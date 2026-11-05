import 'planning_mode.dart';

class Trip {
  const Trip({
    required this.id,
    required this.ownerId,
    required this.title,
    this.startDate,
    this.endDate,
    this.primaryTimezone = 'UTC',
    this.originCountry,
    this.destinationCountry,
    this.tripType = 'leisure',
    this.planningMode = PlanningMode.diy,
    this.status = 'planned',
    this.version = 1,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String? startDate;
  final String? endDate;
  final String primaryTimezone;
  final String? originCountry;
  final String? destinationCountry;
  final String tripType;
  final PlanningMode planningMode;
  final String status;
  final int version;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get dateRangeFormatted {
    if (startDate == null) return null;
    if (endDate == null) return startDate;
    return '$startDate – $endDate';
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      ownerId: (json['owner_id'] as String?) ?? '',
      title: json['title'] as String,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      primaryTimezone: (json['primary_timezone'] as String?) ?? 'UTC',
      originCountry: json['origin_country'] as String?,
      destinationCountry: json['destination_country'] as String?,
      tripType: (json['trip_type'] as String?) ?? 'leisure',
      planningMode: PlanningMode.fromString(json['planning_mode'] as String?),
      status: (json['status'] as String?) ?? 'planned',
      version: (json['version'] as int?) ?? 1,
      role: json['role'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'title': title,
    'start_date': startDate,
    'end_date': endDate,
    'primary_timezone': primaryTimezone,
    'origin_country': originCountry,
    'destination_country': destinationCountry,
    'trip_type': tripType,
    'planning_mode': planningMode.value,
    'status': status,
    'version': version,
    'role': role,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
