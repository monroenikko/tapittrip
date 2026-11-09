import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/trips/data/trip_repository.dart';
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';
import 'package:tapittrip/features/trips/presentation/pages/trip_create_page.dart';
import 'package:tapittrip/features/trips/presentation/providers/trip_list_provider.dart';
import 'package:tapittrip/features/trips/presentation/widgets/trip_card.dart';

class FakeAiApiClient extends ApiClient {
  FakeAiApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic postResponse;
  final List<String> postedPaths = [];
  final List<dynamic> postedPayloads = [];

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    postedPaths.add(path);
    postedPayloads.add(data);
    if (path.contains('/ai-plan/generate')) {
      return {
        'data': {
          'destination': 'Tokyo, Japan',
          'summary': 'Curated 3-day itinerary',
          'travel_party': 'leisure',
          'pace': 'balanced',
          'total_estimated_budget': {'currency': 'JPY', 'amount': 15000},
          'days': [
            {
              'day_number': 1,
              'title': 'Day 1: Historic Asakusa',
              'theme': 'Historic Sights',
              'primary_neighborhood': 'Asakusa',
              'budget_estimate': {'currency': 'JPY', 'amount': 5000},
              'activities': [
                {
                  'title': 'Senso-ji Temple',
                  'kind': 'attraction',
                  'neighborhood': 'Asakusa',
                  'place_name': 'Senso-ji',
                  'description': 'Tokyo oldest Buddhist temple',
                }
              ],
            }
          ],
        }
      };
    }
    if (path.contains('/ai-plan/apply')) {
      return {
        'data': [
          {
            'id': 'item-1',
            'trip_id': 'trip-1',
            'title': 'Senso-ji Temple',
            'kind': 'attraction',
            'status': 'planned',
            'sort_order': 1,
            'version': 1,
          }
        ]
      };
    }
    return postResponse ?? {'data': {}};
  }
}

class FakeTripRepository implements TripRepository {
  final List<Trip> trips = [];

  @override
  Future<List<Trip>> getTrips() async => List.unmodifiable(trips);

  @override
  Future<Trip> getTrip(String id) async => trips.firstWhere((t) => t.id == id);

  @override
  Future<Trip> createTrip({
    required String title,
    String? startDate,
    String? endDate,
    String? primaryTimezone,
    String? originCountry,
    String? destinationCountry,
    String? tripType,
    PlanningMode planningMode = PlanningMode.diy,
  }) async {
    final trip = Trip(
      id: 'trip-${trips.length + 1}',
      ownerId: 'user-1',
      title: title,
      startDate: startDate,
      endDate: endDate,
      primaryTimezone: primaryTimezone ?? 'UTC',
      originCountry: originCountry,
      destinationCountry: destinationCountry,
      tripType: tripType ?? 'leisure',
      planningMode: planningMode,
    );
    trips.add(trip);
    return trip;
  }

  @override
  Future<Trip> updateTrip(
    String id, {
    String? title,
    String? startDate,
    String? endDate,
    String? primaryTimezone,
    String? originCountry,
    String? destinationCountry,
    String? tripType,
    PlanningMode? planningMode,
    String? status,
  }) async {
    final index = trips.indexWhere((t) => t.id == id);
    final existing = trips[index];
    final updated = Trip(
      id: existing.id,
      ownerId: existing.ownerId,
      title: title ?? existing.title,
      startDate: startDate ?? existing.startDate,
      endDate: endDate ?? existing.endDate,
      primaryTimezone: primaryTimezone ?? existing.primaryTimezone,
      originCountry: originCountry ?? existing.originCountry,
      destinationCountry: destinationCountry ?? existing.destinationCountry,
      tripType: tripType ?? existing.tripType,
      planningMode: planningMode ?? existing.planningMode,
      status: status ?? existing.status,
    );
    trips[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTrip(String id) async {
    trips.removeWhere((t) => t.id == id);
  }
}

void main() {
  group('TripListNotifier and CRUD operations across all 4 modes', () {
    test('fetches empty list initially', () async {
      final fakeRepo = FakeTripRepository();
      final container = ProviderContainer(
        overrides: [tripRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final state = await container.read(tripListProvider.future);
      expect(state, isEmpty);
    });

    test('creates and lists trips in all 4 planning modes (v1.4)', () async {
      final fakeRepo = FakeTripRepository();
      final container = ProviderContainer(
        overrides: [tripRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripListProvider.notifier);

      // Mode 1: DIY
      final diyTrip = await notifier.createTrip(
        title: 'Backpacking Southeast Asia',
        planningMode: PlanningMode.diy,
      );
      expect(diyTrip, isNotNull);
      expect(diyTrip!.planningMode, PlanningMode.diy);

      // Mode 2: Already-Booked
      final bookedTrip = await notifier.createTrip(
        title: 'Tokyo Hotel & Flight Confirmation',
        planningMode: PlanningMode.existing,
      );
      expect(bookedTrip, isNotNull);
      expect(bookedTrip!.planningMode, PlanningMode.existing);

      // Mode 3: Guided Tour
      final guidedTrip = await notifier.createTrip(
        title: 'Swiss Alps Group Trek',
        planningMode: PlanningMode.guided,
      );
      expect(guidedTrip, isNotNull);
      expect(guidedTrip!.planningMode, PlanningMode.guided);

      // Mode 4: Simple / Essentials
      final simpleTrip = await notifier.createTrip(
        title: 'Weekend Getaway',
        planningMode: PlanningMode.simple,
      );
      expect(simpleTrip, isNotNull);
      expect(simpleTrip!.planningMode, PlanningMode.simple);

      final allTrips = container.read(tripListProvider).value!;
      expect(allTrips.length, 4);

      // Delete one trip
      final deleted = await notifier.deleteTrip(diyTrip.id);
      expect(deleted, isTrue);

      final remainingTrips = container.read(tripListProvider).value!;
      expect(remainingTrips.length, 3);
      expect(remainingTrips.any((t) => t.id == diyTrip.id), isFalse);
    });

    test('updates trip details in-place via updateTrip', () async {
      final fakeRepo = FakeTripRepository();
      final container = ProviderContainer(
        overrides: [tripRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripListProvider.notifier);
      final trip = await notifier.createTrip(
        title: 'Original Title',
        destinationCountry: 'JP',
        planningMode: PlanningMode.diy,
      );
      expect(trip, isNotNull);

      final updated = await notifier.updateTrip(
        trip!.id,
        title: 'Updated Title',
        destinationCountry: 'Tokyo, Japan',
        startDate: '2026-06-01',
        endDate: '2026-06-10',
        planningMode: PlanningMode.existing,
      );

      expect(updated, isNotNull);
      expect(updated!.title, 'Updated Title');
      expect(updated.destinationCountry, 'Tokyo, Japan');
      expect(updated.startDate, '2026-06-01');
      expect(updated.endDate, '2026-06-10');
      expect(updated.planningMode, PlanningMode.existing);

      final tripsInState = container.read(tripListProvider).value!;
      expect(tripsInState.first.title, 'Updated Title');
      expect(tripsInState.first.destinationCountry, 'Tokyo, Japan');
    });

    testWidgets('TripCard renders edit button and triggers onEdit', (
      tester,
    ) async {
      bool editTapped = false;
      const trip = Trip(
        id: 'trip-1',
        ownerId: 'user-1',
        title: 'Osaka & Kyoto',
        destinationCountry: 'Japan',
        planningMode: PlanningMode.diy,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: TripCard(trip: trip, onEdit: () => editTapped = true),
            ),
          ),
        ),
      );

      expect(find.text('Osaka & Kyoto'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      expect(editTapped, isTrue);
    });

    testWidgets(
      'TripCreatePage renders itinerary setup with AI auto-generate toggle and interest chips',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeRepo = FakeTripRepository();
        final fakeApi = FakeAiApiClient();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tripRepositoryProvider.overrideWithValue(fakeRepo),
              apiClientProvider.overrideWithValue(fakeApi),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TripCreatePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('New Trip'), findsOneWidget);
        expect(find.text('Trip title *'), findsOneWidget);
        expect(find.text('Itinerary Setup'), findsOneWidget);
        expect(
          find.text('✨ Auto-generate starter itinerary with AI'),
          findsOneWidget,
        );
        expect(find.text('Interests & Focus:'), findsOneWidget);
        expect(find.textContaining('Sightseeing'), findsOneWidget);
        expect(find.textContaining('Food & Dining'), findsOneWidget);
      },
    );

    testWidgets(
      'TripCreatePage toggling manual stop shows input fields',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeRepo = FakeTripRepository();
        final fakeApi = FakeAiApiClient();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tripRepositoryProvider.overrideWithValue(fakeRepo),
              apiClientProvider.overrideWithValue(fakeApi),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TripCreatePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially manual input fields are not visible
        expect(find.text('First stop title'), findsNothing);

        // Tap checkbox to enable manual stop
        final manualCheckbox = find.text('✍️ Add your first stop manually instead');
        expect(manualCheckbox, findsOneWidget);
        await tester.tap(manualCheckbox);
        await tester.pumpAndSettle();

        // Now first stop fields are revealed
        expect(find.text('First stop title'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);
      },
    );

    testWidgets(
      'TripCreatePage creates trip and navigates',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeRepo = FakeTripRepository();
        final fakeApi = FakeAiApiClient();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tripRepositoryProvider.overrideWithValue(fakeRepo),
              apiClientProvider.overrideWithValue(fakeApi),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TripCreatePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter trip title
        await tester.enterText(find.byType(TextFormField).first, 'Tokyo Trip');
        await tester.pump();

        // Submit form
        await tester.tap(find.text('Create Trip'));
        await tester.pump();

        // Wait for async operations to complete
        await tester.pumpAndSettle();

        // Trip was created in repository
        expect(fakeRepo.trips.length, 1);
        expect(fakeRepo.trips.first.title, 'Tokyo Trip');

        // AI starter itinerary was generated and applied
        expect(
          fakeApi.postedPaths.any((p) => p.contains('/ai-plan/generate')),
          isTrue,
        );
        expect(
          fakeApi.postedPaths.any((p) => p.contains('/ai-plan/apply')),
          isTrue,
        );
        final generateCall = fakeApi.postedPayloads.firstWhere(
          (p) => p is Map && p['destination'] != null,
        ) as Map<String, dynamic>;
        expect(generateCall['travel_party'], 'couple'); // leisure mapped to couple
      },
    );
  });
}
