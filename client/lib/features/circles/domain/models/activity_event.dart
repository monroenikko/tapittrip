class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.tripId,
    required this.eventType,
    required this.title,
    this.summary,
    this.entityType,
    this.entityId,
    this.metadata = const {},
    this.occurredAt,
    required this.actorName,
    this.actorAvatarUrl,
  });

  final String id;
  final String tripId;
  final String eventType;
  final String title;
  final String? summary;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic> metadata;
  final DateTime? occurredAt;
  final String actorName;
  final String? actorAvatarUrl;

  String get eventEmoji => switch (eventType) {
    'moment_shared' => '📸',
    'member_joined' => '👋',
    'itinerary_updated' => '🗺️',
    'expense_logged' => '💳',
    _ => '✨',
  };

  List<String> get photos {
    final raw = metadata['photos'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  String? get mood => metadata['mood'] as String?;

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    final rawActor = json['actor'];
    final actorMap = rawActor is Map
        ? Map<String, dynamic>.from(rawActor)
        : const <String, dynamic>{};

    final rawMetadata = json['metadata'];
    final metaMap = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : const <String, dynamic>{};

    return ActivityEvent(
      id: (json['id'] ?? '').toString(),
      tripId: (json['trip_id'] ?? '').toString(),
      eventType: (json['event_type'] ?? 'activity').toString(),
      title: (json['title'] ?? '').toString(),
      summary: json['summary'] as String?,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      metadata: metaMap,
      occurredAt: json['occurred_at'] != null
          ? DateTime.tryParse(json['occurred_at'].toString())
          : null,
      actorName: (actorMap['display_name'] ?? actorMap['name'] ?? 'Traveler')
          .toString(),
      actorAvatarUrl: actorMap['avatar_url'] as String?,
    );
  }
}
