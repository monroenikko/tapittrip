import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/core/router/app_router.dart';
import 'package:tapittrip/features/itinerary/domain/models/itinerary_item.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/recommendations_provider.dart';
import 'package:tapittrip/features/lounges/data/lounge_repository.dart';
import 'package:tapittrip/features/lounges/presentation/providers/lounge_provider.dart';

import 'trip_assistant_test.dart' show FakeAssistantApiClient;

import 'package:tapittrip/features/auth/domain/models/auth_state.dart';
import 'package:tapittrip/features/auth/domain/models/auth_user.dart';
import 'package:tapittrip/features/auth/presentation/pages/profile_page.dart';
import 'package:tapittrip/features/auth/presentation/providers/auth_provider.dart';
import 'package:tapittrip/features/circles/presentation/providers/trip_circle_provider.dart';
import 'package:tapittrip/features/flights/domain/models/flight.dart';
import 'package:tapittrip/features/flights/presentation/providers/flight_provider.dart';
import 'package:tapittrip/features/stays/domain/models/stay.dart';
import 'package:tapittrip/features/stays/presentation/providers/stay_provider.dart';
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';
import 'package:tapittrip/features/trips/presentation/pages/trip_list_page.dart';
import 'package:tapittrip/features/trips/presentation/providers/trip_list_provider.dart';
import 'package:tapittrip/features/trips/presentation/widgets/trip_navigation_view.dart';
import 'package:tapittrip/features/weather/domain/models/trip_weather.dart';
import 'package:tapittrip/features/weather/presentation/providers/weather_provider.dart';

class _EmptyItinerary extends ItineraryListNotifier {
  _EmptyItinerary(super.tripId);
  @override
  Future<List<ItineraryItem>> build() async => [];
}

class _Lounges extends LoungeRepository {
  _Lounges() : super(apiClient: FakeAssistantApiClient());
  @override
  Future<void> prefetchAirports(List<String> iataCodes) async {}
}

class _Trips extends TripListNotifier {
  _Trips(this.items);
  final List<Trip> items;
  @override
  Future<List<Trip>> build() async => items;
  void loading() => state = const AsyncLoading();
  void error() =>
      state = AsyncError(Exception('private data'), StackTrace.current);
  @override
  Future<void> refresh() async => state = AsyncData(items);
}

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    user: AuthUser(
      id: 'user',
      name: 'Traveler',
      displayName: 'Traveler',
      email: 'traveler@example.test',
      friendCode: 'TRP-ABC123',
    ),
    token: 'test-token',
  );
}

class _Stays extends StayListNotifier {
  _Stays(super.tripId, this.items);
  final List<Stay> items;
  bool fail = false;
  @override
  Future<List<Stay>> build() async {
    if (fail) throw Exception('private data');
    return items;
  }

  @override
  Future<void> refresh() async => state = AsyncData(items);
}

class _Flights extends FlightListNotifier {
  _Flights(super.tripId);
  @override
  Future<List<Flight>> build() async => const [];
}

void main() {
  const trip = Trip(id: 'one', ownerId: 'user', title: 'Kyoto');
  const other = Trip(id: 'two', ownerId: 'user', title: 'Manila');
  const stay = Stay(id: 'stay', tripId: 'one', name: 'Saved Hotel');

  Future<GoRouter> mount(
    WidgetTester tester, {
    List<Trip> trips = const [],
    _Stays? stays,
    _Trips? tripNotifier,
    bool? componentBookings,
    bool large = false,
    bool dark = false,
  }) async {
    final router = GoRouter(
      initialLocation: '/trips',
      routes: [
        GoRoute(
          path: '/trips',
          builder: (_, _) => componentBookings == null
              ? const TripListPage()
              : Scaffold(body: TripNavigationView(bookings: componentBookings)),
        ),
        GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
        GoRoute(
          path: '/trips/new',
          builder: (_, _) => const Scaffold(body: Text('Create trip screen')),
        ),
        GoRoute(
          path: '/trips/:tripId/itinerary',
          builder: (_, state) => Scaffold(
            appBar: AppBar(
              title: Text('Trip ${state.pathParameters['tripId']}'),
            ),
            body: Text(
              'Section ${state.uri.queryParameters['tab'] ?? 'itinerary'}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    if (large) {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authProvider.overrideWith(_Auth.new),
          tripListProvider.overrideWith(() => tripNotifier ?? _Trips(trips)),
          pendingInboxCountProvider.overrideWithValue(0),
          for (final trip in trips) ...[
            tripWeatherProvider(trip.id)
                .overrideWith((_) => Completer<TripWeather>().future),
            stayListProvider(trip.id).overrideWith(
              () => stays != null && stays.tripId == trip.id
                  ? stays
                  : _Stays(trip.id, []),
            ),
            flightListProvider(trip.id).overrideWith(() => _Flights(trip.id)),
          ],
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(large ? 2 : 1)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('real router opens Stays directly without itinerary activities', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_Auth.new),
        tripListProvider.overrideWith(() => _Trips([trip])),
        pendingInboxCountProvider.overrideWithValue(0),
        itineraryListProvider('one').overrideWith(() => _EmptyItinerary('one')),
        tripDaysProvider('one').overrideWith((_) async => []),
        tripRecommendationsProvider('one').overrideWith((_) async => null),
        tripWeatherProvider('one')
            .overrideWith((_) => Completer<TripWeather>().future),
        stayListProvider('one').overrideWith(() => _Stays('one', [stay])),
        flightListProvider('one').overrideWith(() => _Flights('one')),
        loungeRepositoryProvider.overrideWithValue(_Lounges()),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    router.go('/trips/one/itinerary?tab=stays', extra: trip);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved Hotel'), findsOneWidget);
    expect(find.text('No activities planned yet'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bottom tabs show different content and profile returns to previous tab',
    (tester) async {
      final router = await mount(tester);
      await tester.tap(find.text('Itinerary').last);
      await tester.pumpAndSettle();
      expect(find.text('Choose a trip'), findsOneWidget);
      await tester.tap(find.text('Bookings').last);
      await tester.pumpAndSettle();
      expect(find.text('Saved accommodation'), findsOneWidget);
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(find.text('Profile & Settings'), findsOneWidget);
      await tester.ensureVisible(find.text('Allow direct Friend Code invites'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Saved accommodation'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(find.text('Your Trips'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in PlanningMode.values) {
    testWidgets(
      'itinerary picker opens correct trip without activities, ${mode.name}',
      (tester) async {
        await mount(
          tester,
          trips: [
            Trip(
              id: 'one',
              ownerId: 'user',
              title: 'Kyoto',
              planningMode: mode,
            ),
            other,
          ],
          componentBookings: false,
        );
        await tester.tap(find.text('Manila'));
        await tester.pumpAndSettle();
        expect(find.text('Trip two'), findsOneWidget);
        expect(find.text('Section itinerary'), findsOneWidget);
      },
    );
  }

  testWidgets('bookings groups stays by trip and opens accommodation section', (
    tester,
  ) async {
    final router = await mount(
      tester,
      trips: [trip, other],
      stays: _Stays('one', [stay]),
      componentBookings: true,
    );
    expect(find.text('Saved Hotel'), findsOneWidget);
    expect(find.text('No accommodation saved yet.'), findsOneWidget);
    await tester.tap(find.text('Saved Hotel'));
    await tester.pumpAndSettle();
    expect(find.text('Trip one'), findsOneWidget);
    expect(find.text('Section stays'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Manage accommodation').last);
    await tester.tap(find.text('Manage accommodation').last);
    await tester.pumpAndSettle();
    expect(find.text('Trip two'), findsOneWidget);
    expect(find.text('Section stays'), findsOneWidget);
  });

  testWidgets('failed stay section is isolated and retries safely', (
    tester,
  ) async {
    await mount(
      tester,
      trips: [trip, other],
      stays: _Stays('one', [stay])..fail = true,
      componentBookings: true,
    );
    expect(
      find.text('Unable to load accommodation for this trip.'),
      findsOneWidget,
    );
    expect(find.text('private data'), findsNothing);
    expect(find.text('Manila'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Saved Hotel'), findsOneWidget);
  });

  testWidgets('trip loading and error states recover with retry', (
    tester,
  ) async {
    final notifier = _Trips([trip]);
    await mount(tester, tripNotifier: notifier, componentBookings: false);
    notifier.loading();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    notifier.error();
    await tester.pumpAndSettle();
    expect(find.text('Unable to load trips.'), findsOneWidget);
    expect(find.text('private data'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Kyoto'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets('bookings fits narrow screens with large text, dark=$dark', (
      tester,
    ) async {
      await mount(
        tester,
        trips: [trip],
        stays: _Stays('one', [stay]),
        componentBookings: true,
        large: true,
        dark: dark,
      );
      await tester.ensureVisible(find.text('Manage accommodation'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty itinerary and bookings provide trip creation', (
    tester,
  ) async {
    await mount(tester, componentBookings: true);
    expect(find.text('No trips yet'), findsOneWidget);
    await tester.tap(find.text('Add Trip'));
    await tester.pumpAndSettle();
    expect(find.text('Create trip screen'), findsOneWidget);
  });
}
