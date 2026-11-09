import 'daily_forecast.dart';
import 'weather_condition.dart';

class TripWeather {
  const TripWeather({
    required this.destination,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.current,
    this.forecast = const [],
    this.providerAttribution = 'Live Weather',
  });

  final String destination;
  final double latitude;
  final double longitude;
  final String timezone;
  final WeatherCondition current;
  final List<DailyForecast> forecast;
  final String providerAttribution;

  factory TripWeather.fromJson(Map<String, dynamic> json) {
    final currentJson = json['current'] as Map<String, dynamic>? ?? {};
    final rawForecast = json['forecast'] as List<dynamic>? ?? [];

    return TripWeather(
      destination: (json['destination'] as String?) ?? 'Destination',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: (json['timezone'] as String?) ?? 'UTC',
      current: WeatherCondition.fromJson(currentJson),
      forecast: rawForecast
          .map((e) => DailyForecast.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      providerAttribution:
          (json['provider_attribution'] as String?) ?? 'Live Weather',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'current': current.toJson(),
      'forecast': forecast.map((e) => e.toJson()).toList(),
      'provider_attribution': providerAttribution,
    };
  }
}

