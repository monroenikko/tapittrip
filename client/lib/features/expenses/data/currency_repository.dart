import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';

class CurrencyRateUnavailableException extends ApiException {
  const CurrencyRateUnavailableException({required this.from, required this.to})
    : super(
        code: 'exchange_rate_unavailable',
        message: 'Exchange rate unavailable for $from to $to.',
        statusCode: 503,
      );

  final String from;
  final String to;
}

class CurrencyRateDetails {
  const CurrencyRateDetails({
    required this.from,
    required this.to,
    required this.rate,
    required this.reciprocalRate,
    required this.asOf,
    required this.provider,
    this.isOffline = false,
    this.isUnavailable = false,
  });

  final String from;
  final String to;
  final double rate;
  final double reciprocalRate;
  final String asOf;
  final String provider;
  final bool isOffline;
  final bool isUnavailable;

  bool get isAvailable => !isUnavailable && rate > 0;

  factory CurrencyRateDetails.unavailable({
    required String from,
    required String to,
  }) {
    return CurrencyRateDetails(
      from: from,
      to: to,
      rate: 0.0,
      reciprocalRate: 0.0,
      asOf: '',
      provider: 'unavailable',
      isOffline: true,
      isUnavailable: true,
    );
  }

  factory CurrencyRateDetails.fromJson(
    Map<String, dynamic> json, {
    bool isOffline = false,
  }) {
    final parsedRate = (json['rate'] as num?)?.toDouble();
    final availableFlag = json['available'] as bool? ?? true;
    final unavailable = !availableFlag || parsedRate == null || parsedRate <= 0;

    return CurrencyRateDetails(
      from: json['from'] as String? ?? 'USD',
      to: json['to'] as String? ?? 'PHP',
      rate: parsedRate ?? 0.0,
      reciprocalRate: (json['reciprocal_rate'] as num?)?.toDouble() ?? 0.0,
      asOf: json['as_of'] as String? ?? DateTime.now().toIso8601String(),
      provider:
          json['provider'] as String? ??
          (unavailable ? 'unavailable' : 'cache'),
      isOffline: isOffline,
      isUnavailable: unavailable,
    );
  }

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'rate': rate,
    'reciprocal_rate': reciprocalRate,
    'as_of': asOf,
    'provider': provider,
    'available': !isUnavailable,
  };
}

class CurrencyRepository {
  CurrencyRepository({
    required this.apiClient,
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _secureStorage;

  /// Fetch an attributed exchange-rate snapshot from the API or encrypted cache.
  /// Never invents offline rates when neither network nor a prior snapshot exists.
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
        asOf: DateTime.now().toUtc().toIso8601String(),
        provider: 'identity',
      );
    }

    final cacheKey = 'cached_forex_${from}_$to';

    try {
      final response = await apiClient.get(
        '/currencies/rates',
        queryParameters: {'from': from, 'to': to},
      );

      final rawMap = response is Map && response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : Map<String, dynamic>.from(response as Map);
      final details = CurrencyRateDetails.fromJson(rawMap);
      if (details.isUnavailable) {
        throw CurrencyRateUnavailableException(from: from, to: to);
      }

      await _secureStorage.write(
        key: cacheKey,
        value: jsonEncode(details.toJson()),
      );

      return details;
    } catch (_) {
      try {
        final cachedJson = await _secureStorage.read(key: cacheKey);
        if (cachedJson != null && cachedJson.isNotEmpty) {
          final data = jsonDecode(cachedJson) as Map<String, dynamic>;
          final cachedDetails = CurrencyRateDetails.fromJson(
            data,
            isOffline: true,
          );
          if (cachedDetails.isAvailable) {
            return cachedDetails;
          }
        }
      } catch (_) {}

      throw CurrencyRateUnavailableException(from: from, to: to);
    }
  }

  /// Non-throwing variant returning an explicit unavailable snapshot for expense entry UI.
  Future<CurrencyRateDetails> tryGetRateDetails(
    String fromCurrency,
    String toCurrency,
  ) async {
    try {
      return await getRateDetails(fromCurrency, toCurrency);
    } catch (_) {
      return CurrencyRateDetails.unavailable(
        from: fromCurrency.toUpperCase().trim(),
        to: toCurrency.toUpperCase().trim(),
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
