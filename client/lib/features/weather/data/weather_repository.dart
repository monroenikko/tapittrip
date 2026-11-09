import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
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
      final data = Map<String, dynamic>.from(response['data'] as Map);
      final weather = TripWeather.fromJson(data);

      // Cache locally for offline access
      await _storage.write(
        key: _cacheKey(tripId),
        value: jsonEncode(weather.toJson()),
      );

      return weather;
    } catch (e) {
      // Try offline cached copy
      final cached = await _storage.read(key: _cacheKey(tripId));
      if (cached != null) {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        return TripWeather.fromJson(decoded);
      }
      rethrow;
    }
  }
}
