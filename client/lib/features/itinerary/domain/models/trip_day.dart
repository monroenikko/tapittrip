class TripDay {
  const TripDay({
    required this.id,
    required this.tripId,
    required this.localDate,
    this.notes,
  });

  final String id;
  final String tripId;
  final String localDate;
  final String? notes;

  factory TripDay.fromJson(Map<String, dynamic> json) {
    return TripDay(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      localDate: json['local_date'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'local_date': localDate,
      if (notes != null) 'notes': notes,
    };
  }
}
