import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../circles/data/trip_circle_repository.dart';
import '../domain/models/flight.dart';

class FlightRepository {
  FlightRepository({
    required ApiClient apiClient,
    FlutterSecureStorage? storage,
  }) : _api = apiClient,
       _storage = storage ?? const FlutterSecureStorage();

  final ApiClient _api;
  final FlutterSecureStorage _storage;
  String _cacheKey(String tripId) => 'cached_flights_$tripId';

  Future<List<Flight>> fetch(String tripId) async {
    try {
      final response = await _api.get('/trips/$tripId/flights');
      final raw = response is Map ? response['data'] : response;
      final items = List<dynamic>.from(raw as List);
      await _storage.write(key: _cacheKey(tripId), value: jsonEncode(items));
      return _decode(items);
    } on ApiException catch (error) {
      if (error.statusCode == 403 || error.code == 'forbidden') {
        await TripCircleRepository.purgeAllTripCachesForStorage(
          storage: _storage,
          tripId: tripId,
        );
        rethrow;
      }
      return _cachedOrThrow(tripId, error);
    } catch (error) {
      return _cachedOrThrow(tripId, error);
    }
  }

  Future<Flight> create(String tripId, Map<String, dynamic> payload) async =>
      Flight.fromJson(
        _dataMap(await _api.post('/trips/$tripId/flights', data: payload)),
      );

  Future<Flight> update(String flightId, Map<String, dynamic> payload) async =>
      Flight.fromJson(
        _dataMap(await _api.patch('/flights/$flightId', data: payload)),
      );

  Future<void> delete(String flightId) => _api.delete('/flights/$flightId');

  Future<void> cache(String tripId, List<Flight> flights) => _storage.write(
    key: _cacheKey(tripId),
    value: jsonEncode(flights.map((flight) => flight.toJson()).toList()),
  );

  Future<void> applyPulledOperations(
    List<Map<String, dynamic>> operations,
  ) async {
    final flightOps = operations.where(
      (op) => op['entity_type'] == 'flight' && op['trip_id'] is String,
    );
    if (flightOps.isEmpty) return;

    final byTrip = <String, List<Map<String, dynamic>>>{};
    for (final op in flightOps) {
      final tripId = op['trip_id'] as String;
      byTrip.putIfAbsent(tripId, () => []).add(op);
    }

    for (final entry in byTrip.entries) {
      final tripId = entry.key;
      final rawCached = await _storage.read(key: _cacheKey(tripId));
      final current = rawCached == null
          ? <Flight>[]
          : _decode(List<dynamic>.from(jsonDecode(rawCached) as List));
      final byId = <String, Flight>{
        for (final flight in current) flight.id: flight,
      };

      for (final op in entry.value) {
        final entityId = op['entity_id'] as String?;
        if (entityId == null || entityId.isEmpty) continue;
        final opType = op['operation_type'] as String? ?? '';

        if (opType == 'delete') {
          byId.remove(entityId);
          continue;
        }

        if (opType == 'create' || opType == 'update') {
          final payload = op['payload'] is Map
              ? Map<String, dynamic>.from(op['payload'] as Map)
              : const <String, dynamic>{};
          final existing = byId[entityId];
          final rawSegments = payload['segments'];
          final segments = rawSegments is List
              ? rawSegments
                    .map(
                      (s) => FlightSegment.fromJson(
                        Map<String, dynamic>.from(s as Map),
                      ),
                    )
                    .toList()
              : (existing?.segments ?? const <FlightSegment>[]);
          final baseVersion =
              (op['base_version'] as num?)?.toInt() ?? existing?.version ?? 1;
          final nextVersion =
              (payload['version'] as num?)?.toInt() ??
              (opType == 'update' ? baseVersion + 1 : baseVersion);

          byId[entityId] = Flight(
            id: entityId,
            tripId: tripId,
            airline: payload.containsKey('airline')
                ? payload['airline'] as String?
                : existing?.airline,
            bookingReference:
                payload['booking_reference'] as String? ??
                existing?.bookingReference,
            segments: segments,
            version: nextVersion,
            updatedAt: op['created_at'] is String
                ? DateTime.tryParse(op['created_at'] as String)
                : existing?.updatedAt,
          );
        }
      }

      await cache(tripId, byId.values.toList());
    }
  }

  Future<List<Flight>> _cachedOrThrow(String tripId, Object error) async {
    final cached = await _storage.read(key: _cacheKey(tripId));
    if (cached == null) throw error;
    return _decode(List<dynamic>.from(jsonDecode(cached) as List));
  }

  List<Flight> _decode(List<dynamic> raw) => raw
      .map((item) => Flight.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();

  Map<String, dynamic> _dataMap(dynamic response) => Map<String, dynamic>.from(
    response is Map && response['data'] is Map
        ? response['data'] as Map
        : response as Map,
  );
}
