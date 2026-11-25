class TripLocationShare {
  const TripLocationShare({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.userName,
    required this.enabled,
    required this.isActive,
    required this.isStale,
    required this.durationMinutes,
    this.expiresAt,
    this.audience = 'circle',
    this.latitude,
    this.longitude,
    this.lastSharedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String userId;
  final String userName;
  final bool enabled;
  final bool isActive;
  final bool isStale;
  final int durationMinutes;
  final DateTime? expiresAt;
  final String audience;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSharedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TripLocationShare.fromJson(Map<String, dynamic> json) {
    return TripLocationShare(
      id: json['id'] as String? ?? '',
      tripId: json['trip_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? 'Traveler',
      enabled: json['enabled'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
      isStale: json['is_stale'] as bool? ?? true,
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)?.toLocal()
          : null,
      audience: json['audience'] as String? ?? 'circle',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastSharedAt: json['last_shared_at'] != null
          ? DateTime.tryParse(json['last_shared_at'] as String)?.toLocal()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'user_id': userId,
      'user_name': userName,
      'enabled': enabled,
      'is_active': isActive,
      'is_stale': isStale,
      'duration_minutes': durationMinutes,
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'audience': audience,
      'latitude': latitude,
      'longitude': longitude,
      'last_shared_at': lastSharedAt?.toUtc().toIso8601String(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }

  TripLocationShare copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? userName,
    bool? enabled,
    bool? isActive,
    bool? isStale,
    int? durationMinutes,
    DateTime? expiresAt,
    String? audience,
    double? latitude,
    double? longitude,
    DateTime? lastSharedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripLocationShare(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      enabled: enabled ?? this.enabled,
      isActive: isActive ?? this.isActive,
      isStale: isStale ?? this.isStale,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      expiresAt: expiresAt ?? this.expiresAt,
      audience: audience ?? this.audience,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastSharedAt: lastSharedAt ?? this.lastSharedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
