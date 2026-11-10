import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/itinerary/data/itinerary_repository.dart';
import 'package:tapittrip/features/itinerary/domain/models/itinerary_item.dart';
import 'package:tapittrip/features/itinerary/domain/models/place.dart';
import 'package:tapittrip/features/itinerary/domain/models/trip_day.dart';
import 'package:tapittrip/features/itinerary/presentation/pages/trip_itinerary_page.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/activity_timeline_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/add_activity_bottom_sheet.dart';
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
        dayNumber: 1,
        title: 'Day 1',
        notes: 'Kyoto Arrival',
      );

      final json = day.toJson();
      final fromJson = TripDay.fromJson(json);

      expect(fromJson.id, 'day-1');
      expect(fromJson.localDate, '2026-05-10');
      expect(fromJson.dayNumber, 1);
      expect(fromJson.displayTitle, 'Day 1');
      expect(fromJson.displayHeader, contains('Day 1'));
      expect(fromJson.notes, 'Kyoto Arrival');
    });

    testWidgets('AddActivityBottomSheet renders Day dropdown selector', (
      tester,
    ) async {
      const days = [
        TripDay(
          id: 'day-1',
          tripId: 'trip-1',
          localDate: '2026-05-10',
          dayNumber: 1,
          title: 'Day 1',
        ),
        TripDay(
          id: 'day-2',
          tripId: 'trip-1',
          localDate: '2026-05-11',
          dayNumber: 2,
          title: 'Day 2',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AddActivityBottomSheet(
              tripId: 'trip-1',
              days: days,
              onSubmit: ({
                required title,
                required kind,
                tripDayId,
                inlinePlace,
                notes,
              }) async {},
            ),
          ),
        ),
      );

      expect(
        find.widgetWithText(DropdownButtonFormField<String>, 'Itinerary Day'),
        findsOneWidget,
      );
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
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

  mainReorderTests();
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

class _FakeReorderApiClient extends ApiClient {
  _FakeReorderApiClient(this.initialItems, this.days)
    : super(tokenStorage: InMemoryTokenStorage());

  List<Map<String, dynamic>> initialItems;
  final List<TripDay> days;
  String? lastPostPath;
  Map<String, dynamic>? lastPostData;
  bool failReorder = false;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (path.endsWith('/days')) {
      return days
          .map(
            (d) => {
              'id': d.id,
              'trip_id': d.tripId,
              'day_number': d.dayNumber,
              'title': d.title,
              'local_date': d.localDate,
              'notes': d.notes,
            },
          )
          .toList();
    }
    return initialItems;
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPostPath = path;
    lastPostData = data is Map ? Map<String, dynamic>.from(data) : null;

    if (path.endsWith('/reorder')) {
      if (failReorder) {
        throw Exception('Network timeout');
      }
      final itemIds = List<String>.from(lastPostData?['item_ids'] as List);
      final dayAssignments = lastPostData?['day_assignments'] is Map
          ? Map<String, dynamic>.from(lastPostData!['day_assignments'] as Map)
          : <String, dynamic>{};

      final byId = {for (final m in initialItems) m['id'] as String: m};
      final reordered = <Map<String, dynamic>>[];
      for (var i = 0; i < itemIds.length; i++) {
        final id = itemIds[i];
        final copy = Map<String, dynamic>.from(byId[id]!);
        copy['sort_order'] = i;
        copy['version'] = ((copy['version'] as int?) ?? 1) + 1;
        if (dayAssignments.containsKey(id)) {
          copy['trip_day_id'] = dayAssignments[id];
        }
        reordered.add(copy);
      }
      initialItems = reordered;
      return reordered;
    }

    return const {};
  }
}

void mainReorderTests() {
  group('Drag & Drop Ordinal Reordering', () {
    const day1 = TripDay(
      id: 'day-1',
      tripId: 'trip-1',
      dayNumber: 1,
      title: 'Day 1',
      localDate: '2026-06-01',
      notes: 'Day 1',
    );
    const day2 = TripDay(
      id: 'day-2',
      tripId: 'trip-1',
      dayNumber: 2,
      title: 'Day 2',
      localDate: '2026-06-02',
      notes: 'Day 2',
    );

    List<Map<String, dynamic>> buildInitialRawItems() => [
      {
        'id': 'item-a',
        'trip_id': 'trip-1',
        'trip_day_id': 'day-1',
        'title': 'Stop A (Senso-ji)',
        'kind': 'attraction',
        'sort_order': 0,
        'status': 'planned',
        'version': 1,
      },
      {
        'id': 'item-b',
        'trip_id': 'trip-1',
        'trip_day_id': 'day-1',
        'title': 'Stop B (Sushi Lunch)',
        'kind': 'meal',
        'sort_order': 1,
        'status': 'planned',
        'version': 1,
      },
      {
        'id': 'item-c',
        'trip_id': 'trip-1',
        'trip_day_id': 'day-2',
        'title': 'Stop C (Tokyo Tower)',
        'kind': 'attraction',
        'sort_order': 2,
        'status': 'planned',
        'version': 1,
      },
    ];

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test(
      'ItineraryRepository.reorderItems sends item_ids and day_assignments',
      () async {
        final api = _FakeReorderApiClient(buildInitialRawItems(), [day1, day2]);
        final repo = ItineraryRepository(
          apiClient: api,
          storage: const FlutterSecureStorage(),
        );

        final result = await repo.reorderItems(
          'trip-1',
          ['item-b', 'item-c', 'item-a'],
          dayAssignments: {'item-c': 'day-1'},
        );

        expect(api.lastPostPath, '/trips/trip-1/itinerary-items/reorder');
        expect(api.lastPostData?['item_ids'], ['item-b', 'item-c', 'item-a']);
        expect(api.lastPostData?['day_assignments'], {'item-c': 'day-1'});
        expect(result.length, 3);
        expect(result[0].id, 'item-b');
        expect(result[1].id, 'item-c');
        expect(result[1].tripDayId, 'day-1');
      },
    );

    testWidgets(
      'dragging a card by its drag handle reorders stops within Day 1 and updates ordinals',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final api = _FakeReorderApiClient(buildInitialRawItems(), [day1, day2]);
        final repo = ItineraryRepository(
          apiClient: api,
          storage: const FlutterSecureStorage(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [itineraryRepositoryProvider.overrideWithValue(repo)],
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

        final stopAYBefore = tester
            .getTopLeft(find.text('Stop A (Senso-ji)'))
            .dy;
        final stopBYBefore = tester
            .getTopLeft(find.text('Stop B (Sushi Lunch)'))
            .dy;
        expect(stopAYBefore, lessThan(stopBYBefore));

        // Find drag handle on Stop B (second drag handle in Day 1)
        final handles = find.byIcon(Icons.drag_indicator_rounded);
        expect(handles, findsNWidgets(3));

        final handleBPos = tester.getCenter(handles.at(1));
        final dragDeltaY = stopAYBefore - stopBYBefore - 40;

        await tester.dragFrom(handleBPos, Offset(0, dragDeltaY));
        await tester.pumpAndSettle();

        final stopAYAfter = tester
            .getTopLeft(find.text('Stop A (Senso-ji)'))
            .dy;
        final stopBYAfter = tester
            .getTopLeft(find.text('Stop B (Sushi Lunch)'))
            .dy;

        // Stop B is now visually above Stop A!
        expect(stopBYAfter, lessThan(stopAYAfter));
        // Backend received reordered item IDs
        expect(api.lastPostData?['item_ids'], ['item-b', 'item-a', 'item-c']);
      },
    );

    testWidgets(
      'dragging a card from Day 2 into Day 1 updates both ordinal order and day assignment',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final api = _FakeReorderApiClient(buildInitialRawItems(), [day1, day2]);
        final repo = ItineraryRepository(
          apiClient: api,
          storage: const FlutterSecureStorage(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [itineraryRepositoryProvider.overrideWithValue(repo)],
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

        final stopAY = tester.getTopLeft(find.text('Stop A (Senso-ji)')).dy;
        final stopCY = tester.getTopLeft(find.text('Stop C (Tokyo Tower)')).dy;

        // Drag Stop C (3rd handle) all the way above Stop A (into Day 1 slot 1)
        final handleC = find.byIcon(Icons.drag_indicator_rounded).at(2);
        final dragDeltaY = stopAY - stopCY - 50;

        await tester.dragFrom(tester.getCenter(handleC), Offset(0, dragDeltaY));
        await tester.pumpAndSettle();

        // Day 1 chip should now show count 3, Day 2 count 0
        expect(find.text('Day 1 (3)'), findsOneWidget);
        expect(find.text('Day 2 (0)'), findsOneWidget);
        expect(api.lastPostData?['day_assignments'], {'item-c': 'day-1'});
        expect(api.lastPostData?['item_ids'], ['item-c', 'item-a', 'item-b']);
      },
    );

    testWidgets(
      'tapping ordinal badge opens Change Stop Order sheet and moves stop to selected ordinal',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final api = _FakeReorderApiClient(buildInitialRawItems(), [day1, day2]);
        final repo = ItineraryRepository(
          apiClient: api,
          storage: const FlutterSecureStorage(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [itineraryRepositoryProvider.overrideWithValue(repo)],
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

        // Tap Stop B's ordinal badge ('2')
        final badges = find.byType(TimelineDayBadge);
        expect(badges, findsNWidgets(3));

        final badge2Text = find.descendant(
          of: badges.at(1),
          matching: find.text('2'),
        );
        await tester.tap(badge2Text);
        await tester.pumpAndSettle();

        expect(find.text('Change Stop Order'), findsOneWidget);
        expect(find.text('Stop Position (Ordinal)'), findsOneWidget);

        // Select #1 chip
        await tester.tap(find.text('#1'));
        await tester.pumpAndSettle();

        // Confirm
        await tester.tap(find.text('Move to Stop #1'));
        await tester.pumpAndSettle();

        // Stop B is now ordered before Stop A
        expect(api.lastPostData?['item_ids'], ['item-b', 'item-a', 'item-c']);
        final stopAY = tester.getTopLeft(find.text('Stop A (Senso-ji)')).dy;
        final stopBY = tester.getTopLeft(find.text('Stop B (Sushi Lunch)')).dy;
        expect(stopBY, lessThan(stopAY));
      },
    );

    testWidgets(
      'reverts order and shows snackbar if reorder request fails offline',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final api = _FakeReorderApiClient(buildInitialRawItems(), [day1, day2])
          ..failReorder = true;
        final repo = ItineraryRepository(
          apiClient: api,
          storage: const FlutterSecureStorage(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [itineraryRepositoryProvider.overrideWithValue(repo)],
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

        final stopAYBefore = tester
            .getTopLeft(find.text('Stop A (Senso-ji)'))
            .dy;
        final stopBYBefore = tester
            .getTopLeft(find.text('Stop B (Sushi Lunch)'))
            .dy;

        final handleBPos = tester.getCenter(
          find.byIcon(Icons.drag_indicator_rounded).at(1),
        );
        await tester.dragFrom(
          handleBPos,
          Offset(0, stopAYBefore - stopBYBefore - 40),
        );
        await tester.pumpAndSettle();

        // Reverted back to original order
        final stopAYAfter = tester
            .getTopLeft(find.text('Stop A (Senso-ji)'))
            .dy;
        final stopBYAfter = tester
            .getTopLeft(find.text('Stop B (Sushi Lunch)'))
            .dy;
        expect(stopAYAfter, lessThan(stopBYAfter));
        expect(
          find.text('Unable to save new stop order. Reverted changes.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'reordering while filtered to a single day preserves items in other days',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final api = _FakeReorderApiClient(buildInitialRawItems(), [day1, day2]);
        final repo = ItineraryRepository(
          apiClient: api,
          storage: const FlutterSecureStorage(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [itineraryRepositoryProvider.overrideWithValue(repo)],
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

        // Filter to Day 1 only
        await tester.tap(find.text('Day 1 (2)'));
        await tester.pumpAndSettle();

        expect(find.text('Stop C (Tokyo Tower)'), findsNothing);

        final stopAY = tester.getTopLeft(find.text('Stop A (Senso-ji)')).dy;
        final stopBY = tester.getTopLeft(find.text('Stop B (Sushi Lunch)')).dy;

        final handleBPos = tester.getCenter(
          find.byIcon(Icons.drag_indicator_rounded).at(1),
        );
        await tester.dragFrom(handleBPos, Offset(0, stopAY - stopBY - 40));
        await tester.pumpAndSettle();

        // Day 2 item C must remain preserved in complete ordered payload
        expect(api.lastPostData?['item_ids'], ['item-b', 'item-a', 'item-c']);

        // Switch back to All Days and confirm Stop C is still present
        await tester.tap(find.text('All Days (3)'));
        await tester.pumpAndSettle();
        expect(find.text('Stop C (Tokyo Tower)'), findsOneWidget);
      },
    );

    testWidgets(
      'dragging a card in a dateless itinerary (days empty) updates ordinal order',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final rawNoDays = [
          {
            'id': 'item-1',
            'trip_id': 'trip-1',
            'title': 'First Dateless Stop',
            'kind': 'attraction',
            'sort_order': 0,
            'status': 'planned',
            'version': 1,
          },
          {
            'id': 'item-2',
            'trip_id': 'trip-1',
            'title': 'Second Dateless Stop',
            'kind': 'meal',
            'sort_order': 1,
            'status': 'planned',
            'version': 1,
          },
        ];

        final api = _FakeReorderApiClient(rawNoDays, const []);
        final repo = ItineraryRepository(
          apiClient: api,
          storage: const FlutterSecureStorage(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [itineraryRepositoryProvider.overrideWithValue(repo)],
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

        final y1 = tester.getTopLeft(find.text('First Dateless Stop')).dy;
        final y2 = tester.getTopLeft(find.text('Second Dateless Stop')).dy;
        expect(y1, lessThan(y2));

        final handle2 = find.byIcon(Icons.drag_indicator_rounded).at(1);
        await tester.timedDragFrom(
          tester.getCenter(handle2),
          Offset(0, y1 - y2 - 20),
          const Duration(milliseconds: 300),
        );
        await tester.pumpAndSettle();

        final y1After = tester.getTopLeft(find.text('First Dateless Stop')).dy;
        final y2After = tester.getTopLeft(find.text('Second Dateless Stop')).dy;
        expect(y2After, lessThan(y1After));
        expect(api.lastPostData?['item_ids'], ['item-2', 'item-1']);
      },
    );
  });
}
