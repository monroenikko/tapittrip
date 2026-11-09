import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../domain/models/trip_weather.dart';

class WeatherRepository {
  WeatherRepository({
    required this.apiClient,
    FlutterSecureStorage? storage,
  })  : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  String _cacheKey(String tripId) => 'cached_weather_$tripId';

  Future<TripWeather> fetchTripWeather(String tripId) async {
    try {
      final response = await apiClient.get('/trips/$tripId/weather');
      final Map<String, dynamic> data;
      if (response is Map) {
        if (response.containsKey('data') && response['data'] is Map) {
          data = Map<String, dynamic>.from(response['data'] as Map);
        } else {
          data = Map<String, dynamic>.from(response);
        }
      } else {
        throw ApiException(
          code: 'invalid_response',
          message: 'Invalid weather response format received from server.',
        );
      }
      final weather = TripWeather.fromJson(data);

      // Cache locally for offline access
      await _storage.write(
        key: _cacheKey(tripId),
        value: jsonEncode(weather.toJson()),
      );

      return weather;
    } catch (e) {
      // Return last synced copy if available while offline
      final cached = await _storage.read(key: _cacheKey(tripId));
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached);
          if (decoded is Map) {
            final weather = TripWeather.fromJson(Map<String, dynamic>.from(decoded));
            return weather.copyWith(isOfflineSynced: true);
          }
        } catch (_) {
          // Ignore cache decoding error and rethrow original error
        }
      }
      rethrow;
    }
  }
}
