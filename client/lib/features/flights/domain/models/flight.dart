class Flight {
  const Flight({
    required this.id,
    required this.tripId,
    required this.segments,
    this.airline,
    this.bookingReference,
    this.version = 1,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String? airline;
  final String? bookingReference;
  final List<FlightSegment> segments;
  final int version;
  final DateTime? updatedAt;

  Flight copyWith({
    String? airline,
    String? bookingReference,
    List<FlightSegment>? segments,
    int? version,
    DateTime? updatedAt,
  }) => Flight(
    id: id,
    tripId: tripId,
    airline: airline ?? this.airline,
    bookingReference: bookingReference ?? this.bookingReference,
    segments: segments ?? this.segments,
    version: version ?? this.version,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'trip_id': tripId,
    'airline': airline,
    'booking_reference': bookingReference,
    'segments': segments.map((segment) => segment.toJson()).toList(),
    'version': version,
    'updated_at': updatedAt?.toUtc().toIso8601String(),
  };

  factory Flight.fromJson(Map<String, dynamic> json) => Flight(
    id: json['id'] as String,
    tripId: json['trip_id'] as String,
    airline: json['airline'] as String?,
    bookingReference: json['booking_reference'] as String?,
    segments: ((json['segments'] as List?) ?? const [])
        .map(
          (item) =>
              FlightSegment.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    version: (json['version'] as num?)?.toInt() ?? 1,
    updatedAt: json['updated_at'] == null
        ? null
        : DateTime.tryParse(json['updated_at'] as String),
  );
}

class FlightSegment {
  const FlightSegment({
    required this.id,
    required this.flightNumber,
    required this.originAirport,
    required this.destinationAirport,
    required this.scheduledDepartureUtc,
    required this.scheduledArrivalUtc,
    required this.originTimezone,
    required this.destinationTimezone,
    this.terminal,
    this.gate,
  });

  final String? id;
  final String flightNumber;
  final String originAirport;
  final String destinationAirport;
  final DateTime scheduledDepartureUtc;
  final DateTime scheduledArrivalUtc;
  final String originTimezone;
  final String destinationTimezone;
  final String? terminal;
  final String? gate;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'flight_number': flightNumber,
    'origin_airport': originAirport,
    'destination_airport': destinationAirport,
    'scheduled_departure_utc': scheduledDepartureUtc.toUtc().toIso8601String(),
    'scheduled_arrival_utc': scheduledArrivalUtc.toUtc().toIso8601String(),
    'origin_timezone': originTimezone,
    'destination_timezone': destinationTimezone,
    if (terminal != null) 'terminal': terminal,
    if (gate != null) 'gate': gate,
  };

  factory FlightSegment.fromJson(Map<String, dynamic> json) => FlightSegment(
    id: json['id'] as String?,
    flightNumber: json['flight_number'] as String,
    originAirport: json['origin_airport'] as String,
    destinationAirport: json['destination_airport'] as String,
    scheduledDepartureUtc: DateTime.parse(
      json['scheduled_departure_utc'] as String,
    ).toUtc(),
    scheduledArrivalUtc: DateTime.parse(json['scheduled_arrival_utc'] as String)
        .toUtc(),
    originTimezone: json['origin_timezone'] as String,
    destinationTimezone: json['destination_timezone'] as String,
    terminal: json['terminal'] as String?,
    gate: json['gate'] as String?,
  );
}
