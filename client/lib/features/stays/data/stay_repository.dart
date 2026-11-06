// ignore_for_file: use_null_aware_elements

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../domain/models/luggage_profile.dart';
import '../domain/models/stay.dart';
import '../domain/models/transport_option.dart';

class StayRepository {
  StayRepository({required this.apiClient, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  String _cacheKey(String tripId) => 'cached_stays_$tripId';

  /// Fetch all stays for a trip with offline cache support.
  Future<List<Stay>> fetchStays(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/stays');

      if (response is List) {
        await _storage.write(
          key: _cacheKey(tripId),
          value: jsonEncode(response),
        );

        return response
            .map((json) => Stay.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException {
      final cached = await _storage.read(key: _cacheKey(tripId));
      if (cached != null) {
        final data = jsonDecode(cached) as List<dynamic>;
        return data
            .map((json) => Stay.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    } catch (_) {
      final cached = await _storage.read(key: _cacheKey(tripId));
      if (cached != null) {
        final data = jsonDecode(cached) as List<dynamic>;
        return data
            .map((json) => Stay.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  /// Create a new stay for a trip.
  Future<Stay> createStay(
    String tripId, {
    required String name,
    String stayType = 'hotel',
    String? address,
    double? latitude,
    double? longitude,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String timezone = 'UTC',
    String? phone,
    String? bookingReference,
    String? notes,
    LuggageProfile? luggageProfile,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'stay_type': stayType,
      'timezone': timezone,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (checkInAt != null) 'check_in_at': checkInAt.toIso8601String(),
      if (checkOutAt != null) 'check_out_at': checkOutAt.toIso8601String(),
      if (phone != null) 'phone': phone,
      if (bookingReference != null) 'booking_reference': bookingReference,
      if (notes != null) 'notes': notes,
      if (luggageProfile != null) 'luggage_profile': luggageProfile.toJson(),
    };

    final response = await apiClient.post(
      '/trips/$tripId/stays',
      data: payload,
    );
    return Stay.fromJson(response as Map<String, dynamic>);
  }

  /// Update an existing stay.
  Future<Stay> updateStay(
    String stayId, {
    String? name,
    String? stayType,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? timezone,
    String? phone,
    String? bookingReference,
    String? notes,
    LuggageProfile? luggageProfile,
  }) async {
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (stayType != null) 'stay_type': stayType,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (checkInAt != null) 'check_in_at': checkInAt.toIso8601String(),
      if (checkOutAt != null) 'check_out_at': checkOutAt.toIso8601String(),
      if (timezone != null) 'timezone': timezone,
      if (phone != null) 'phone': phone,
      if (bookingReference != null) 'booking_reference': bookingReference,
      if (notes != null) 'notes': notes,
      if (luggageProfile != null) 'luggage_profile': luggageProfile.toJson(),
    };

    final response = await apiClient.patch('/stays/$stayId', data: payload);
    return Stay.fromJson(response as Map<String, dynamic>);
  }

  /// Delete a stay.
  Future<void> deleteStay(String stayId) async {
    await apiClient.delete('/stays/$stayId');
  }

  /// Compare arrival transport options for a stay.
  Future<TransportComparisonResult> compareTransport(
    String stayId, {
    String? origin,
    String? luggagePreset,
    int? partySize,
    int? backpacks,
    int? carryOns,
    int? checkedBags,
    int? oversized,
    bool? stroller,
  }) async {
    final payload = <String, dynamic>{
      if (origin != null && origin.isNotEmpty) 'origin': origin,
      if (luggagePreset != null) 'luggage_preset': luggagePreset,
      if (partySize != null) 'party_size': partySize,
      if (backpacks != null) 'backpacks': backpacks,
      if (carryOns != null) 'carry_ons': carryOns,
      if (checkedBags != null) 'checked_bags': checkedBags,
      if (oversized != null) 'oversized': oversized,
      if (stroller != null) 'stroller': stroller,
    };

    final response = await apiClient.post(
      '/stays/$stayId/transport-options',
      data: payload,
    );
    return TransportComparisonResult.fromJson(response as Map<String, dynamic>);
  }
}
