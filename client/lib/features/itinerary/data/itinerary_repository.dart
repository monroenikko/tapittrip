// ignore_for_file: use_null_aware_elements

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../circles/data/trip_circle_repository.dart';
import '../domain/models/food_suggestion.dart';
import '../domain/models/itinerary_item.dart';
import '../domain/models/place.dart';
import '../domain/models/route_optimization_result.dart';
import '../domain/models/trip_day.dart';
import '../domain/models/visit_event.dart';

class ItineraryRepository {
  ItineraryRepository({required this.apiClient, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  String _cacheKey(String tripId) => 'cached_itinerary_$tripId';
  String _daysCacheKey(String tripId) => 'cached_days_$tripId';
  String _foodCacheKey(String tripId, String mealType) =>
      'cached_food_suggestions_${tripId}_$mealType';
  String _routeOptimizationCacheKey(String tripId) =>
      'cached_route_optimization_$tripId';

  /// Fetch all scheduled days for a trip with offline cache support.
  Future<List<TripDay>> fetchDays(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/days');

      if (response is List) {
        await _storage.write(
          key: _daysCacheKey(tripId),
          value: jsonEncode(response),
        );

        return response
            .whereType<Map>()
            .map((json) => TripDay.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      return [];
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.code == 'forbidden') {
        await TripCircleRepository.purgeAllTripCachesForStorage(
          storage: _storage,
          tripId: tripId,
        );
        rethrow;
      }
      final cached = await _storage.read(key: _daysCacheKey(tripId));
      if (cached != null) {
        final data = jsonDecode(cached) as List<dynamic>;
        return data
            .whereType<Map>()
            .map((json) => TripDay.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      rethrow;
    } catch (_) {
      final cached = await _storage.read(key: _daysCacheKey(tripId));
      if (cached != null) {
        final data = jsonDecode(cached) as List<dynamic>;
        return data
            .whereType<Map>()
            .map((json) => TripDay.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      rethrow;
    }
  }

  /// Create a new trip day.
  Future<TripDay> createDay(
    String tripId, {
    required String localDate,
    String? notes,
  }) async {
    final response = await apiClient.post(
      '/trips/$tripId/days',
      data: {'local_date': localDate, if (notes != null) 'notes': notes},
    );

    return TripDay.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Fetch all itinerary items for a trip with offline cache support.
  Future<List<ItineraryItem>> fetchItems(
    String tripId, {
    String? tripDayId,
  }) async {
    try {
      final response = await apiClient.get(
        '/trips/$tripId/itinerary-items',
        queryParameters: {if (tripDayId != null) 'trip_day_id': tripDayId},
      );

      final List<dynamic> list;
      if (response is List) {
        list = response;
      } else if (response is Map && response['data'] is List) {
        list = response['data'] as List<dynamic>;
      } else {
        list = const [];
      }

      if (tripDayId == null) {
        await _storage.write(key: _cacheKey(tripId), value: jsonEncode(list));
      }

      return list
          .whereType<Map>()
          .map(
            (json) => ItineraryItem.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.code == 'forbidden') {
        await TripCircleRepository.purgeAllTripCachesForStorage(
          storage: _storage,
          tripId: tripId,
        );
        rethrow;
      }
      final cached = await _storage.read(key: _cacheKey(tripId));
      if (cached != null) {
        final data = jsonDecode(cached) as List<dynamic>;
        var items = data
            .whereType<Map>()
            .map(
              (json) => ItineraryItem.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
        if (tripDayId != null) {
          items = items.where((it) => it.tripDayId == tripDayId).toList();
        }
        return items;
      }
      rethrow;
    } catch (_) {
      final cached = await _storage.read(key: _cacheKey(tripId));
      if (cached != null) {
        final data = jsonDecode(cached) as List<dynamic>;
        var items = data
            .whereType<Map>()
            .map(
              (json) => ItineraryItem.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
        if (tripDayId != null) {
          items = items.where((it) => it.tripDayId == tripDayId).toList();
        }
        return items;
      }
      rethrow;
    }
  }

  /// Create a new itinerary item/stop.
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
    final payload = <String, dynamic>{
      'title': title,
      'kind': kind,
      if (tripDayId != null) 'trip_day_id': tripDayId,
      if (placeId != null) 'place_id': placeId,
      if (inlinePlace != null) 'place': inlinePlace,
      if (notes != null) 'notes': notes,
      if (startsAtUtc != null) 'starts_at_utc': startsAtUtc,
      if (endsAtUtc != null) 'ends_at_utc': endsAtUtc,
      if (timezone != null) 'timezone': timezone,
    };

    final response = await apiClient.post(
      '/trips/$tripId/itinerary-items',
      data: payload,
    );

    return ItineraryItem.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Write updated items list into offline cache safely.
  Future<void> cacheItems(String tripId, List<ItineraryItem> items) async {
    try {
      await _storage.write(
        key: _cacheKey(tripId),
        value: jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  /// Update an itinerary item.
  Future<ItineraryItem> updateItem(
    String itemId, {
    String? title,
    String? kind,
    String? tripDayId,
    String? placeId,
    Map<String, dynamic>? inlinePlace,
    String? status,
    String? notes,
    int? sortOrder,
    int? baseVersion,
  }) async {
    final payload = <String, dynamic>{
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (tripDayId != null) 'trip_day_id': tripDayId,
      if (placeId != null) 'place_id': placeId,
      if (inlinePlace != null) 'place': inlinePlace,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (baseVersion != null) 'base_version': baseVersion,
    };

    final response = await apiClient.patch(
      '/itinerary-items/$itemId',
      data: payload,
    );

    return ItineraryItem.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Reorder itinerary items in bulk, optionally reassigning trip days.
  Future<List<ItineraryItem>> reorderItems(
    String tripId,
    List<String> orderedItemIds, {
    Map<String, String?>? dayAssignments,
    Map<String, int>? expectedVersions,
  }) async {
    final payload = <String, dynamic>{
      'item_ids': orderedItemIds,
      if (dayAssignments != null && dayAssignments.isNotEmpty)
        'day_assignments': dayAssignments,
      if (expectedVersions != null && expectedVersions.isNotEmpty)
        'expected_versions': expectedVersions,
    };

    final response = await apiClient.post(
      '/trips/$tripId/itinerary-items/reorder',
      data: payload,
    );

    final List<dynamic> list;
    if (response is List) {
      list = response;
    } else if (response is Map && response['data'] is List) {
      list = response['data'] as List<dynamic>;
    } else {
      list = const [];
    }

    if (list.isNotEmpty) {
      await _storage.write(key: _cacheKey(tripId), value: jsonEncode(list));
    }

    return list
        .whereType<Map>()
        .map((json) => ItineraryItem.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  /// Delete an itinerary item.
  Future<void> deleteItem(String itemId) async {
    await apiClient.delete('/itinerary-items/$itemId');
  }

  /// Search places by keyword query.
  Future<List<Place>> searchPlaces(String query) async {
    final response = await apiClient.get(
      '/places/search',
      queryParameters: {'q': query},
    );

    if (response is List) {
      return response
          .whereType<Map>()
          .map((json) => Place.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  /// Record a visit event for an itinerary item (suggested, confirmed, revoked).
  Future<VisitEvent> recordVisitEvent(
    String itemId, {
    required String eventType,
    String method = 'manual',
    double? accuracyM,
  }) async {
    final response = await apiClient.post(
      '/itinerary-items/$itemId/visit-events',
      data: {
        'event_type': eventType,
        'method': method,
        if (accuracyM != null) 'accuracy_m': accuracyM,
      },
    );

    return VisitEvent.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Cast or clear a Trip Circle member vote ('up', 'down', or 'none') on an itinerary item.
  Future<ItineraryItem> voteItem(String itemId, {required String? vote}) async {
    final response = await apiClient.post(
      '/itinerary-items/$itemId/vote',
      data: {'vote': vote ?? 'none'},
    );

    final Map<String, dynamic> map;
    if (response is Map && response['data'] is Map) {
      map = Map<String, dynamic>.from(response['data'] as Map);
    } else if (response is Map) {
      map = Map<String, dynamic>.from(response);
    } else {
      map = const {};
    }

    return ItineraryItem.fromJson(map);
  }

  /// Evaluate stop-to-stop transit mode comparisons and optimize itinerary route order with constraints.
  Future<RouteOptimizationResult> optimizeRoute(
    String tripId, {
    String? tripDayId,
    bool apply = false,
    bool preserveFixedTimes = true,
    int maxWalkingMetersPerLeg = 1500,
    Map<String, int>? expectedVersions,
  }) async {
    try {
      final response = await apiClient.post(
        '/trips/$tripId/itinerary-items/optimize-route',
        data: {
          if (tripDayId != null) 'trip_day_id': tripDayId,
          'apply': apply,
          'preserve_fixed_times': preserveFixedTimes,
          'max_walking_meters_per_leg': maxWalkingMetersPerLeg,
          if (expectedVersions != null && expectedVersions.isNotEmpty)
            'expected_versions': expectedVersions,
        },
      );

      final Map<String, dynamic> map;
      if (response is Map && response['data'] is Map) {
        map = Map<String, dynamic>.from(response['data'] as Map);
      } else if (response is Map) {
        map = Map<String, dynamic>.from(response);
      } else {
        map = const {};
      }

      final result = RouteOptimizationResult.fromJson(map);

      if (tripDayId == null) {
        await _storage.write(
          key: _routeOptimizationCacheKey(tripId),
          value: jsonEncode(result.toJson()),
        );
      }
      if (result.applied && result.items.isNotEmpty && tripDayId == null) {
        await cacheItems(tripId, result.items);
      }

      return result;
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.code == 'forbidden') {
        await TripCircleRepository.purgeAllTripCachesForStorage(
          storage: _storage,
          tripId: tripId,
        );
        rethrow;
      }
      if (!apply) {
        final cached = await _storage.read(
          key: _routeOptimizationCacheKey(tripId),
        );
        if (cached != null) {
          return RouteOptimizationResult.fromJson(
            Map<String, dynamic>.from(jsonDecode(cached) as Map),
          );
        }
      }
      rethrow;
    } catch (_) {
      if (!apply) {
        final cached = await _storage.read(
          key: _routeOptimizationCacheKey(tripId),
        );
        if (cached != null) {
          return RouteOptimizationResult.fromJson(
            Map<String, dynamic>.from(jsonDecode(cached) as Map),
          );
        }
      }
      rethrow;
    }
  }

  /// Fetch curated destination and stay-aware restaurant & food suggestions.
  Future<FoodSuggestionsResult> fetchFoodSuggestions(
    String tripId, {
    String mealType = 'all',
    String? dietary,
    String near = 'stay',
  }) async {
    final cacheKey = _foodCacheKey(tripId, mealType);
    try {
      final response = await apiClient.get(
        '/trips/$tripId/food-suggestions',
        queryParameters: {
          'meal_type': mealType,
          if (dietary != null && dietary.isNotEmpty) 'dietary': dietary,
          'near': near,
        },
      );

      final Map<String, dynamic> map;
      if (response is Map && response['data'] is Map) {
        map = Map<String, dynamic>.from(response['data'] as Map);
      } else if (response is Map) {
        map = Map<String, dynamic>.from(response);
      } else {
        map = const {};
      }

      final result = FoodSuggestionsResult.fromJson(map);
      await _storage.write(key: cacheKey, value: jsonEncode(result.toJson()));
      return result;
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.code == 'forbidden') {
        await TripCircleRepository.purgeAllTripCachesForStorage(
          storage: _storage,
          tripId: tripId,
        );
        rethrow;
      }
      final cached = await _storage.read(key: cacheKey);
      if (cached != null) {
        return FoodSuggestionsResult.fromJson(
          Map<String, dynamic>.from(jsonDecode(cached) as Map),
        );
      }
      rethrow;
    } catch (_) {
      final cached = await _storage.read(key: cacheKey);
      if (cached != null) {
        return FoodSuggestionsResult.fromJson(
          Map<String, dynamic>.from(jsonDecode(cached) as Map),
        );
      }
      rethrow;
    }
  }
}
