class VisitEvent {
  const VisitEvent({
    required this.id,
    required this.itineraryItemId,
    required this.userId,
    required this.eventType,
    this.method = 'manual',
    required this.detectedAt,
    this.accuracyM,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String itineraryItemId;
  final String userId;
  final String eventType; // suggested, confirmed, revoked
  final String method; // manual, geofence
  final DateTime detectedAt;
  final double? accuracyM;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isConfirmed => eventType == 'confirmed';
  bool get isSuggested => eventType == 'suggested';
  bool get isRevoked => eventType == 'revoked';
  bool get isGeofence => method == 'geofence';

  factory VisitEvent.fromJson(Map<String, dynamic> json) {
    return VisitEvent(
      id: json['id'] as String,
      itineraryItemId: json['itinerary_item_id'] as String,
      userId: json['user_id'] as String,
      eventType: json['event_type'] as String,
      method: json['method'] as String? ?? 'manual',
      detectedAt: DateTime.parse(json['detected_at'] as String),
      accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itinerary_item_id': itineraryItemId,
      'user_id': userId,
      'event_type': eventType,
      'method': method,
      'detected_at': detectedAt.toIso8601String(),
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
