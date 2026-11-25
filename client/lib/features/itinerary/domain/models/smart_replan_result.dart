import 'itinerary_item.dart';

class SmartReplanProposedChange {
  const SmartReplanProposedChange({
    required this.action,
    required this.title,
    required this.kind,
    required this.reason,
    this.targetItemId,
    this.placeName,
    this.notes,
    this.startsAtUtc,
    this.endsAtUtc,
  });

  final String action; // keep_visited, shift_time, add_alternative
  final String? targetItemId;
  final String title;
  final String kind;
  final String? placeName;
  final String? notes;
  final String reason;
  final String? startsAtUtc;
  final String? endsAtUtc;

  factory SmartReplanProposedChange.fromJson(Map<String, dynamic> json) {
    return SmartReplanProposedChange(
      action: json['action'] as String? ?? 'add_alternative',
      targetItemId: json['target_item_id'] as String?,
      title: json['title'] as String? ?? '',
      kind: json['kind'] as String? ?? 'custom',
      placeName: json['place_name'] as String?,
      notes: json['notes'] as String?,
      reason: json['reason'] as String? ?? '',
      startsAtUtc: json['starts_at_utc'] as String?,
      endsAtUtc: json['ends_at_utc'] as String?,
    );
  }
}

class SmartReplanResult {
  const SmartReplanResult({
    required this.tripId,
    required this.triggerReason,
    required this.applied,
    required this.preservedVisitedCount,
    required this.summary,
    required this.proposedChanges,
    required this.items,
    required this.providerAttribution,
    required this.verified,
    required this.advisoryNotice,
    this.tripDayId,
  });

  final String tripId;
  final String? tripDayId;
  final String triggerReason;
  final bool applied;
  final int preservedVisitedCount;
  final String summary;
  final List<SmartReplanProposedChange> proposedChanges;
  final List<ItineraryItem> items;
  final String providerAttribution;
  final bool verified;
  final String advisoryNotice;

  factory SmartReplanResult.fromJson(Map<String, dynamic> json) {
    final rawChanges = json['proposed_changes'];
    final rawItems = json['items'];

    return SmartReplanResult(
      tripId: json['trip_id'] as String? ?? '',
      tripDayId: json['trip_day_id'] as String?,
      triggerReason: json['trigger_reason'] as String? ?? 'rain_weather',
      applied: json['applied'] as bool? ?? false,
      preservedVisitedCount:
          (json['preserved_visited_count'] as num?)?.toInt() ?? 0,
      summary: json['summary'] as String? ?? '',
      proposedChanges: rawChanges is List
          ? rawChanges
                .whereType<Map>()
                .map(
                  (c) => SmartReplanProposedChange.fromJson(
                    Map<String, dynamic>.from(c),
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
}
