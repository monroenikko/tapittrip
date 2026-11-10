class TripRecap {
  const TripRecap({
    required this.trip,
    required this.highlights,
    required this.storyAlbum,
    required this.expenseSummary,
  });

  final TripRecapInfo trip;
  final TripRecapHighlights highlights;
  final TripRecapStoryAlbum storyAlbum;
  final TripRecapExpenseSummary expenseSummary;

  factory TripRecap.fromJson(Map<String, dynamic> json) {
    return TripRecap(
      trip: TripRecapInfo.fromJson(
        Map<String, dynamic>.from(json['trip'] as Map? ?? {}),
      ),
      highlights: TripRecapHighlights.fromJson(
        Map<String, dynamic>.from(json['highlights'] as Map? ?? {}),
      ),
      storyAlbum: TripRecapStoryAlbum.fromJson(
        Map<String, dynamic>.from(json['story_album'] as Map? ?? {}),
      ),
      expenseSummary: TripRecapExpenseSummary.fromJson(
        Map<String, dynamic>.from(json['expense_summary'] as Map? ?? {}),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'trip': trip.toJson(),
    'highlights': highlights.toJson(),
    'story_album': storyAlbum.toJson(),
    'expense_summary': expenseSummary.toJson(),
  };
}

class TripRecapInfo {
  const TripRecapInfo({
    required this.id,
    required this.title,
    required this.destination,
    this.startDate,
    this.endDate,
    this.durationDays,
    required this.status,
  });

  final String id;
  final String title;
  final String destination;
  final String? startDate;
  final String? endDate;
  final int? durationDays;
  final String status;

  factory TripRecapInfo.fromJson(Map<String, dynamic> json) {
    return TripRecapInfo(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      destination: (json['destination'] ?? '').toString(),
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      durationDays: json['duration_days'] as int?,
      status: (json['status'] ?? 'planned').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'destination': destination,
    'start_date': startDate,
    'end_date': endDate,
    'duration_days': durationDays,
    'status': status,
  };
}

class TripRecapHighlights {
  const TripRecapHighlights({
    required this.totalPlacesVisited,
    required this.totalPlacesPlanned,
    required this.completionRatePercentage,
    required this.totalStays,
    required this.totalNights,
    required this.totalCompanions,
  });

  final int totalPlacesVisited;
  final int totalPlacesPlanned;
  final int completionRatePercentage;
  final int totalStays;
  final int totalNights;
  final int totalCompanions;

  factory TripRecapHighlights.fromJson(Map<String, dynamic> json) {
    return TripRecapHighlights(
      totalPlacesVisited: (json['total_places_visited'] as num?)?.toInt() ?? 0,
      totalPlacesPlanned: (json['total_places_planned'] as num?)?.toInt() ?? 0,
      completionRatePercentage:
          (json['completion_rate_percentage'] as num?)?.toInt() ?? 0,
      totalStays: (json['total_stays'] as num?)?.toInt() ?? 0,
      totalNights: (json['total_nights'] as num?)?.toInt() ?? 0,
      totalCompanions: (json['total_companions'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_places_visited': totalPlacesVisited,
    'total_places_planned': totalPlacesPlanned,
    'completion_rate_percentage': completionRatePercentage,
    'total_stays': totalStays,
    'total_nights': totalNights,
    'total_companions': totalCompanions,
  };
}

class TripRecapStoryAlbum {
  const TripRecapStoryAlbum({
    required this.totalPhotos,
    required this.photos,
    required this.moments,
    required this.moodBreakdown,
    this.topMood,
  });

  final int totalPhotos;
  final List<TripRecapPhoto> photos;
  final List<TripRecapMoment> moments;
  final Map<String, int> moodBreakdown;
  final String? topMood;

  String? get topMoodEmoji {
    if (topMood == null) return null;
    return switch (topMood!.toLowerCase().trim()) {
      'amazed' => '🤩',
      'happy' => '😊',
      'peaceful' => '😌',
      'excited' => '🎉',
      'tired' => '😴',
      'grateful' => '🙏',
      'adventurous' => '🏔️',
      _ => '✨',
    };
  }

  factory TripRecapStoryAlbum.fromJson(Map<String, dynamic> json) {
    final rawPhotos = (json['photos'] as List<dynamic>?) ?? [];
    final rawMoments = (json['moments'] as List<dynamic>?) ?? [];

    final rawBreakdown = json['mood_breakdown'];
    final breakdown = <String, int>{};
    if (rawBreakdown is Map) {
      rawBreakdown.forEach((key, value) {
        if (value is num) {
          breakdown[key.toString()] = value.toInt();
        }
      });
    }

    return TripRecapStoryAlbum(
      totalPhotos: (json['total_photos'] as num?)?.toInt() ?? 0,
      photos: rawPhotos
          .map(
            (p) => TripRecapPhoto.fromJson(
              Map<String, dynamic>.from(p as Map? ?? {}),
            ),
          )
          .toList(),
      moments: rawMoments
          .map(
            (m) => TripRecapMoment.fromJson(
              Map<String, dynamic>.from(m as Map? ?? {}),
            ),
          )
          .toList(),
      moodBreakdown: breakdown,
      topMood: json['top_mood'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_photos': totalPhotos,
    'photos': photos.map((p) => p.toJson()).toList(),
    'moments': moments.map((m) => m.toJson()).toList(),
    'mood_breakdown': moodBreakdown,
    'top_mood': topMood,
  };
}

class TripRecapPhoto {
  const TripRecapPhoto({
    required this.url,
    required this.caption,
    this.date,
    required this.authorName,
    this.mood,
    this.locationName,
  });

  final String url;
  final String caption;
  final String? date;
  final String authorName;
  final String? mood;
  final String? locationName;

  factory TripRecapPhoto.fromJson(Map<String, dynamic> json) {
    return TripRecapPhoto(
      url: (json['url'] ?? '').toString(),
      caption: (json['caption'] ?? '').toString(),
      date: json['date'] as String?,
      authorName: (json['author_name'] ?? 'Traveler').toString(),
      mood: json['mood'] as String?,
      locationName: json['location_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'caption': caption,
    'date': date,
    'author_name': authorName,
    'mood': mood,
    'location_name': locationName,
  };
}

class TripRecapMoment {
  const TripRecapMoment({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    this.authorAvatarUrl,
    this.entryDate,
    this.mood,
    this.moodEmoji,
    this.weather,
    this.locationName,
    this.coverPhoto,
    required this.isShared,
  });

  final String id;
  final String title;
  final String content;
  final String authorName;
  final String? authorAvatarUrl;
  final String? entryDate;
  final String? mood;
  final String? moodEmoji;
  final String? weather;
  final String? locationName;
  final String? coverPhoto;
  final bool isShared;

  factory TripRecapMoment.fromJson(Map<String, dynamic> json) {
    return TripRecapMoment(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      authorName: (json['author_name'] ?? 'Traveler').toString(),
      authorAvatarUrl: json['author_avatar_url'] as String?,
      entryDate: json['entry_date'] as String?,
      mood: json['mood'] as String?,
      moodEmoji: json['mood_emoji'] as String?,
      weather: json['weather'] as String?,
      locationName: json['location_name'] as String?,
      coverPhoto: json['cover_photo'] as String?,
      isShared: json['is_shared'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'author_name': authorName,
    'author_avatar_url': authorAvatarUrl,
    'entry_date': entryDate,
    'mood': mood,
    'mood_emoji': moodEmoji,
    'weather': weather,
    'location_name': locationName,
    'cover_photo': coverPhoto,
    'is_shared': isShared,
  };
}

class TripRecapExpenseSummary {
  const TripRecapExpenseSummary({
    required this.currency,
    required this.totalSpentMinor,
    required this.formattedTotalSpent,
    required this.expensesCount,
    this.topCategory,
    required this.hasBudget,
    this.budgetUtilizationPercent,
  });

  final String currency;
  final int totalSpentMinor;
  final String formattedTotalSpent;
  final int expensesCount;
  final String? topCategory;
  final bool hasBudget;
  final double? budgetUtilizationPercent;

  factory TripRecapExpenseSummary.fromJson(Map<String, dynamic> json) {
    return TripRecapExpenseSummary(
      currency: (json['currency'] ?? 'USD').toString(),
      totalSpentMinor: (json['total_spent_minor'] as num?)?.toInt() ?? 0,
      formattedTotalSpent:
          (json['formatted_total_spent'] ?? '${json['currency'] ?? 'USD'} 0')
              .toString(),
      expensesCount: (json['expenses_count'] as num?)?.toInt() ?? 0,
      topCategory: json['top_category'] as String?,
      hasBudget: json['has_budget'] == true,
      budgetUtilizationPercent: (json['budget_utilization_percent'] as num?)
          ?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'currency': currency,
    'total_spent_minor': totalSpentMinor,
    'formatted_total_spent': formattedTotalSpent,
    'expenses_count': expensesCount,
    'top_category': topCategory,
    'has_budget': hasBudget,
    'budget_utilization_percent': budgetUtilizationPercent,
  };
}
