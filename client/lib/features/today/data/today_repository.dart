import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../domain/models/today_dashboard_summary.dart';

class TodayRepository {
  TodayRepository({required this.apiClient, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  String _cacheKey(String tripId) => 'cached_today_$tripId';

  /// Fetch today's dashboard summary with offline cache fallback.
  Future<TodayDashboardSummary> fetchTodaySummary(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/today');

      if (response is Map<String, dynamic>) {
        await _storage.write(
          key: _cacheKey(tripId),
          value: jsonEncode(response),
        );
        return TodayDashboardSummary.fromJson(response);
      }
      throw const ApiException(
        code: 'invalid_response',
        message: 'Invalid today summary response from server.',
      );
    } on ApiException {
      final cached = await _storage.read(key: _cacheKey(tripId));
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        return TodayDashboardSummary.fromJson(data);
      }
      rethrow;
    } catch (_) {
      final cached = await _storage.read(key: _cacheKey(tripId));
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        return TodayDashboardSummary.fromJson(data);
      }
      rethrow;
    }
  }
}

