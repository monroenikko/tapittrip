import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';

class CurrencyRateDetails {
  const CurrencyRateDetails({
    required this.from,
    required this.to,
    required this.rate,
    required this.reciprocalRate,
    required this.asOf,
    required this.provider,
    this.isOffline = false,
  });

  final String from;
  final String to;
  final double rate;
  final double reciprocalRate;
  final String asOf;
  final String provider;
  final bool isOffline;

  factory CurrencyRateDetails.fromJson(
    Map<String, dynamic> json, {
    bool isOffline = false,
  }) {
    return CurrencyRateDetails(
      from: json['from'] as String? ?? 'USD',
      to: json['to'] as String? ?? 'PHP',
      rate: (json['rate'] as num?)?.toDouble() ?? 1.0,
      reciprocalRate: (json['reciprocal_rate'] as num?)?.toDouble() ?? 1.0,
      asOf: json['as_of'] as String? ?? DateTime.now().toIso8601String(),
      provider: json['provider'] as String? ?? 'cache',
      isOffline: isOffline,
    );
  }

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'rate': rate,
    'reciprocal_rate': reciprocalRate,
    'as_of': asOf,
    'provider': provider,
  };
}

class CurrencyRepository {
  CurrencyRepository({
    required this.apiClient,
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _secureStorage;

  // Fallback exchange rate matrix against USD for offline resilience
  static const Map<String, double> _fallbackToUsd = {
    'USD': 1.0,
    'PHP': 58.50,
    'JPY': 154.00,
    'EUR': 0.92,
    'GBP': 0.78,
    'SGD': 1.33,
    'AUD': 1.52,
    'THB': 34.20,
    'KRW': 1380.0,
    'CAD': 1.39,
    'HKD': 7.78,
    'TWD': 32.10,
    'IDR': 15700.0,
    'MYR': 4.40,
    'AED': 3.67,
    'CHF': 0.88,
  };

  Future<CurrencyRateDetails> getRateDetails(
    String fromCurrency,
    String toCurrency,
  ) async {
    final from = fromCurrency.toUpperCase().trim();
    final to = toCurrency.toUpperCase().trim();

    if (from == to) {
      return CurrencyRateDetails(
        from: from,
        to: to,
        rate: 1.0,
        reciprocalRate: 1.0,
        asOf: DateTime.now().toIso8601String(),
        provider: 'identity',
      );
    }

    final cacheKey = 'cached_forex_${from}_$to';

    try {
      final response = await apiClient.get(
        '/currencies/rates',
        queryParameters: {'from': from, 'to': to},
      );

      final data = response as Map<String, dynamic>;
      final details = CurrencyRateDetails.fromJson(data);

      // Save to encrypted storage for offline access
      await _secureStorage.write(
        key: cacheKey,
        value: jsonEncode(details.toJson()),
      );

      return details;
    } catch (_) {
      // Try to read from local encrypted cache
      try {
        final cachedJson = await _secureStorage.read(key: cacheKey);
        if (cachedJson != null) {
          final data = jsonDecode(cachedJson) as Map<String, dynamic>;
          return CurrencyRateDetails.fromJson(data, isOffline: true);
        }
      } catch (_) {}

      // Fallback to built-in snapshot rates
      final fromRate = _fallbackToUsd[from] ?? 1.0;
      final toRate = _fallbackToUsd[to] ?? 1.0;
      final rate = from == 'JPY' && to == 'PHP' ? 0.3800 : (toRate / fromRate);
      final reciprocal = rate > 0 ? (1.0 / rate) : 1.0;

      return CurrencyRateDetails(
        from: from,
        to: to,
        rate: rate,
        reciprocalRate: reciprocal,
        asOf: DateTime.now().toIso8601String(),
        provider: 'offline_snapshot',
        isOffline: true,
      );
    }
  }

  Future<double> getRate(String fromCurrency, String toCurrency) async {
    final details = await getRateDetails(fromCurrency, toCurrency);
    return details.rate;
  }
}

final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CurrencyRepository(apiClient: apiClient);
});

final currencyRateProvider =
    FutureProvider.family<CurrencyRateDetails, ({String from, String to})>((
      ref,
      pair,
    ) async {
      final repository = ref.watch(currencyRepositoryProvider);
      return repository.getRateDetails(pair.from, pair.to);
    });
