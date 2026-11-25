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
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
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

Widget _buildApp(List<Trip> trips) {
  final router = GoRouter(
    initialLocation: '/trips',
    routes: [
      GoRoute(
        path: '/trips',
        builder: (context, state) => const TripListPage(),
      ),
      GoRoute(
        path: '/trips/new',
        builder: (context, state) => const Scaffold(body: Text('New Trip')),
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
  final trips = [
    const Trip(
      id: 't1',
      ownerId: 'user-1',
      title: 'Kyoto Autumn',
      destinationCountry: 'Japan',
      planningMode: PlanningMode.diy,
      tripType: 'leisure',
    ),
    const Trip(
      id: 't2',
      ownerId: 'user-1',
      title: 'BGC Summit',
      destinationCountry: 'Philippines',
      planningMode: PlanningMode.guided,
      tripType: 'business',
    ),
  ];

  group('TripListPage Live Search & Filters', () {
    testWidgets('filters trips by query and clears cleanly', (tester) async {
      await tester.pumpWidget(_buildApp(trips));
      await tester.pumpAndSettle();

      expect(find.text('Kyoto Autumn'), findsOneWidget);
      expect(find.text('BGC Summit'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Japan');
      await tester.pumpAndSettle();

      expect(find.text('Kyoto Autumn'), findsOneWidget);
      expect(find.text('BGC Summit'), findsNothing);

      // Clear search
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(find.text('Kyoto Autumn'), findsOneWidget);
      expect(find.text('BGC Summit'), findsOneWidget);
    });

    testWidgets('filters trips via filter sheet and shows empty-search reset', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(trips));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Filter trips'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Trips'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Guided Tour'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Kyoto Autumn'), findsNothing);
      expect(find.text('BGC Summit'), findsOneWidget);

      // Combine with non-matching search query
      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pumpAndSettle();

      expect(find.text('No matching trips'), findsOneWidget);

      await tester.ensureVisible(find.text('Clear filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('Kyoto Autumn'), findsOneWidget);
      expect(find.text('BGC Summit'), findsOneWidget);
    });
  });
}
