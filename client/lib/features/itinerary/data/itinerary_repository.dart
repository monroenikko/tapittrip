// ignore_for_file: use_null_aware_elements

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../domain/models/itinerary_item.dart';
import '../domain/models/place.dart';
import '../domain/models/trip_day.dart';
import '../domain/models/visit_event.dart';

class ItineraryRepository {
  ItineraryRepository({required this.apiClient, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  String _cacheKey(String tripId) => 'cached_itinerary_$tripId';
  String _daysCacheKey(String tripId) => 'cached_days_$tripId';

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
            .map((json) => TripDay.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException {
      final cached = await _storage.read(key: _daysCacheKey(tripId));
      if (cached != null) {
        final data = jsonDecode(cached) as List<dynamic>;
        return data
            .map((json) => TripDay.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    } catch (_) {
      final cached = await _storage.read(key: _daysCacheKey(tripId));
      if (cached != null) {
        final data = jsonDecode(cached) as List<dynamic>;
        return data
            .map((json) => TripDay.fromJson(json as Map<String, dynamic>))
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

    return TripDay.fromJson(response as Map<String, dynamic>);
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

      if (response is List) {
        if (tripDayId == null) {
          await _storage.write(
            key: _cacheKey(tripId),
            value: jsonEncode(response),
          );
        }

        return response
            .map((json) => ItineraryItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException {
      final cached = await _storage.read(key: _cacheKey(tripId));
      if (cached != null) {
        final data = jsonDecode(cached) as List<dynamic>;
        var items = data
            .map((json) => ItineraryItem.fromJson(json as Map<String, dynamic>))
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
            .map((json) => ItineraryItem.fromJson(json as Map<String, dynamic>))
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

    return ItineraryItem.fromJson(response as Map<String, dynamic>);
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
    };

    final response = await apiClient.patch(
      '/itinerary-items/$itemId',
      data: payload,
    );

    return ItineraryItem.fromJson(response as Map<String, dynamic>);
  }

  /// Reorder itinerary items in bulk.
  Future<List<ItineraryItem>> reorderItems(
    String tripId,
    List<String> orderedItemIds,
  ) async {
    final response = await apiClient.post(
      '/trips/$tripId/itinerary-items/reorder',
      data: {'item_ids': orderedItemIds},
    );

    if (response is List) {
      await _storage.write(key: _cacheKey(tripId), value: jsonEncode(response));

      return response
          .map((json) => ItineraryItem.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
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
          .map((json) => Place.fromJson(json as Map<String, dynamic>))
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

    return VisitEvent.fromJson(response as Map<String, dynamic>);
  }
}
