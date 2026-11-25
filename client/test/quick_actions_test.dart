import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/auth/domain/models/auth_state.dart';
import 'package:tapittrip/features/auth/domain/models/auth_user.dart';
import 'package:tapittrip/features/auth/presentation/providers/auth_provider.dart';
import 'package:tapittrip/features/circles/presentation/providers/trip_circle_provider.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';
import 'package:tapittrip/features/trips/presentation/pages/trip_list_page.dart';
import 'package:tapittrip/features/trips/presentation/providers/trip_list_provider.dart';
import 'package:tapittrip/features/weather/domain/models/trip_weather.dart';
import 'package:tapittrip/features/weather/presentation/providers/weather_provider.dart';

class _TestTrips extends TripListNotifier {
  _TestTrips(this.items);
  final List<Trip> items;

  @override
  Future<List<Trip>> build() async => items;

  @override
  Future<void> refresh() async => state = AsyncData(items);
}

class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
    user: AuthUser(
      id: 'user-1',
      name: 'Traveler',
      displayName: 'Traveler',
      email: 'traveler@example.test',
      friendCode: 'TRP-123456',
    ),
    token: 'test-token',
  );
}

Trip _sampleTrip({
  required String id,
  required String title,
  String? country,
  String? role,
}) {
  return Trip(
    id: id,
    ownerId: 'user-1',
    title: title,
    destinationCountry: country,
    role: role,
  );
}

Widget _buildTestApp({
  required List<Trip> trips,
  required List<String> navigatedRoutes,
}) {
  final router = GoRouter(
    initialLocation: '/trips',
    routes: [
      GoRoute(
        path: '/trips',
        builder: (context, state) => const TripListPage(),
      ),
      GoRoute(
        path: '/trips/new',
        builder: (context, state) {
          navigatedRoutes.add(state.uri.toString());
          return const Scaffold(body: Text('New Trip Page'));
        },
      ),
      GoRoute(
        path: '/trips/:tripId/itinerary',
        builder: (context, state) {
          navigatedRoutes.add(state.uri.toString());
          return Scaffold(
            appBar: AppBar(),
            body: Text('Itinerary:${state.uri}'),
          );
        },
      ),
      GoRoute(
        path: '/trips/:tripId/expenses',
        builder: (context, state) {
          navigatedRoutes.add(state.uri.toString());
          return Scaffold(
            appBar: AppBar(),
            body: Text('Expenses:${state.uri}'),
          );
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith(_TestAuth.new),
      tripListProvider.overrideWith(() => _TestTrips(trips)),
      pendingInboxCountProvider.overrideWithValue(0),
      for (final trip in trips)
        tripWeatherProvider(trip.id)
            .overrideWith((_) => Completer<TripWeather>().future),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void main() {
  group('TripListPage Quick Actions', () {
    testWidgets('single trip routes all 4 actions to their real destinations', (
      tester,
    ) async {
      final routes = <String>[];
      final trip = _sampleTrip(
        id: 'trip-tokyo',
        title: 'Tokyo Spring',
        country: 'Japan',
        role: 'owner',
      );

      await tester.pumpWidget(
        _buildTestApp(trips: [trip], navigatedRoutes: routes),
      );
      await tester.pumpAndSettle();

      // 1. AI Itinerary
      await tester.tap(find.text('AI Itinerary'));
      await tester.pumpAndSettle();
      expect(routes.last, '/trips/trip-tokyo/itinerary?action=ai-plan');
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 2. Smart Route
      await tester.tap(find.text('Smart Route'));
      await tester.pumpAndSettle();
      expect(routes.last, '/trips/trip-tokyo/itinerary?tab=transport');
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 3. Budget Plan
      await tester.tap(find.text('Budget Plan'));
      await tester.pumpAndSettle();
      expect(routes.last, '/trips/trip-tokyo/expenses');
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 4. Travel Guide
      await tester.tap(find.text('Travel Guide'));
      await tester.pumpAndSettle();
      expect(routes.last, '/trips/trip-tokyo/itinerary?tab=recommendations');
    });

    testWidgets('multiple trips opens picker sheet and routes chosen trip', (
      tester,
    ) async {
      final routes = <String>[];
      final trips = [
        _sampleTrip(id: 't1', title: 'Tokyo Spring', country: 'Japan'),
        _sampleTrip(id: 't2', title: 'Paris Autumn', country: 'France'),
      ];

      await tester.pumpWidget(
        _buildTestApp(trips: trips, navigatedRoutes: routes),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Budget Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Create new trip instead'), findsOneWidget);
      await tester.tap(find.text('Paris Autumn').last);
      await tester.pumpAndSettle();

      expect(routes.last, '/trips/t2/expenses');
    });

    testWidgets('empty trip list falls back to /trips/new', (tester) async {
      final routes = <String>[];

      await tester.pumpWidget(
        _buildTestApp(trips: const [], navigatedRoutes: routes),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Smart Route'));
      await tester.pumpAndSettle();

      expect(routes.last, '/trips/new');
    });
  });
}
