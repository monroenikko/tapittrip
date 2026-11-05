import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/itinerary/domain/models/itinerary_item.dart';
import 'package:tapittrip/features/itinerary/domain/models/place.dart';
import 'package:tapittrip/features/itinerary/domain/models/trip_day.dart';
import 'package:tapittrip/features/itinerary/presentation/pages/trip_itinerary_page.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/activity_timeline_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/itinerary_filter_tabs.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/route_summary_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/timeline_day_badge.dart';
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';

const samplePlace = Place(
  id: 'place-1',
  name: 'Senso-ji Temple',
  formattedAddress: '2 Chome-3-1 Asakusa, Taito City, Tokyo',
  countryCode: 'JP',
  latitude: 35.7147,
  longitude: 139.7967,
  googleMapsUrl:
      'https://www.google.com/maps/search/?api=1&query=35.7147,139.7967',
);

const sampleItem = ItineraryItem(
  id: 'item-1',
  tripId: 'trip-1',
  title: 'Senso-ji Temple Morning Visit',
  kind: 'attraction',
  notes: 'Visit early for peaceful photos and omikuji.',
  sortOrder: 0,
  status: 'planned',
  place: samplePlace,
);

const sampleTrip = Trip(
  id: 'trip-1',
  ownerId: 'user-1',
  title: 'Tokyo Cultural Exploration',
  startDate: '2026-05-10',
  endDate: '2026-05-18',
  destinationCountry: 'JP',
  tripType: 'leisure',
  planningMode: PlanningMode.diy,
);

void main() {
  group('Itinerary Models', () {
    test('Place serializes and deserializes properly', () {
      final json = samplePlace.toJson();
      final fromJson = Place.fromJson(json);

      expect(fromJson.id, 'place-1');
      expect(fromJson.name, 'Senso-ji Temple');
      expect(fromJson.latitude, 35.7147);
      expect(fromJson.googleMapsUrl, contains('35.7147,139.7967'));
    });

    test('TripDay serializes and deserializes properly', () {
      const day = TripDay(
        id: 'day-1',
        tripId: 'trip-1',
        localDate: '2026-05-10',
        notes: 'Kyoto Arrival',
      );

      final json = day.toJson();
      final fromJson = TripDay.fromJson(json);

      expect(fromJson.id, 'day-1');
      expect(fromJson.localDate, '2026-05-10');
      expect(fromJson.notes, 'Kyoto Arrival');
    });

    test('ItineraryItem serializes and deserializes properly with place', () {
      final json = sampleItem.toJson();
      final fromJson = ItineraryItem.fromJson(json);

      expect(fromJson.id, 'item-1');
      expect(fromJson.title, 'Senso-ji Temple Morning Visit');
      expect(fromJson.place?.name, 'Senso-ji Temple');
      expect(fromJson.status, 'planned');
    });
  });

  group('Timeline Widgets', () {
    testWidgets('TimelineDayBadge renders numbered day circle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SizedBox(
              height: 100,
              child: TimelineDayBadge(dayNumber: 1, isFirst: true),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets(
      'ActivityTimelineCard renders activity information and directions button',
      (tester) async {
        bool toggleCalled = false;
        bool deleteCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: ActivityTimelineCard(
                item: sampleItem,
                onToggleVisited: () => toggleCalled = true,
                onDelete: () => deleteCalled = true,
              ),
            ),
          ),
        );

        expect(find.text('Senso-ji Temple Morning Visit'), findsOneWidget);
        expect(find.text('Senso-ji Temple'), findsOneWidget);
        expect(find.text('Directions'), findsOneWidget);
        expect(find.byIcon(Icons.navigation_rounded), findsOneWidget);

        await tester.tap(find.byTooltip('Mark as visited'));
        expect(toggleCalled, isTrue);

        await tester.tap(find.byTooltip('Delete stop'));
        expect(deleteCalled, isTrue);
      },
    );

    testWidgets('RouteSummaryCard renders distance, cost, and CO2 metrics', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: RouteSummaryCard(
              distance: '180 km',
              estimatedCost: '\$850',
              co2Saved: '22 kg',
            ),
          ),
        ),
      );

      expect(find.text('AI Route Optimized'), findsOneWidget);
      expect(find.text('180 km'), findsOneWidget);
      expect(find.text('\$850'), findsOneWidget);
      expect(find.text('22 kg'), findsOneWidget);
    });

    testWidgets('ItineraryFilterTabs renders selectable tabs', (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ItineraryFilterTabs(
                  selectedIndex: selected,
                  onTabSelected: (idx) => setState(() => selected = idx),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Itinerary'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Stay'), findsOneWidget);
      expect(find.text('Recommendations'), findsOneWidget);

      await tester.tap(find.text('Transport'));
      await tester.pumpAndSettle();

      expect(selected, 1);
    });
  });

  group('TripItineraryPage', () {
    testWidgets('renders timeline activity items and trip header', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTripIdProvider.overrideWithValue('trip-1'),
            itineraryListProvider.overrideWith(_FakeItineraryListNotifier.new),
            tripDaysProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TripItineraryPage(
              tripId: 'trip-1',
              initialTrip: sampleTrip,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your Itinerary'), findsOneWidget);
      expect(find.text('Tokyo Cultural Exploration'), findsOneWidget);
      expect(find.text('Senso-ji Temple Morning Visit'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
      expect(find.text('Add Activity'), findsWidgets);
    });

    testWidgets('keeps a large error responsive without exposing it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itineraryListProvider.overrideWith(
              _FailingItineraryListNotifier.new,
            ),
            tripDaysProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const TripItineraryPage(
              tripId: 'trip-1',
              initialTrip: sampleTrip,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Error loading itinerary'), findsOneWidget);
      expect(find.text('Check your connection and try again.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('private provider payload'), findsNothing);
    });
  });
}

class _FakeItineraryListNotifier extends ItineraryListNotifier {
  @override
  Future<List<ItineraryItem>> build() async {
    return [sampleItem];
  }
}

class _FailingItineraryListNotifier extends ItineraryListNotifier {
  @override
  Future<List<ItineraryItem>> build() async {
    throw Exception(List.filled(1000, 'private provider payload').join('\n'));
  }
}
