class TripReminder {
  const TripReminder({
    required this.id,
    required this.tripId,
    this.itineraryItemId,
    this.checklistId,
    required this.type,
    required this.title,
    required this.body,
    required this.triggerAtUtc,
    required this.timezone,
    this.deliveryChannel = 'local',
    this.status = 'scheduled',
    required this.dedupeKey,
    this.sourceVersion = 1,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String? itineraryItemId;
  final String? checklistId;
  final String type;
  final String title;
  final String body;
  final DateTime triggerAtUtc;
  final String timezone;
  final String deliveryChannel;
  final String status;
  final String dedupeKey;
  final int sourceVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isScheduled => status == 'scheduled';
  bool get isCancelled => status == 'cancelled';
  bool get isDelivered => status == 'delivered';

  factory TripReminder.fromJson(Map<String, dynamic> json) {
    return TripReminder(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      itineraryItemId: json['itinerary_item_id'] as String?,
      checklistId: json['checklist_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      triggerAtUtc: DateTime.parse(json['trigger_at_utc'] as String),
      timezone: json['timezone'] as String? ?? 'UTC',
      deliveryChannel: json['delivery_channel'] as String? ?? 'local',
      status: json['status'] as String? ?? 'scheduled',
      dedupeKey: json['dedupe_key'] as String,
      sourceVersion: json['source_version'] as int? ?? 1,
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
      'trip_id': tripId,
      'itinerary_item_id': itineraryItemId,
      'checklist_id': checklistId,
      'type': type,
      'title': title,
      'body': body,
      'trigger_at_utc': triggerAtUtc.toIso8601String(),
      'timezone': timezone,
      'delivery_channel': deliveryChannel,
      'status': status,
      'dedupe_key': dedupeKey,
      'source_version': sourceVersion,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
