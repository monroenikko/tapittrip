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
    this.isOfflineSynced = false,
  });

  final String destination;
  final double latitude;
  final double longitude;
  final String timezone;
  final WeatherCondition current;
  final List<DailyForecast> forecast;
  final String providerAttribution;
  final bool isOfflineSynced;

  TripWeather copyWith({
    String? destination,
    double? latitude,
    double? longitude,
    String? timezone,
    WeatherCondition? current,
    List<DailyForecast>? forecast,
    String? providerAttribution,
    bool? isOfflineSynced,
  }) {
    return TripWeather(
      destination: destination ?? this.destination,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      current: current ?? this.current,
      forecast: forecast ?? this.forecast,
      providerAttribution: providerAttribution ?? this.providerAttribution,
      isOfflineSynced: isOfflineSynced ?? this.isOfflineSynced,
    );
  }

  factory TripWeather.fromJson(Map<String, dynamic> json) {
    final rawCurrent = json['current'];
    final currentJson = rawCurrent is Map
        ? Map<String, dynamic>.from(rawCurrent)
        : <String, dynamic>{};
    final rawForecast = json['forecast'] as List<dynamic>? ?? [];

    return TripWeather(
      destination: (json['destination'] as String?) ?? 'Destination',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: (json['timezone'] as String?) ?? 'UTC',
      current: WeatherCondition.fromJson(currentJson),
      forecast: rawForecast
          .whereType<Map>()
          .map((e) => DailyForecast.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      providerAttribution:
          (json['provider_attribution'] as String?) ?? 'Live Weather',
      isOfflineSynced: (json['is_offline_synced'] as bool?) ?? false,
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
      'is_offline_synced': isOfflineSynced,
    };
  }
}
