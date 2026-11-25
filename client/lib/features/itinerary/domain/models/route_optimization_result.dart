import 'itinerary_item.dart';

class ItineraryTransitModeComparison {
  const ItineraryTransitModeComparison({
    required this.mode,
    required this.label,
    required this.suitability,
    required this.advisoryNote,
    required this.googleMapsDirectionsUrl,
    this.estimatedDurationMinutes,
  });

  final String mode;
  final String label;
  final int? estimatedDurationMinutes;
  final String suitability;
  final String advisoryNote;
  final String googleMapsDirectionsUrl;

  factory ItineraryTransitModeComparison.fromJson(Map<String, dynamic> json) {
    return ItineraryTransitModeComparison(
      mode: json['mode'] as String? ?? 'walk',
      label: json['label'] as String? ?? 'Walk',
      estimatedDurationMinutes: (json['estimated_duration_minutes'] as num?)
          ?.toInt(),
      suitability: json['suitability'] as String? ?? 'alternative',
      advisoryNote: json['advisory_note'] as String? ?? '',
      googleMapsDirectionsUrl:
          json['google_maps_directions_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'label': label,
    'estimated_duration_minutes': estimatedDurationMinutes,
    'suitability': suitability,
    'advisory_note': advisoryNote,
    'google_maps_directions_url': googleMapsDirectionsUrl,
  };
}

class ItineraryTransitSegment {
  const ItineraryTransitSegment({
    required this.fromItemId,
    required this.fromTitle,
    required this.fromPlaceName,
    required this.toItemId,
    required this.toTitle,
    required this.toPlaceName,
    required this.recommendedMode,
    required this.exceedsWalkingLimit,
    required this.modeComparisons,
    required this.providerAttribution,
    required this.verified,
    required this.limitationNotice,
    this.tripDayId,
    this.distanceMeters,
    this.distanceKm,
    this.estimatedDurationMinutes,
  });

  final String fromItemId;
  final String fromTitle;
  final String fromPlaceName;
  final String toItemId;
  final String toTitle;
  final String toPlaceName;
  final String? tripDayId;
  final int? distanceMeters;
  final double? distanceKm;
  final String recommendedMode;
  final int? estimatedDurationMinutes;
  final bool exceedsWalkingLimit;
  final List<ItineraryTransitModeComparison> modeComparisons;
  final String providerAttribution;
  final bool verified;
  final String limitationNotice;

  factory ItineraryTransitSegment.fromJson(Map<String, dynamic> json) {
    final rawModes = json['mode_comparisons'];
    return ItineraryTransitSegment(
      fromItemId: json['from_item_id'] as String? ?? '',
      fromTitle: json['from_title'] as String? ?? '',
      fromPlaceName: json['from_place_name'] as String? ?? '',
      toItemId: json['to_item_id'] as String? ?? '',
      toTitle: json['to_title'] as String? ?? '',
      toPlaceName: json['to_place_name'] as String? ?? '',
      tripDayId: json['trip_day_id'] as String?,
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      recommendedMode:
          json['recommended_mode'] as String? ?? 'unknown_coordinates',
      estimatedDurationMinutes: (json['estimated_duration_minutes'] as num?)
          ?.toInt(),
      exceedsWalkingLimit: json['exceeds_walking_limit'] as bool? ?? false,
      modeComparisons: rawModes is List
          ? rawModes
                .whereType<Map>()
                .map(
                  (m) => ItineraryTransitModeComparison.fromJson(
                    Map<String, dynamic>.from(m),
                  ),
                )
                .toList()
          : const [],
      providerAttribution: json['provider_attribution'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      limitationNotice: json['limitation_notice'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'from_item_id': fromItemId,
    'from_title': fromTitle,
    'from_place_name': fromPlaceName,
    'to_item_id': toItemId,
    'to_title': toTitle,
    'to_place_name': toPlaceName,
    'trip_day_id': tripDayId,
    'distance_meters': distanceMeters,
    'distance_km': distanceKm,
    'recommended_mode': recommendedMode,
    'estimated_duration_minutes': estimatedDurationMinutes,
    'exceeds_walking_limit': exceedsWalkingLimit,
    'mode_comparisons': modeComparisons.map((m) => m.toJson()).toList(),
    'provider_attribution': providerAttribution,
    'verified': verified,
    'limitation_notice': limitationNotice,
  };
}

class RouteOptimizationResult {
  const RouteOptimizationResult({
    required this.tripId,
    required this.applied,
    required this.isAlreadyOptimal,
    required this.currentItemIds,
    required this.proposedItemIds,
    required this.pinnedItemIds,
    required this.currentTotalDistanceKm,
    required this.optimizedTotalDistanceKm,
    required this.distanceSavedKm,
    required this.estimatedCo2SavedKg,
    required this.preserveFixedTimes,
    required this.maxWalkingMetersPerLeg,
    required this.segments,
    required this.items,
    required this.providerAttribution,
    required this.verified,
    required this.advisoryNotice,
    this.tripDayId,
    this.anchorStayName,
  });

  final String tripId;
  final String? tripDayId;
  final bool applied;
  final bool isAlreadyOptimal;
  final List<String> currentItemIds;
  final List<String> proposedItemIds;
  final List<String> pinnedItemIds;
  final double currentTotalDistanceKm;
  final double optimizedTotalDistanceKm;
  final double distanceSavedKm;
  final double estimatedCo2SavedKg;
  final bool preserveFixedTimes;
  final int maxWalkingMetersPerLeg;
  final String? anchorStayName;
  final List<ItineraryTransitSegment> segments;
  final List<ItineraryItem> items;
  final String providerAttribution;
  final bool verified;
  final String advisoryNotice;

  factory RouteOptimizationResult.fromJson(Map<String, dynamic> json) {
    final constraints = json['constraints_applied'] is Map
        ? Map<String, dynamic>.from(json['constraints_applied'] as Map)
        : const <String, dynamic>{};
    final rawSegments = json['segments'];
    final rawItems = json['items'];

    return RouteOptimizationResult(
      tripId: json['trip_id'] as String? ?? '',
      tripDayId: json['trip_day_id'] as String?,
      applied: json['applied'] as bool? ?? false,
      isAlreadyOptimal: json['is_already_optimal'] as bool? ?? true,
      currentItemIds:
          (json['current_item_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      proposedItemIds:
          (json['proposed_item_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      pinnedItemIds:
          (json['pinned_item_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      currentTotalDistanceKm:
          (json['current_total_distance_km'] as num?)?.toDouble() ?? 0.0,
      optimizedTotalDistanceKm:
          (json['optimized_total_distance_km'] as num?)?.toDouble() ?? 0.0,
      distanceSavedKm: (json['distance_saved_km'] as num?)?.toDouble() ?? 0.0,
      estimatedCo2SavedKg:
          (json['estimated_co2_saved_kg'] as num?)?.toDouble() ?? 0.0,
      preserveFixedTimes: constraints['preserve_fixed_times'] as bool? ?? true,
      maxWalkingMetersPerLeg:
          (constraints['max_walking_meters_per_leg'] as num?)?.toInt() ?? 1500,
      anchorStayName: constraints['anchor_stay_name'] as String?,
      segments: rawSegments is List
          ? rawSegments
                .whereType<Map>()
                .map(
                  (s) => ItineraryTransitSegment.fromJson(
                    Map<String, dynamic>.from(s),
                  ),
                )
                .toList()
          : const [],
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (it) => ItineraryItem.fromJson(Map<String, dynamic>.from(it)),
                )
                .toList()
          : const [],
      providerAttribution: json['provider_attribution'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      advisoryNotice: json['advisory_notice'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'trip_id': tripId,
    'trip_day_id': tripDayId,
    'applied': applied,
    'is_already_optimal': isAlreadyOptimal,
    'current_item_ids': currentItemIds,
    'proposed_item_ids': proposedItemIds,
    'pinned_item_ids': pinnedItemIds,
    'current_total_distance_km': currentTotalDistanceKm,
    'optimized_total_distance_km': optimizedTotalDistanceKm,
    'distance_saved_km': distanceSavedKm,
    'estimated_co2_saved_kg': estimatedCo2SavedKg,
    'constraints_applied': {
      'preserve_fixed_times': preserveFixedTimes,
      'max_walking_meters_per_leg': maxWalkingMetersPerLeg,
      'anchor_stay_name': anchorStayName,
    },
    'segments': segments.map((s) => s.toJson()).toList(),
    'items': items.map((it) => it.toJson()).toList(),
    'provider_attribution': providerAttribution,
    'verified': verified,
    'advisory_notice': advisoryNotice,
  };
}
