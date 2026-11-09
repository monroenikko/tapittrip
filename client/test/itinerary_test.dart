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
import 'package:tapittrip/features/itinerary/presentation/widgets/place_autocomplete_field.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/route_summary_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/timeline_day_badge.dart';
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';
import 'package:tapittrip/features/weather/domain/models/daily_forecast.dart';
import 'package:tapittrip/features/weather/domain/models/trip_weather.dart';
import 'package:tapittrip/features/weather/domain/models/weather_condition.dart';
import 'package:tapittrip/features/weather/presentation/providers/weather_provider.dart';
import 'package:tapittrip/features/weather/presentation/widgets/trip_weather_view.dart';

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
      'ActivityTimelineCard renders activity information and edit / directions buttons',
      (tester) async {
        bool toggleCalled = false;
        bool deleteCalled = false;
        bool editCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: ActivityTimelineCard(
                item: sampleItem,
                onToggleVisited: () => toggleCalled = true,
                onEdit: () => editCalled = true,
                onDelete: () => deleteCalled = true,
              ),
            ),
          ),
        );

        expect(find.text('Senso-ji Temple Morning Visit'), findsOneWidget);
        expect(find.text('Senso-ji Temple'), findsOneWidget);
        expect(find.text('Directions'), findsOneWidget);
        expect(find.byIcon(Icons.navigation_rounded), findsOneWidget);
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

        await tester.tap(find.byTooltip('Mark as visited'));
        expect(toggleCalled, isTrue);

        await tester.tap(find.byTooltip('Edit activity'));
        expect(editCalled, isTrue);

        await tester.tap(find.byTooltip('Delete stop'));
        expect(deleteCalled, isTrue);
      },
    );

    testWidgets(
      'ActivityTimelineCard renders weather badge with forecast and triggers onWeatherTap',
      (tester) async {
        bool weatherTapped = false;
        const testWeather = TripWeather(
          destination: 'Tokyo',
          latitude: 35.7147,
          longitude: 139.7967,
          timezone: 'Asia/Tokyo',
          current: WeatherCondition(
            temperatureC: 22.0,
            temperatureF: 71.6,
            condition: 'Sunny',
            icon: 'sunny',
            humidity: 50,
            windKph: 10,
            precipitationProbability: 5,
            advisory: 'Clear skies',
          ),
          forecast: [
            DailyForecast(
              date: '2026-11-10',
              dayName: 'Tue',
              tempMaxC: 24.0,
              tempMinC: 16.0,
              tempMaxF: 75.2,
              tempMinF: 60.8,
              condition: 'Partly Cloudy',
              icon: 'partly_cloudy',
              precipitationProbability: 25,
            ),
          ],
        );

        final itemWithDate = sampleItem.copyWith(
          startsAtUtc: '2026-11-10T09:00:00Z',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: ActivityTimelineCard(
                item: itemWithDate,
                weather: testWeather,
                onWeatherTap: () => weatherTapped = true,
              ),
            ),
          ),
        );

        expect(
          find.textContaining('Tue: 24°C • Partly Cloudy'),
          findsOneWidget,
        );
        expect(find.textContaining('25%'), findsOneWidget);

        await tester.tap(find.textContaining('Tue: 24°C • Partly Cloudy'));
        expect(weatherTapped, isTrue);
      },
    );

    testWidgets('PlaceAutocompleteField renders label and text input', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: PlaceAutocompleteField(
                controller: controller,
                labelText: 'Stay or Hotel Name',
                prefixIcon: Icons.hotel_rounded,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Stay or Hotel Name'), findsOneWidget);
      expect(find.byIcon(Icons.hotel_rounded), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Hilton');
      expect(controller.text, 'Hilton');
    });

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

    testWidgets('RouteSummaryCard renders weather metric when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: RouteSummaryCard(
              distance: '210 km',
              estimatedCost: '₱6800.00',
              co2Saved: '18 kg',
              weatherText: '28°C',
              weatherIcon: Icons.wb_sunny_rounded,
            ),
          ),
        ),
      );

      expect(find.text('210 km'), findsOneWidget);
      expect(find.text('₱6800.00'), findsOneWidget);
      expect(find.text('18 kg'), findsOneWidget);
      expect(find.text('Weather'), findsOneWidget);
      expect(find.text('28°C'), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
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
            itineraryListProvider('trip-1')
                .overrideWith(() => _FakeItineraryListNotifier('trip-1')),
            tripDaysProvider('trip-1').overrideWith((ref) => Future.value([])),
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

    testWidgets('TripItineraryPage renders weather chip when provider emits', (
      tester,
    ) async {
      const mockWeather = TripWeather(
        destination: 'Tokyo, Japan',
        latitude: 35.6762,
        longitude: 139.6503,
        timezone: 'Asia/Tokyo',
        current: WeatherCondition(
          temperatureC: 18.0,
          temperatureF: 64.4,
          condition: 'Clear Sky',
          icon: 'sunny',
          humidity: 45,
          windKph: 8.5,
          precipitationProbability: 0,
          advisory: 'Sunny skies',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itineraryListProvider('trip-1')
                .overrideWith(() => _FakeItineraryListNotifier('trip-1')),
            tripDaysProvider('trip-1').overrideWith((ref) => Future.value([])),
            tripWeatherProvider('trip-1')
                .overrideWith((ref) => Future.value(mockWeather)),
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

      expect(find.textContaining('18°C • Clear Sky'), findsWidgets);
      expect(find.text('18°C'), findsWidgets);

      // Tapping the weather pill on an activity card switches to the Weather tab
      final itemWeatherFinder = find.descendant(
        of: find.byType(ActivityTimelineCard),
        matching: find.textContaining('18°C • Clear Sky'),
      );
      expect(itemWeatherFinder, findsOneWidget);
      await tester.tap(itemWeatherFinder);
      await tester.pumpAndSettle();
      expect(find.byType(TripWeatherView), findsOneWidget);
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
            itineraryListProvider('trip-1')
                .overrideWith(() => _FailingItineraryListNotifier('trip-1')),
            tripDaysProvider('trip-1').overrideWith((ref) => Future.value([])),
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

    testWidgets(
      'TripItineraryPage switching to Weather tab renders TripWeatherView with whole week forecast without layout errors',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const mockWeather = TripWeather(
          destination: 'BGC Taguig',
          latitude: 14.55,
          longitude: 121.05,
          timezone: 'Asia/Manila',
          current: WeatherCondition(
            temperatureC: 29.0,
            temperatureF: 84.2,
            condition: 'Partly Cloudy',
            icon: 'partly_cloudy',
            humidity: 68,
            windKph: 12.0,
            precipitationProbability: 15,
            advisory: 'Warm and pleasant in Taguig.',
          ),
          forecast: [
            DailyForecast(
              date: '2026-11-09',
              dayName: 'Today',
              tempMaxC: 30.0,
              tempMinC: 24.0,
              tempMaxF: 86.0,
              tempMinF: 75.2,
              condition: 'Partly Cloudy',
              icon: 'partly_cloudy',
              precipitationProbability: 20,
            ),
            DailyForecast(
              date: '2026-11-10',
              dayName: 'Tomorrow',
              tempMaxC: 31.0,
              tempMinC: 25.0,
              tempMaxF: 87.8,
              tempMinF: 77.0,
              condition: 'Clear Sky',
              icon: 'sunny',
              precipitationProbability: 10,
            ),
          ],
          providerAttribution: 'Live Weather via Open-Meteo',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              itineraryListProvider('trip-1')
                  .overrideWith(() => _FakeItineraryListNotifier('trip-1')),
              tripDaysProvider('trip-1')
                  .overrideWith((ref) => Future.value([])),
              tripWeatherProvider('trip-1')
                  .overrideWith((ref) => Future.value(mockWeather)),
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

        // Tap the Weather filter tab in ItineraryFilterTabs
        final weatherTab = find.descendant(
          of: find.byType(ItineraryFilterTabs),
          matching: find.text('Weather'),
        );
        await tester.tap(weatherTab);
        await tester.pumpAndSettle();

        // Verify the full weather view is rendered seamlessly
        expect(find.text('BGC Taguig'), findsWidgets);
        expect(
          find.text('Live Weather & Climate (Asia/Manila)'),
          findsOneWidget,
        );
        expect(find.text('29°C'), findsWidgets);
        expect(find.text('Destination Weather Advisory'), findsOneWidget);
        expect(find.text('Warm and pleasant in Taguig.'), findsOneWidget);
        expect(find.text('Forecast for Trip Days'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Tomorrow'), findsOneWidget);
        expect(
          find.text('Ask TapItTrip for Weather Backup Ideas'),
          findsOneWidget,
        );
      },
    );
  });
}

class _FakeItineraryListNotifier extends ItineraryListNotifier {
  _FakeItineraryListNotifier(super.tripId);

  @override
  Future<List<ItineraryItem>> build() async {
    return [sampleItem];
  }
}

class _FailingItineraryListNotifier extends ItineraryListNotifier {
  _FailingItineraryListNotifier(super.tripId);

  @override
  Future<List<ItineraryItem>> build() async {
    throw Exception(List.filled(1000, 'private provider payload').join('\n'));
  }
}
