import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../trips/domain/models/trip.dart';
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

  /// High-speed in-memory cache for 0ms instant display without blocking spinners.
  static final Map<String, LoungeSearchResult> _memoryCache = {};

  /// Resets in-memory cache (primarily for tests).
  static void clearMemoryCache() {
    _memoryCache.clear();
  }

  dynamic _extractData(dynamic response) {
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return response['data'];
    }
    return response;
  }

  LoungeSearchResult _applyFilters(
    LoungeSearchResult source, {
    String? terminal,
    bool? isAirside,
    List<String>? accessMethods,
    bool isFromCache = false,
  }) {
    var filtered = source.lounges;

    if (terminal != null && terminal.isNotEmpty) {
      filtered = filtered
          .where((l) => l.terminal?.code.toUpperCase() == terminal.toUpperCase())
          .toList();
    }
    if (isAirside != null) {
      filtered = filtered.where((l) => l.isAirside == isAirside).toList();
    }
    if (accessMethods != null && accessMethods.isNotEmpty) {
      final methodSet = accessMethods.map((m) => m.toLowerCase()).toSet();
      filtered = filtered.where((l) {
        return l.accessMethods.any((m) => methodSet.contains(m.toLowerCase()));
      }).toList();
    }

    return LoungeSearchResult(
      airport: source.airport,
      lounges: filtered,
      isFromCache: isFromCache,
    );
  }

  Future<LoungeSearchResult> _fetchFromNetwork(
    String iata,
    String cacheKey,
  ) async {
    final response = await apiClient.get('/airports/$iata/lounges');
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
  }

  void _refreshInBackground(String iata, String cacheKey) {
    _fetchFromNetwork(iata, cacheKey).then((freshResult) {
      _memoryCache[iata] = freshResult;
    }).catchError((_) {
      // Silently ignore background network errors
    });
  }

  Future<LoungeSearchResult> searchLounges(
    String iata, {
    String? terminal,
    bool? isAirside,
    List<String>? accessMethods,
  }) async {
    final cleanIata = iata.toUpperCase().trim();
    final cacheKey = 'cached_lounges_$cleanIata';

    // 1. Instant hit in in-memory cache (0ms instant return)
    if (_memoryCache.containsKey(cleanIata)) {
      final cached = _memoryCache[cleanIata]!;
      _refreshInBackground(cleanIata, cacheKey);
      return _applyFilters(
        cached,
        terminal: terminal,
        isAirside: isAirside,
        accessMethods: accessMethods,
        isFromCache: true,
      );
    }

    // 2. Fallback to network or disk
    try {
      final result = await _fetchFromNetwork(cleanIata, cacheKey);
      _memoryCache[cleanIata] = result;
      return _applyFilters(
        result,
        terminal: terminal,
        isAirside: isAirside,
        accessMethods: accessMethods,
        isFromCache: false,
      );
    } catch (e) {
      // Offline fallback from local storage
      final cached = await storage.read(key: cacheKey);
      if (cached != null && cached.isNotEmpty) {
        try {
          final data = jsonDecode(cached) as Map<String, dynamic>;
          final airport = Airport.fromJson(
            Map<String, dynamic>.from(data['airport'] as Map),
          );
          final lounges = (data['lounges'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    AirportLounge.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();

          final result = LoungeSearchResult(
            airport: airport,
            lounges: lounges,
            isFromCache: true,
          );
          _memoryCache[cleanIata] = result;

          return _applyFilters(
            result,
            terminal: terminal,
            isAirside: isAirside,
            accessMethods: accessMethods,
            isFromCache: true,
          );
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Proactively pre-fetches and caches airport lounge information for given IATA codes
  /// while the app crawls trip details, itinerary items, or performs background sync.
  Future<void> prefetchAirports(List<String> iataCodes) async {
    final cleanIatas = iataCodes
        .map((c) => c.toUpperCase().trim())
        .where((c) => c.length == 3)
        .toSet();

    await Future.wait(
      cleanIatas.map((iata) async {
        if (_memoryCache.containsKey(iata)) return;
        final cacheKey = 'cached_lounges_$iata';
        try {
          final stored = await storage.read(key: cacheKey);
          if (stored != null && stored.isNotEmpty) {
            final data = jsonDecode(stored) as Map<String, dynamic>;
            final airport = Airport.fromJson(
              Map<String, dynamic>.from(data['airport'] as Map),
            );
            final lounges = (data['lounges'] as List<dynamic>? ?? [])
                .map(
                  (e) => AirportLounge.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList();
            _memoryCache[iata] = LoungeSearchResult(
              airport: airport,
              lounges: lounges,
              isFromCache: true,
            );
            return;
          }
        } catch (_) {}

        try {
          final res = await _fetchFromNetwork(iata, cacheKey);
          _memoryCache[iata] = res;
        } catch (_) {
          // Ignore background prefetch errors
        }
      }),
    );
  }

  /// Helper to detect relevant airport IATA codes from a trip, its destination, and activities.
  static List<String> detectAirportsForTrip(
    Trip? trip, {
    List<String>? additionalTexts,
  }) {
    final Set<String> codes = {};
    final destination = (trip?.destinationCountry ?? trip?.title ?? '')
        .toLowerCase();

    if (destination.contains('japan') ||
        destination.contains('tokyo') ||
        destination.contains('jp')) {
      codes.addAll(['HND', 'NRT', 'KIX']);
    } else if (destination.contains('philippines') ||
        destination.contains('manila') ||
        destination.contains('ph')) {
      codes.addAll(['MNL', 'CEB']);
    } else if (destination.contains('singapore') || destination.contains('sg')) {
      codes.add('SIN');
    } else if (destination.contains('thailand') ||
        destination.contains('bangkok') ||
        destination.contains('th')) {
      codes.addAll(['BKK', 'DMK']);
    } else if (destination.contains('korea') ||
        destination.contains('seoul') ||
        destination.contains('kr')) {
      codes.addAll(['ICN', 'GMP']);
    } else if (destination.contains('united states') ||
        destination.contains('usa') ||
        destination.contains('us')) {
      codes.addAll(['SFO', 'LAX', 'JFK']);
    }

    // Default home origin hub
    codes.add('MNL');

    final regex = RegExp(r'\b([A-Z]{3})\b');
    if (additionalTexts != null) {
      for (final text in additionalTexts) {
        final matches = regex.allMatches(text);
        for (final m in matches) {
          final code = m.group(1);
          if (code != null &&
              [
                'HND',
                'NRT',
                'MNL',
                'SIN',
                'BKK',
                'ICN',
                'KIX',
                'DPS',
                'SFO',
                'LAX',
                'CEB',
                'JFK',
              ].contains(code)) {
            codes.add(code);
          }
        }
      }
    }

    return codes.toList();
  }

  Future<AirportLounge> fetchLoungeDetails(String loungeId) async {
    final response = await apiClient.get('/lounges/$loungeId');
    final data = _extractData(response) as Map<String, dynamic>;
    return AirportLounge.fromJson(data);
  }
}
