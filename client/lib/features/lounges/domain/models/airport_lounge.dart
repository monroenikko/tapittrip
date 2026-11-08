import 'airport.dart';
import 'airport_terminal.dart';

class AirportLounge {
  const AirportLounge({
    required this.id,
    required this.airportId,
    required this.terminalId,
    required this.name,
    required this.operatorName,
    required this.locationDescription,
    this.isAirside = true,
    this.openingHours,
    this.amenities = const [],
    this.accessMethods = const [],
    this.estimatedPrice,
    this.bookingUrl,
    this.transitWarning,
    this.disclaimer,
    this.terminal,
    this.airport,
  });

  final String id;
  final String airportId;
  final String terminalId;
  final String name;
  final String operatorName;
  final String locationDescription;
  final bool isAirside;
  final Map<String, dynamic>? openingHours;
  final List<String> amenities;
  final List<String> accessMethods;
  final Map<String, dynamic>? estimatedPrice;
  final String? bookingUrl;
  final String? transitWarning;
  final String? disclaimer;
  final AirportTerminal? terminal;
  final Airport? airport;

  factory AirportLounge.fromJson(Map<String, dynamic> json) {
    return AirportLounge(
      id: json['id'] as String,
      airportId: json['airport_id'] as String,
      terminalId: json['terminal_id'] as String,
      name: json['name'] as String,
      operatorName: (json['operator'] as String?) ?? '',
      locationDescription: (json['location_description'] as String?) ?? '',
      isAirside: (json['is_airside'] as bool?) ?? true,
      openingHours: json['opening_hours'] != null
          ? Map<String, dynamic>.from(json['opening_hours'] as Map)
          : null,
      amenities: (json['amenities'] as List<dynamic>? ?? []).cast<String>(),
      accessMethods: (json['access_methods'] as List<dynamic>? ?? [])
          .cast<String>(),
      estimatedPrice: json['estimated_price'] != null
          ? Map<String, dynamic>.from(json['estimated_price'] as Map)
          : null,
      bookingUrl: json['booking_url'] as String?,
      transitWarning: json['transit_warning'] as String?,
      disclaimer: json['disclaimer'] as String?,
      terminal: json['terminal'] != null
          ? AirportTerminal.fromJson(
              Map<String, dynamic>.from(json['terminal'] as Map),
            )
          : null,
      airport: json['airport'] != null
          ? Airport.fromJson(Map<String, dynamic>.from(json['airport'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'airport_id': airportId,
      'terminal_id': terminalId,
      'name': name,
      'operator': operatorName,
      'location_description': locationDescription,
      'is_airside': isAirside,
      if (openingHours != null) 'opening_hours': openingHours,
      'amenities': amenities,
      'access_methods': accessMethods,
      if (estimatedPrice != null) 'estimated_price': estimatedPrice,
      if (bookingUrl != null) 'booking_url': bookingUrl,
      if (transitWarning != null) 'transit_warning': transitWarning,
      if (disclaimer != null) 'disclaimer': disclaimer,
      if (terminal != null) 'terminal': terminal!.toJson(),
      if (airport != null) 'airport': airport!.toJson(),
    };
  }
}
