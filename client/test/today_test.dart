import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/core/utils/map_launcher.dart';
import 'package:tapittrip/features/itinerary/domain/models/itinerary_item.dart';
import 'package:tapittrip/features/itinerary/domain/models/place.dart';
import 'package:tapittrip/features/stays/domain/models/stay.dart';
import 'package:tapittrip/features/today/domain/models/today_dashboard_summary.dart';
import 'package:tapittrip/features/today/presentation/pages/today_dashboard_page.dart';
import 'package:tapittrip/features/today/presentation/providers/today_provider.dart';
import 'package:tapittrip/features/today/presentation/widgets/current_stay_banner.dart';
import 'package:tapittrip/features/today/presentation/widgets/next_stop_card.dart';
import 'package:tapittrip/features/today/presentation/widgets/quick_actions_grid.dart';
import 'package:tapittrip/features/today/presentation/widgets/today_hero_card.dart';
import 'package:tapittrip/features/today/presentation/widgets/trip_progress_card.dart';
import 'package:tapittrip/features/trips/data/trip_repository.dart';
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';

class _FakeTripRepository implements TripRepository {
  _FakeTripRepository(this._trips);

  final List<Trip> _trips;

  @override
  Future<List<Trip>> getTrips() async => List.unmodifiable(_trips);

  @override
  Future<Trip> getTrip(String id) async => _trips.firstWhere((t) => t.id == id);

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
    return _trips.first;
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
    return _trips.first;
  }

  @override
  Future<void> deleteTrip(String id) async {}
}

Widget _buildTestApp(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('MapLauncher Unit Tests', () {
    test(
      'launchDirections returns false when no destination is provided',
      () async {
        final result = await MapLauncher.launchDirections();
        expect(result, isFalse);
      },
    );

    test('launchDirections returns false for empty strings', () async {
      final result = await MapLauncher.launchDirections(query: '   ');
      expect(result, isFalse);
    });
  });

  group('TodayDashboardSummary Domain Model', () {
    final sampleTrip = Trip(
      id: 'trip-1',
      ownerId: 'user-1',
      title: 'Japan Autumn Adventure',
      destinationCountry: 'Japan',
      startDate: '2026-11-06',
      endDate: '2026-11-12',
      primaryTimezone: 'Asia/Tokyo',
      planningMode: PlanningMode.diy,
      tripType: 'international',
    );

    test('parses active trip JSON correctly', () {
      final json = {
        'trip': sampleTrip.toJson(),
        'trip_status': 'active',
        'active_day': {
          'day_number': 3,
          'total_days': 7,
          'date': '2026-11-08',
          'notes': 'Exploring Shibuya and Shinjuku',
        },
        'today_items': [
          {
            'id': 'item-1',
            'trip_id': 'trip-1',
            'title': 'Shibuya Crossing',
            'kind': 'attraction',
            'status': 'visited',
            'sort_order': 0,
            'place': {
              'id': 'place-1',
              'name': 'Shibuya Crossing',
              'formatted_address': 'Shibuya, Tokyo',
            },
          },
          {
            'id': 'item-2',
            'trip_id': 'trip-1',
            'title': 'Meiji Shrine',
            'kind': 'attraction',
            'status': 'planned',
            'sort_order': 1,
            'place': {
              'id': 'place-2',
              'name': 'Meiji Shrine',
              'formatted_address': 'Yoyogikamizonocho, Shibuya City, Tokyo',
            },
          },
        ],
        'next_upcoming_item': {
          'id': 'item-2',
          'trip_id': 'trip-1',
          'title': 'Meiji Shrine',
          'kind': 'attraction',
          'status': 'planned',
          'sort_order': 1,
        },
        'current_stay': {
          'id': 'stay-1',
          'trip_id': 'trip-1',
          'name': 'Cerulean Tower Tokyu Hotel',
          'stay_type': 'hotel',
          'check_in_at': '2026-11-06T15:00:00Z',
          'check_out_at': '2026-11-12T11:00:00Z',
          'address': '26-1 Sakuragaokacho, Shibuya City, Tokyo',
          'google_maps_directions_url':
              'https://maps.apple.com/?daddr=Cerulean+Tower',
        },
        'metrics': {
          'total_activities': 2,
          'completed_activities': 1,
          'progress_percentage': 50,
        },
        'timezone': 'Asia/Tokyo',
      };

      final summary = TodayDashboardSummary.fromJson(json);

      expect(summary.isActive, isTrue);
      expect(summary.isPreTrip, isFalse);
      expect(summary.isPostTrip, isFalse);
      expect(summary.statusBadgeText, 'Day 3 of 7');
      expect(summary.activeDay?.dayNumber, 3);
      expect(summary.activeDay?.totalDays, 7);
      expect(summary.todayItems.length, 2);
      expect(summary.nextUpcomingItem?.title, 'Meiji Shrine');
      expect(summary.currentStay?.name, 'Cerulean Tower Tokyu Hotel');
      expect(summary.metrics.progressPercentage, 50);
      expect(summary.metrics.completedActivities, 1);
    });

    test('parses pre-trip countdown and statusBadgeText correctly', () {
      final json = {
        'trip': sampleTrip.toJson(),
        'trip_status': 'pre_trip',
        'days_until_start': 5,
        'metrics': {
          'total_activities': 0,
          'completed_activities': 0,
          'progress_percentage': 0,
        },
        'timezone': 'Asia/Tokyo',
      };

      final summary = TodayDashboardSummary.fromJson(json);

      expect(summary.isPreTrip, isTrue);
      expect(summary.isActive, isFalse);
      expect(summary.statusBadgeText, 'Starts in 5 days');
      expect(summary.daysUntilStart, 5);
    });

    test('supports trips without activities (traveler inclusivity v1.4)', () {
      final json = {
        'trip': sampleTrip.toJson(),
        'trip_status': 'active',
        'active_day': {'day_number': 1, 'total_days': 7, 'date': '2026-11-06'},
        'today_items': [],
        'next_upcoming_item': null,
        'current_stay': null,
        'metrics': {
          'total_activities': 0,
          'completed_activities': 0,
          'progress_percentage': 0,
        },
        'timezone': 'Asia/Tokyo',
      };

      final summary = TodayDashboardSummary.fromJson(json);

      expect(summary.isActive, isTrue);
      expect(summary.todayItems, isEmpty);
      expect(summary.nextUpcomingItem, isNull);
      expect(summary.currentStay, isNull);
      expect(summary.metrics.totalActivities, 0);
      expect(summary.metrics.progressPercentage, 0);
    });
  });

  group('Today Dashboard Widgets', () {
    final testTrip = Trip(
      id: 'trip-101',
      ownerId: 'user-1',
      title: 'Tokyo Explorer',
      destinationCountry: 'Japan',
      startDate: '2026-11-06',
      endDate: '2026-11-10',
      primaryTimezone: 'Asia/Tokyo',
      planningMode: PlanningMode.diy,
      tripType: 'international',
    );

    final testSummary = TodayDashboardSummary(
      trip: testTrip,
      tripStatus: 'active',
      activeDay: const ActiveDayInfo(
        dayNumber: 2,
        totalDays: 5,
        date: '2026-11-07',
        notes: 'Exploring vibrant Shibuya',
      ),
      metrics: const DashboardMetrics(
        totalActivities: 4,
        completedActivities: 2,
        progressPercentage: 50,
      ),
      nextUpcomingItem: const ItineraryItem(
        id: 'stop-2',
        tripId: 'trip-101',
        title: 'Shibuya Sky Observatory',
        kind: 'attraction',
        status: 'planned',
        place: Place(
          id: 'place-101',
          name: 'Shibuya Scramble Square',
          formattedAddress: '2 Chome-24-12 Shibuya',
        ),
      ),
      currentStay: Stay(
        id: 'stay-101',
        tripId: 'trip-101',
        name: 'Hotel Indigo Tokyo Shibuya',
        stayType: 'hotel',
        checkInAt: DateTime.parse('2026-11-06T15:00:00Z'),
        checkOutAt: DateTime.parse('2026-11-10T11:00:00Z'),
        address: '2-25-12 Dogenzaka, Shibuya',
        googleMapsDirectionsUrl: 'https://maps.apple.com/?daddr=Hotel+Indigo',
      ),
      timezone: 'Asia/Tokyo',
    );

    testWidgets('TodayHeroCard displays destination, status badge, and dates', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(TodayHeroCard(summary: testSummary)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tokyo Explorer'), findsOneWidget);
      expect(find.text('Day 2 of 5'), findsOneWidget);
    });

    testWidgets('TripProgressCard displays progress ring and percentage', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(TripProgressCard(summary: testSummary)),
      );
      await tester.pumpAndSettle();

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('2/4 stops'), findsOneWidget);
      expect(find.text('Asia/Tokyo'), findsOneWidget);
    });

    testWidgets(
      'NextStopCard renders next upcoming stop with directions button',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(NextStopCard(summary: testSummary)),
        );
        await tester.pumpAndSettle();

        expect(find.text('NEXT STOP'), findsOneWidget);
        expect(find.text('Shibuya Sky Observatory'), findsOneWidget);
        expect(find.text('Shibuya Scramble Square'), findsOneWidget);
        expect(find.text('Directions'), findsOneWidget);
        expect(find.text('Visited'), findsOneWidget);
      },
    );

    testWidgets(
      'NextStopCard renders friendly empty state when no stops remain',
      (tester) async {
        final emptySummary = TodayDashboardSummary(
          trip: testTrip,
          tripStatus: 'active',
          activeDay: const ActiveDayInfo(
            dayNumber: 2,
            totalDays: 5,
            date: '2026-11-07',
          ),
          metrics: const DashboardMetrics(
            totalActivities: 0,
            completedActivities: 0,
            progressPercentage: 0,
          ),
          todayItems: const [],
          nextUpcomingItem: null,
          timezone: 'Asia/Tokyo',
        );

        await tester.pumpWidget(
          _buildTestApp(NextStopCard(summary: emptySummary)),
        );
        await tester.pumpAndSettle();

        expect(find.text('No stops scheduled today'), findsOneWidget);
        expect(find.text('+ Add Activity'), findsOneWidget);
      },
    );

    testWidgets(
      'CurrentStayBanner renders stay name, address, and directions action',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(CurrentStayBanner(summary: testSummary)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hotel Indigo Tokyo Shibuya'), findsOneWidget);
        expect(find.text('2-25-12 Dogenzaka, Shibuya'), findsOneWidget);
        expect(find.text('Directions'), findsOneWidget);
        expect(find.text('Arrival Transport'), findsOneWidget);
      },
    );

    testWidgets('QuickActionsGrid renders 4 action buttons', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(QuickActionsGrid(summary: testSummary)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Itinerary'), findsOneWidget);
      expect(find.text('Stays'), findsOneWidget);
      expect(find.text('+ Stop'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
    });

    testWidgets('TodayDashboardPage renders full dashboard when trips exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          const TodayDashboardPage(initialTripId: 'trip-101'),
          overrides: [
            tripRepositoryProvider.overrideWithValue(
              _FakeTripRepository([testTrip]),
            ),
            todaySummaryProvider('trip-101')
                .overrideWith((ref) async => testSummary),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tokyo Explorer'), findsAtLeastNWidgets(1));
      expect(find.text('NEXT STOP'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Hotel Indigo Tokyo Shibuya'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Hotel Indigo Tokyo Shibuya'), findsOneWidget);
    });
  });
}
