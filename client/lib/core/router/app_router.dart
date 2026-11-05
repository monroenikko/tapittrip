import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/itinerary/presentation/pages/trip_itinerary_page.dart';
import '../../features/trips/domain/models/trip.dart';
import '../../features/trips/presentation/pages/trip_create_page.dart';
import '../../features/trips/presentation/pages/trip_list_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState>(ref.watch(authProvider));
  ref.listen<AuthState>(authProvider, (_, next) => authNotifier.value = next);

  return GoRouter(
    initialLocation: '/trips',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = authNotifier.value;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      if (auth is Authenticated) {
        if (isLoggingIn || isRegistering) {
          return '/trips';
        }
      } else if (auth is Unauthenticated || auth is AuthFailure) {
        if (!isLoggingIn && !isRegistering) {
          return '/login';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/trips',
        builder: (context, state) => const TripListPage(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const TripCreatePage(),
          ),
          GoRoute(
            path: ':tripId/itinerary',
            builder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              final trip = state.extra as Trip?;
              return TripItineraryPage(tripId: tripId, initialTrip: trip);
            },
          ),
        ],
      ),
    ],
  );
});
