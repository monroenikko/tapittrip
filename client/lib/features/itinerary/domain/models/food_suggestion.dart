class FoodSuggestionItem {
  const FoodSuggestionItem({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.mealType,
    required this.neighborhood,
    required this.proximityLabel,
    required this.dietaryTags,
    required this.priceTier,
    required this.notes,
    required this.googleMapsSearchUrl,
    required this.suggestedTitle,
    required this.suggestedPlaceName,
    required this.suggestedNotes,
    required this.providerAttribution,
    required this.verified,
  });

  final String id;
  final String name;
  final String cuisine;
  final String mealType;
  final String neighborhood;
  final String proximityLabel;
  final List<String> dietaryTags;
  final String priceTier;
  final String notes;
  final String googleMapsSearchUrl;
  final String suggestedTitle;
  final String suggestedPlaceName;
  final String suggestedNotes;
  final String providerAttribution;
  final bool verified;

  factory FoodSuggestionItem.fromJson(Map<String, dynamic> json) {
    final action = json['suggested_action'] is Map
        ? Map<String, dynamic>.from(json['suggested_action'] as Map)
        : const <String, dynamic>{};
    final payload = action['payload'] is Map
        ? Map<String, dynamic>.from(action['payload'] as Map)
        : const <String, dynamic>{};
    final name = json['name'] as String? ?? '';
    final notes = json['notes'] as String? ?? '';

    return FoodSuggestionItem(
      id: json['id'] as String? ?? '',
      name: name,
      cuisine: json['cuisine'] as String? ?? '',
      mealType: json['meal_type'] as String? ?? 'lunch',
      neighborhood: json['neighborhood'] as String? ?? '',
      proximityLabel: json['proximity_label'] as String? ?? '',
      dietaryTags:
          (json['dietary_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      priceTier: json['price_tier'] as String? ?? 'moderate',
      notes: notes,
      googleMapsSearchUrl: json['google_maps_search_url'] as String? ?? '',
      suggestedTitle: payload['title'] as String? ?? name,
      suggestedPlaceName: payload['place_name'] as String? ?? name,
      suggestedNotes: payload['notes'] as String? ?? notes,
      providerAttribution: json['provider_attribution'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cuisine': cuisine,
    'meal_type': mealType,
    'neighborhood': neighborhood,
    'proximity_label': proximityLabel,
    'dietary_tags': dietaryTags,
    'price_tier': priceTier,
    'notes': notes,
    'google_maps_search_url': googleMapsSearchUrl,
    'suggested_action': {
      'label': 'Add $suggestedTitle',
      'kind': 'add_activity',
      'payload': {
        'title': suggestedTitle,
        'kind': 'meal',
        'place_name': suggestedPlaceName,
        'notes': suggestedNotes,
      },
    },
    'provider_attribution': providerAttribution,
    'verified': verified,
  };
}

class FoodSuggestionsResult {
  const FoodSuggestionsResult({
    required this.tripId,
    required this.destination,
    required this.mealTypeFilter,
    required this.nearFilter,
    required this.source,
    required this.verified,
    required this.advisoryNotice,
    required this.suggestions,
    this.anchorStayName,
    this.dietaryFilter,
  });

  final String tripId;
  final String destination;
  final String? anchorStayName;
  final String mealTypeFilter;
  final String? dietaryFilter;
  final String nearFilter;
  final String source;
  final bool verified;
  final String advisoryNotice;
  final List<FoodSuggestionItem> suggestions;

  factory FoodSuggestionsResult.fromJson(Map<String, dynamic> json) {
    final filters = json['filters_applied'] is Map
        ? Map<String, dynamic>.from(json['filters_applied'] as Map)
        : const <String, dynamic>{};
    final rawList = json['suggestions'];

    return FoodSuggestionsResult(
      tripId: json['trip_id'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      anchorStayName: json['anchor_stay_name'] as String?,
      mealTypeFilter: filters['meal_type'] as String? ?? 'all',
      dietaryFilter: filters['dietary'] as String?,
      nearFilter: filters['near'] as String? ?? 'stay',
      source: json['source'] as String? ?? 'curated_directory',
      verified: json['verified'] as bool? ?? false,
      advisoryNotice: json['advisory_notice'] as String? ?? '',
      suggestions: rawList is List
          ? rawList
                .whereType<Map>()
                .map(
                  (item) => FoodSuggestionItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'trip_id': tripId,
    'destination': destination,
    'anchor_stay_name': anchorStayName,
    'filters_applied': {
      'meal_type': mealTypeFilter,
      'dietary': dietaryFilter,
      'near': nearFilter,
    },
    'source': source,
    'verified': verified,
    'advisory_notice': advisoryNotice,
    'suggestions': suggestions.map((s) => s.toJson()).toList(),
  };
}
