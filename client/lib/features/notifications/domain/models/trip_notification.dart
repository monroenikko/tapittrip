class UserNotification {
  const UserNotification({
    required this.id,
    required this.tripId,
    required this.tripTitle,
    required this.category,
    required this.title,
    required this.body,
    required this.timezone,
    required this.status,
    required this.isRead,
    this.announcementId,
    this.scheduledForUtc,
    this.tripLocalTimeLabel,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String tripId;
  final String tripTitle;
  final String? announcementId;
  final String category;
  final String title;
  final String body;
  final DateTime? scheduledForUtc;
  final String timezone;
  final String? tripLocalTimeLabel;
  final String status;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isSuppressedQuietHours => status == 'suppressed_quiet_hours';

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      tripTitle: json['trip_title'] as String? ?? 'Shared Trip',
      announcementId: json['announcement_id'] as String?,
      category: json['category'] as String? ?? 'circle_announcement',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      scheduledForUtc: json['scheduled_for_utc'] != null
          ? DateTime.tryParse(json['scheduled_for_utc'] as String)
          : null,
      timezone: json['timezone'] as String? ?? 'UTC',
      tripLocalTimeLabel: json['trip_local_time_label'] as String?,
      status: json['status'] as String? ?? 'pending',
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'trip_title': tripTitle,
      'announcement_id': announcementId,
      'category': category,
      'title': title,
      'body': body,
      'scheduled_for_utc': scheduledForUtc?.toIso8601String(),
      'timezone': timezone,
      'trip_local_time_label': tripLocalTimeLabel,
      'status': status,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
