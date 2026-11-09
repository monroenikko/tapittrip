import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/airport.dart';
import '../domain/models/airport_lounge.dart';

class LoungeSearchResult {
  const LoungeSearchResult({
    required this.airport,
    required this.lounges,
    this.isFromCache = false,
  });

  final Airport airport;
  final List<AirportLounge> lounges;
  final bool isFromCache;
}

class LoungeRepository {
  LoungeRepository({
    required this.apiClient,
    this.storage = const FlutterSecureStorage(),
  });

  final ApiClient apiClient;
  final FlutterSecureStorage storage;

  dynamic _extractData(dynamic response) {
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return response['data'];
    }
    return response;
  }

  Future<LoungeSearchResult> searchLounges(
    String iata, {
    String? terminal,
    bool? isAirside,
    List<String>? accessMethods,
  }) async {
    final cacheKey = 'cached_lounges_${iata.toUpperCase()}';

    try {
      final queryParams = <String, dynamic>{};
      if (terminal != null && terminal.isNotEmpty) {
        queryParams['terminal'] = terminal;
      }
      if (isAirside != null) {
        queryParams['is_airside'] = isAirside;
      }
      if (accessMethods != null && accessMethods.isNotEmpty) {
        queryParams['access_methods'] = accessMethods;
      }

      final response = await apiClient.get(
        '/airports/${iata.toUpperCase()}/lounges',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = _extractData(response) as Map<String, dynamic>;

      // Cache raw payload for offline access
      await storage.write(key: cacheKey, value: jsonEncode(data));

      final airport = Airport.fromJson(
        Map<String, dynamic>.from(data['airport'] as Map),
      );
      final lounges = (data['lounges'] as List<dynamic>? ?? [])
          .map(
            (e) => AirportLounge.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      return LoungeSearchResult(airport: airport, lounges: lounges);
    } catch (e) {
      // Offline fallback
      final cached = await storage.read(key: cacheKey);
      if (cached != null && cached.isNotEmpty) {
        try {
          final data = jsonDecode(cached) as Map<String, dynamic>;
          final airport = Airport.fromJson(
            Map<String, dynamic>.from(data['airport'] as Map),
          );
          var lounges = (data['lounges'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    AirportLounge.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();

          if (terminal != null && terminal.isNotEmpty) {
            lounges = lounges
                .where((l) => l.terminal?.code == terminal)
                .toList();
          }
          if (isAirside != null) {
            lounges = lounges.where((l) => l.isAirside == isAirside).toList();
          }

          return LoungeSearchResult(
            airport: airport,
            lounges: lounges,
            isFromCache: true,
          );
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<AirportLounge> fetchLoungeDetails(String loungeId) async {
    final response = await apiClient.get('/lounges/$loungeId');
    final data = _extractData(response) as Map<String, dynamic>;
    return AirportLounge.fromJson(data);
  }
}
