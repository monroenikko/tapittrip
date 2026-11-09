import 'package:flutter/material.dart';

class WeatherCondition {
  const WeatherCondition({
    required this.temperatureC,
    required this.temperatureF,
    this.feelsLikeC,
    this.feelsLikeF,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windKph,
    required this.precipitationProbability,
    required this.advisory,
  });

  final double temperatureC;
  final double temperatureF;
  final double? feelsLikeC;
  final double? feelsLikeF;
  final String condition;
  final String icon;
  final int humidity;
  final double windKph;
  final int precipitationProbability;
  final String advisory;

  String get tempString => '${temperatureC.round()}°C';
  String get tempDualString => '${temperatureC.round()}°C (${temperatureF.round()}°F)';

  IconData get weatherIcon {
    switch (icon.toLowerCase()) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'partly_cloudy':
        return Icons.cloud_queue_rounded;
      case 'cloudy':
        return Icons.cloud_rounded;
      case 'fog':
        return Icons.foggy;
      case 'rain':
        return Icons.water_drop_outlined;
      case 'heavy_rain':
        return Icons.grain_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  Color get weatherColor {
    switch (icon.toLowerCase()) {
      case 'sunny':
        return Colors.orangeAccent.shade700;
      case 'partly_cloudy':
        return Colors.amber.shade700;
      case 'cloudy':
      case 'fog':
        return Colors.blueGrey;
      case 'rain':
      case 'heavy_rain':
        return Colors.blue;
      case 'snow':
        return Colors.lightBlue.shade300;
      case 'thunderstorm':
        return Colors.deepPurple;
      default:
        return Colors.orange;
    }
  }

  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    return WeatherCondition(
      temperatureC: (json['temperature_c'] as num?)?.toDouble() ?? 20.0,
      temperatureF: (json['temperature_f'] as num?)?.toDouble() ?? 68.0,
      feelsLikeC: (json['feels_like_c'] as num?)?.toDouble(),
      feelsLikeF: (json['feels_like_f'] as num?)?.toDouble(),
      condition: (json['condition'] as String?) ?? 'Partly Cloudy',
      icon: (json['icon'] as String?) ?? 'partly_cloudy',
      humidity: (json['humidity'] as num?)?.toInt() ?? 50,
      windKph: (json['wind_kph'] as num?)?.toDouble() ?? 10.0,
      precipitationProbability:
          (json['precipitation_probability'] as num?)?.toInt() ?? 10,
      advisory: (json['advisory'] as String?) ??
          'Comfortable weather for traveling.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature_c': temperatureC,
      'temperature_f': temperatureF,
      if (feelsLikeC != null) 'feels_like_c': feelsLikeC,
      if (feelsLikeF != null) 'feels_like_f': feelsLikeF,
      'condition': condition,
      'icon': icon,
      'humidity': humidity,
      'wind_kph': windKph,
      'precipitation_probability': precipitationProbability,
      'advisory': advisory,
    };
  }
}

