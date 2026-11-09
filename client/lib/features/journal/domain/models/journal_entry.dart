import 'package:flutter/material.dart';

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.tripId,
    required this.userId,
    this.authorName = 'Traveler',
    this.authorAvatarUrl,
    this.itineraryItemId,
    required this.title,
    required this.content,
    required this.entryDate,
    this.locationName,
    this.weather,
    this.mood,
    this.isShared = false,
    this.isAuthor = true,
    this.photos = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tripId;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String? itineraryItemId;
  final String title;
  final String content;
  final String entryDate;
  final String? locationName;
  final String? weather;
  final String? mood;
  final bool isShared;
  final bool isAuthor;
  final List<String> photos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get moodEmoji {
    switch (mood?.toLowerCase()) {
      case 'amazed':
        return '🤩';
      case 'happy':
        return '😊';
      case 'peaceful':
        return '😌';
      case 'excited':
        return '🎉';
      case 'tired':
        return '😴';
      case 'grateful':
        return '🙏';
      case 'adventurous':
        return '🏔️';
      default:
        return '✨';
    }
  }

  String get moodLabel {
    if (mood == null || mood!.isEmpty) return '';
    return mood![0].toUpperCase() + mood!.substring(1);
  }

  IconData get weatherIcon {
    switch (weather?.toLowerCase()) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'cloudy':
        return Icons.wb_cloudy_rounded;
      case 'rainy':
        return Icons.grain_rounded;
      case 'snowy':
        return Icons.ac_unit_rounded;
      case 'windy':
        return Icons.air_rounded;
      default:
        return Icons.cloud_outlined;
    }
  }

  String get privacyLabel => isShared ? 'Shared with Circle' : 'Only You';

  IconData get privacyIcon =>
      isShared ? Icons.group_rounded : Icons.lock_outline_rounded;

  Color get privacyColor => isShared ? Colors.teal : Colors.amber.shade800;

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      userId: (json['user_id'] as String?) ?? '',
      authorName: (json['author_name'] as String?) ?? 'Traveler',
      authorAvatarUrl: json['author_avatar_url'] as String?,
      itineraryItemId: json['itinerary_item_id'] as String?,
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      entryDate: (json['entry_date'] as String?) ?? '',
      locationName: json['location_name'] as String?,
      weather: json['weather'] as String?,
      mood: json['mood'] as String?,
      isShared: (json['is_shared'] as bool?) ?? false,
      isAuthor: (json['is_author'] as bool?) ?? true,
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
      'user_id': userId,
      'author_name': authorName,
      if (authorAvatarUrl != null) 'author_avatar_url': authorAvatarUrl,
      if (itineraryItemId != null) 'itinerary_item_id': itineraryItemId,
      'title': title,
      'content': content,
      'entry_date': entryDate,
      if (locationName != null) 'location_name': locationName,
      if (weather != null) 'weather': weather,
      if (mood != null) 'mood': mood,
      'is_shared': isShared,
      'is_author': isAuthor,
      'photos': photos,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  JournalEntry copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? authorName,
    String? authorAvatarUrl,
    String? itineraryItemId,
    String? title,
    String? content,
    String? entryDate,
    String? locationName,
    String? weather,
    String? mood,
    bool? isShared,
    bool? isAuthor,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      itineraryItemId: itineraryItemId ?? this.itineraryItemId,
      title: title ?? this.title,
      content: content ?? this.content,
      entryDate: entryDate ?? this.entryDate,
      locationName: locationName ?? this.locationName,
      weather: weather ?? this.weather,
      mood: mood ?? this.mood,
      isShared: isShared ?? this.isShared,
      isAuthor: isAuthor ?? this.isAuthor,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
