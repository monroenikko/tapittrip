class AssistantSuggestedAction {
  const AssistantSuggestedAction({
    required this.label,
    required this.kind,
    this.payload = const {},
  });

  final String label;
  final String kind;
  final Map<String, dynamic> payload;

  factory AssistantSuggestedAction.fromJson(Map<String, dynamic> json) {
    return AssistantSuggestedAction(
      label: (json['label'] as String?) ?? 'Action',
      kind: (json['kind'] as String?) ?? 'general',
      payload: json['payload'] != null
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {'label': label, 'kind': kind, 'payload': payload};
  }
}

class TripAssistantResponse {
  const TripAssistantResponse({
    required this.reply,
    required this.category,
    this.contextSummary = const {},
    this.suggestedActions = const [],
  });

  final String reply;
  final String category;
  final Map<String, dynamic> contextSummary;
  final List<AssistantSuggestedAction> suggestedActions;

  factory TripAssistantResponse.fromJson(Map<String, dynamic> json) {
    return TripAssistantResponse(
      reply: (json['reply'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'general',
      contextSummary: json['context_summary'] != null
          ? Map<String, dynamic>.from(json['context_summary'] as Map)
          : const {},
      suggestedActions: (json['suggested_actions'] as List<dynamic>? ?? [])
          .map(
            (e) => AssistantSuggestedAction.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reply': reply,
      'category': category,
      'context_summary': contextSummary,
      'suggested_actions': suggestedActions.map((e) => e.toJson()).toList(),
    };
  }
}
