import 'airport_terminal.dart';

class Airport {
  const Airport({
    required this.id,
    required this.iataCode,
    required this.name,
    required this.city,
    required this.country,
    this.latitude,
    this.longitude,
    required this.timezone,
    this.terminals = const [],
  });

  final String id;
  final String iataCode;
  final String name;
  final String city;
  final String country;
  final double? latitude;
  final double? longitude;
  final String timezone;
  final List<AirportTerminal> terminals;

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      id: json['id'] as String,
      iataCode: json['iata_code'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      timezone: json['timezone'] as String? ?? 'UTC',
      terminals: (json['terminals'] as List<dynamic>? ?? [])
          .map(
            (e) =>
                AirportTerminal.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iata_code': iataCode,
      'name': name,
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'terminals': terminals.map((e) => e.toJson()).toList(),
    };
  }
}
