import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/features/itinerary/data/itinerary_repository.dart';
import 'package:tapittrip/features/itinerary/domain/models/food_suggestion.dart';
import 'package:tapittrip/features/itinerary/domain/models/itinerary_item.dart';
import 'package:tapittrip/features/itinerary/domain/models/place.dart';
import 'package:tapittrip/features/itinerary/domain/models/route_optimization_result.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/food_discovery_section.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/route_optimization_sheet.dart';

import 'trip_assistant_test.dart' show FakeAssistantApiClient;

class _FakeItineraryRepository extends ItineraryRepository {
  _FakeItineraryRepository() : super(apiClient: FakeAssistantApiClient());

  bool lastApplyValue = false;
  int optimizeCalls = 0;
  String lastMealType = 'all';
  int foodCalls = 0;
  final List<String> createdMealTitles = <String>[];

  @override
  Future<RouteOptimizationResult> optimizeRoute(
    String tripId, {
    String? tripDayId,
    bool apply = false,
    bool preserveFixedTimes = true,
    int maxWalkingMetersPerLeg = 1500,
    Map<String, int>? expectedVersions,
  }) async {
    optimizeCalls++;
    lastApplyValue = apply;
    return RouteOptimizationResult.fromJson({
      'trip_id': tripId,
      'trip_day_id': tripDayId,
      'applied': apply,
      'is_already_optimal': false,
      'current_item_ids': ['item-1', 'item-2', 'item-3'],
      'proposed_item_ids': ['item-2', 'item-1', 'item-3'],
      'pinned_item_ids': ['item-3'],
      'current_total_distance_km': 18.4,
      'optimized_total_distance_km': 9.2,
      'distance_saved_km': 9.2,
      'estimated_co2_saved_kg': 1.1,
      'constraints_applied': {
        'preserve_fixed_times': preserveFixedTimes,
        'max_walking_meters_per_leg': maxWalkingMetersPerLeg,
        'anchor_stay_name': 'Asakusa View Hotel',
      },
      'segments': [
        {
          'from_item_id': 'item-2',
          'from_title': 'Senso-ji Temple',
          'from_place_name': 'Senso-ji Temple',
          'to_item_id': 'item-1',
          'to_title': 'Shibuya Sky',
          'to_place_name': 'Shibuya Sky',
          'trip_day_id': 'day-1',
          'distance_meters': 9200,
          'distance_km': 9.2,
          'recommended_mode': 'taxi_rideshare',
          'estimated_duration_minutes': 27,
          'exceeds_walking_limit': true,
          'mode_comparisons': [
            {
              'mode': 'walk',
              'label': 'Walk',
              'estimated_duration_minutes': 123,
              'suitability': 'long_walk',
              'advisory_note': 'Exceeds 1500 m walking threshold.',
              'google_maps_directions_url':
                  'https://www.google.com/maps/dir/?api=1&travelmode=walking',
            },
            {
              'mode': 'public_transit',
              'label': 'Public Transit',
              'estimated_duration_minutes': 37,
              'suitability': 'alternative',
              'advisory_note': 'Includes ~6 min station walk/transfer buffer.',
              'google_maps_directions_url':
                  'https://www.google.com/maps/dir/?api=1&travelmode=transit',
            },
          ],
          'provider_attribution': 'Haversine geometric estimate',
          'verified': false,
          'limitation_notice': 'Advisory geometric estimate.',
        },
      ],
      'items': const [],
      'provider_attribution': 'TapItTrip Geometric Route Optimizer',
      'verified': false,
      'advisory_notice': 'Distances use 1.3x urban route factor.',
    });
  }

  @override
  Future<FoodSuggestionsResult> fetchFoodSuggestions(
    String tripId, {
    String mealType = 'all',
    String? dietary,
    String near = 'stay',
  }) async {
    foodCalls++;
    lastMealType = mealType;
    final all = [
      {
        'id': 'food-jp-breakfast-1',
        'name': 'Asakusa Kissaten Roastery',
        'cuisine': 'Japanese Kissaten & Coffee',
        'meal_type': 'breakfast',
        'neighborhood': 'Asakusa',
        'proximity_label': '5–10 min walk from Asakusa View Hotel',
        'dietary_tags': ['vegetarian', 'kid_friendly'],
        'price_tier': 'budget',
        'notes': 'Thick-cut shokupan toast sets and hand-drip coffee.',
        'google_maps_search_url':
            'https://www.google.com/maps/search/?api=1&query=Asakusa',
        'suggested_action': {
          'label': 'Add Breakfast at Asakusa Kissaten Roastery',
          'kind': 'add_activity',
          'payload': {
            'title': 'Breakfast at Asakusa Kissaten Roastery',
            'kind': 'meal',
            'place_name': 'Asakusa Kissaten Roastery',
            'notes': 'Thick-cut shokupan toast sets.',
          },
        },
        'provider_attribution': 'TapItTrip Curated Culinary Directory',
        'verified': false,
      },
      {
        'id': 'food-jp-dinner-1',
        'name': 'Shinjuku Teishoku Dining',
        'cuisine': 'Japanese Set Meals & Grill',
        'meal_type': 'dinner',
        'neighborhood': 'Shinjuku',
        'proximity_label': '5–10 min walk from Asakusa View Hotel',
        'dietary_tags': ['halal', 'kid_friendly'],
        'price_tier': 'moderate',
        'notes': 'Balanced grilled fish and halal-friendly skewers.',
        'google_maps_search_url':
            'https://www.google.com/maps/search/?api=1&query=Shinjuku',
        'suggested_action': {
          'label': 'Add Dinner at Shinjuku Teishoku Dining',
          'kind': 'add_activity',
          'payload': {
            'title': 'Dinner at Shinjuku Teishoku Dining',
            'kind': 'meal',
            'place_name': 'Shinjuku Teishoku Dining',
            'notes': 'Balanced grilled fish.',
          },
        },
        'provider_attribution': 'TapItTrip Curated Culinary Directory',
        'verified': false,
      },
    ];

    final filtered = all
        .where((item) => mealType == 'all' || item['meal_type'] == mealType)
        .toList();

    return FoodSuggestionsResult.fromJson({
      'trip_id': tripId,
      'destination': 'Tokyo (JP)',
      'anchor_stay_name': 'Asakusa View Hotel',
      'filters_applied': {
        'meal_type': mealType,
        'dietary': dietary,
        'near': near,
      },
      'source': 'curated_directory',
      'verified': false,
      'advisory_notice': 'Curated dining ideas; confirm hours in Maps.',
      'suggestions': filtered,
    });
  }

  @override
  Future<List<ItineraryItem>> fetchItems(
    String tripId, {
    String? tripDayId,
  }) async {
    return const [];
  }

  @override
  Future<ItineraryItem> createItem(
    String tripId, {
    required String title,
    String kind = 'attraction',
    String? tripDayId,
    String? placeId,
    Map<String, dynamic>? inlinePlace,
    String? notes,
    String? startsAtUtc,
    String? endsAtUtc,
    String? timezone,
  }) async {
    createdMealTitles.add(title);
    return ItineraryItem(id: 'new-meal', tripId: tripId, title: title);
  }
}

void main() {
  test('RouteMetricsCalculator computes real Haversine urban distances and handles unknown coordinates transparently', () {
    const items = [
      ItineraryItem(
        id: 'item-1',
        tripId: 'trip-1',
        tripDayId: 'day-1',
        title: 'Senso-ji Temple',
        place: Place(
          id: 'p1',
          name: 'Senso-ji Temple',
          latitude: 35.7147,
          longitude: 139.7967,
        ),
      ),
      ItineraryItem(
        id: 'item-2',
        tripId: 'trip-1',
        tripDayId: 'day-1',
        title: 'Nakamise Shopping Street',
        place: Place(
          id: 'p2',
          name: 'Nakamise',
          latitude: 35.7120,
          longitude: 139.7964,
        ),
      ),
      ItineraryItem(
        id: 'item-3',
        tripId: 'trip-1',
        tripDayId: 'day-1',
        title: 'Ungeocoded Evening Stop',
      ),
    ];

    final metrics = RouteMetricsCalculator.computeForItems(items);
    expect(metrics.geocodedCount, 2);
    expect(metrics.totalDistanceKm, greaterThan(0.2));
    expect(metrics.totalDistanceKm, lessThan(1.0));
    expect(metrics.segments, hasLength(2));
    expect(metrics.segments[0].recommendedMode, 'walk');
    expect(metrics.segments[1].recommendedMode, 'unknown_coordinates');
    expect(metrics.segments[1].distanceMeters, isNull);
  });

  testWidgets(
    'RouteOptimizationSheet previews distance savings, shows pinned constraints, and applies on user approval',
    (tester) async {
      final repo = _FakeItineraryRepository();
      const items = [
        ItineraryItem(id: 'item-1', tripId: 'trip-1', title: 'Shibuya Sky'),
        ItineraryItem(id: 'item-2', tripId: 'trip-1', title: 'Senso-ji Temple'),
        ItineraryItem(
          id: 'item-3',
          tripId: 'trip-1',
          title: 'Reserved Dinner',
          startsAtUtc: '2026-06-01T10:00:00Z',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [itineraryRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: Scaffold(
              body: RouteOptimizationSheet(
                tripId: 'trip-1',
                currentItems: items,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('18.4 km'), findsOneWidget);
      expect(find.text('9.2 km'), findsNWidgets(2)); // Optimized & Saved
      expect(find.text('Pinned constraint'), findsOneWidget);
      expect(repo.lastApplyValue, isFalse);

      await tester.ensureVisible(find.text('Approve & Apply Route Order'));
      await tester.tap(find.text('Approve & Apply Route Order'));
      await tester.pumpAndSettle();

      expect(repo.optimizeCalls, 2);
      expect(repo.lastApplyValue, isTrue);
    },
  );

  testWidgets(
    'FoodDiscoverySection filters by meal type and adds suggested meal to itinerary',
    (tester) async {
      final repo = _FakeItineraryRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [itineraryRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FoodDiscoverySection(
                  tripId: 'trip-1',
                  destination: 'Tokyo, JP',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Restaurant & Food Discovery'), findsOneWidget);
      expect(
        find.text('Curated dining near Asakusa View Hotel'),
        findsOneWidget,
      );
      expect(find.text('Asakusa Kissaten Roastery'), findsOneWidget);
      expect(find.text('Shinjuku Teishoku Dining'), findsOneWidget);

      // Filter by Dinner chip
      await tester.tap(find.text('Dinner'));
      await tester.pumpAndSettle();

      expect(repo.lastMealType, 'dinner');
      expect(find.text('Asakusa Kissaten Roastery'), findsNothing);
      expect(find.text('Shinjuku Teishoku Dining'), findsOneWidget);

      // Tap Add to Itinerary
      await tester.tap(find.text('Add to Itinerary'));
      await tester.pumpAndSettle();

      expect(repo.createdMealTitles, ['Dinner at Shinjuku Teishoku Dining']);
    },
  );
}
