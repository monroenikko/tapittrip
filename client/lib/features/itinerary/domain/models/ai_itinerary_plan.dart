class AiActivitySuggestion {
  const AiActivitySuggestion({
    required this.title,
    required this.kind,
    required this.neighborhood,
    this.description,
    this.plannedStartTime,
    this.plannedEndTime,
    this.placeName,
    this.placeAddress,
    this.latitude,
    this.longitude,
    this.costEstimate,
    this.accessibilityNote,
  });

  final String title;
  final String kind;
  final String neighborhood;
  final String? description;
  final String? plannedStartTime;
  final String? plannedEndTime;
  final String? placeName;
  final String? placeAddress;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? costEstimate;
  final String? accessibilityNote;

  factory AiActivitySuggestion.fromJson(Map<String, dynamic> json) {
    return AiActivitySuggestion(
      title: json['title'] as String,
      kind: (json['kind'] as String?) ?? 'sightseeing',
      neighborhood: (json['neighborhood'] as String?) ?? 'City Center',
      description: json['description'] as String?,
      plannedStartTime: json['planned_start_time'] as String?,
      plannedEndTime: json['planned_end_time'] as String?,
      placeName: json['place_name'] as String?,
      placeAddress: json['place_address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      costEstimate: json['cost_estimate'] != null
          ? Map<String, dynamic>.from(json['cost_estimate'] as Map)
          : null,
      accessibilityNote: json['accessibility_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'kind': kind,
      'neighborhood': neighborhood,
      if (description != null) 'description': description,
      if (plannedStartTime != null) 'planned_start_time': plannedStartTime,
      if (plannedEndTime != null) 'planned_end_time': plannedEndTime,
      if (placeName != null) 'place_name': placeName,
      if (placeAddress != null) 'place_address': placeAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (costEstimate != null) 'cost_estimate': costEstimate,
      if (accessibilityNote != null) 'accessibility_note': accessibilityNote,
    };
  }
}

class AiDaySuggestion {
  const AiDaySuggestion({
    required this.dayNumber,
    required this.title,
    required this.theme,
    required this.primaryNeighborhood,
    this.activities = const [],
    this.budgetEstimate,
    this.familyTip,
  });

  final int dayNumber;
  final String title;
  final String theme;
  final String primaryNeighborhood;
  final List<AiActivitySuggestion> activities;
  final Map<String, dynamic>? budgetEstimate;
  final String? familyTip;

  factory AiDaySuggestion.fromJson(Map<String, dynamic> json) {
    return AiDaySuggestion(
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 1,
      title: (json['title'] as String?) ?? 'Day 1',
      theme: (json['theme'] as String?) ?? 'Exploration',
      primaryNeighborhood:
          (json['primary_neighborhood'] as String?) ?? 'Downtown',
      activities: (json['activities'] as List<dynamic>? ?? [])
          .map(
            (e) => AiActivitySuggestion.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      budgetEstimate: json['budget_estimate'] != null
          ? Map<String, dynamic>.from(json['budget_estimate'] as Map)
          : null,
      familyTip: json['family_tip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_number': dayNumber,
      'title': title,
      'theme': theme,
      'primary_neighborhood': primaryNeighborhood,
      'activities': activities.map((e) => e.toJson()).toList(),
      if (budgetEstimate != null) 'budget_estimate': budgetEstimate,
      if (familyTip != null) 'family_tip': familyTip,
    };
  }
}

class AiItineraryPlan {
  const AiItineraryPlan({
    required this.destination,
    required this.summary,
    required this.travelParty,
    required this.pace,
    this.days = const [],
    this.totalEstimatedBudget,
    this.weatherAlternativeNote,
  });

  final String destination;
  final String summary;
  final String travelParty;
  final String pace;
  final List<AiDaySuggestion> days;
  final Map<String, dynamic>? totalEstimatedBudget;
  final String? weatherAlternativeNote;

  factory AiItineraryPlan.fromJson(Map<String, dynamic> json) {
    return AiItineraryPlan(
      destination: (json['destination'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      travelParty: (json['travel_party'] as String?) ?? 'couple',
      pace: (json['pace'] as String?) ?? 'balanced',
      days: (json['days'] as List<dynamic>? ?? [])
          .map(
            (e) =>
                AiDaySuggestion.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      totalEstimatedBudget: json['total_estimated_budget'] != null
          ? Map<String, dynamic>.from(json['total_estimated_budget'] as Map)
          : null,
      weatherAlternativeNote: json['weather_alternative_note'] as String?,
    );
  }
}
