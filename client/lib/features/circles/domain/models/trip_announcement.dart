class TripAnnouncement {
  const TripAnnouncement({
    required this.id,
    required this.tripId,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.body,
    required this.isPinned,
    required this.version,
    this.clientOperationId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String authorId;
  final String authorName;
  final String title;
  final String body;
  final bool isPinned;
  final String? clientOperationId;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TripAnnouncement.fromJson(Map<String, dynamic> json) {
    return TripAnnouncement(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      authorId: json['author_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Organizer',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isPinned: json['is_pinned'] as bool? ?? false,
      clientOperationId: json['client_operation_id'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
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
      'author_id': authorId,
      'author_name': authorName,
      'title': title,
      'body': body,
      'is_pinned': isPinned,
      'client_operation_id': clientOperationId,
      'version': version,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
