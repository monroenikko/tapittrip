import 'package:flutter/material.dart';

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.dayName,
    required this.tempMaxC,
    required this.tempMinC,
    required this.tempMaxF,
    required this.tempMinF,
    required this.condition,
    required this.icon,
    required this.precipitationProbability,
  });

  final String date;
  final String dayName;
  final double tempMaxC;
  final double tempMinC;
  final double tempMaxF;
  final double tempMinF;
  final String condition;
  final String icon;
  final int precipitationProbability;

  String get rangeString => '${tempMinC.round()}° / ${tempMaxC.round()}°C';

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
        return Colors.blue.shade600;
      case 'snow':
        return Colors.cyan.shade600;
      case 'thunderstorm':
        return Colors.deepPurpleAccent;
      default:
        return Colors.amber.shade800;
    }
  }

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: (json['date'] as String?) ?? '',
      dayName: (json['day_name'] as String?) ?? '',
      tempMaxC: (json['temp_max_c'] as num?)?.toDouble() ?? 22.0,
      tempMinC: (json['temp_min_c'] as num?)?.toDouble() ?? 15.0,
      tempMaxF: (json['temp_max_f'] as num?)?.toDouble() ?? 72.0,
      tempMinF: (json['temp_min_f'] as num?)?.toDouble() ?? 59.0,
      condition: (json['condition'] as String?) ?? 'Partly Cloudy',
      icon: (json['icon'] as String?) ?? 'partly_cloudy',
      precipitationProbability:
          (json['precipitation_probability'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day_name': dayName,
      'temp_max_c': tempMaxC,
      'temp_min_c': tempMinC,
      'temp_max_f': tempMaxF,
      'temp_min_f': tempMinF,
      'condition': condition,
      'icon': icon,
      'precipitation_probability': precipitationProbability,
    };
  }
}
