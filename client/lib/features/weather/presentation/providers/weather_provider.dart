import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/weather_repository.dart';
import '../../domain/models/trip_weather.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WeatherRepository(apiClient: apiClient);
});

final tripWeatherProvider =
    FutureProvider.family<TripWeather, String>((ref, tripId) async {
  final repo = ref.watch(weatherRepositoryProvider);
  return repo.fetchTripWeather(tripId);
});

