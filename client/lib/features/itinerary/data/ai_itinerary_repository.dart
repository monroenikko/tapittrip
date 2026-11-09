import '../../../core/network/api_client.dart';
import '../domain/models/ai_itinerary_plan.dart';
import '../domain/models/itinerary_item.dart';
import '../domain/models/trip_assistant_response.dart';

class AiItineraryRepository {
  AiItineraryRepository({required this.apiClient});

  final ApiClient apiClient;

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map) {
      if (response.containsKey('data') && response['data'] is Map) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
      return Map<String, dynamic>.from(response);
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) {
      return response;
    }
    if (response is Map &&
        response.containsKey('data') &&
        response['data'] is List) {
      return response['data'] as List<dynamic>;
    }
    return const [];
  }

  Future<AiItineraryPlan> generatePlan(
    String tripId, {
    String? destination,
    int? durationDays,
    String? budgetTier,
    String? travelParty,
    String? pace,
    List<String>? interests,
  }) async {
    final payload = <String, dynamic>{};
    if (destination != null && destination.isNotEmpty) {
      payload['destination'] = destination;
    }
    if (durationDays != null) {
      payload['duration_days'] = durationDays;
    }
    if (budgetTier != null) {
      payload['budget_tier'] = budgetTier;
    }
    if (travelParty != null) {
      payload['travel_party'] = travelParty;
    }
    if (pace != null) {
      payload['pace'] = pace;
    }
    if (interests != null && interests.isNotEmpty) {
      payload['interests'] = interests;
    }

    final response = await apiClient.post(
      '/trips/$tripId/ai-plan/generate',
      data: payload,
    );
    final data = _extractMap(response);
    return AiItineraryPlan.fromJson(data);
  }

  Future<List<ItineraryItem>> applyPlan(
    String tripId,
    List<AiDaySuggestion> days,
  ) async {
    final payload = {'days': days.map((d) => d.toJson()).toList()};

    final response = await apiClient.post(
      '/trips/$tripId/ai-plan/apply',
      data: payload,
    );
    final list = _extractList(response);
    return list
        .whereType<Map>()
        .map((e) => ItineraryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<TripAssistantResponse> askAssistant(
    String tripId, {
    required String query,
    String? contextDate,
    String? terminalCode,
  }) async {
    final payload = <String, dynamic>{'query': query};
    if (contextDate != null) {
      payload['context_date'] = contextDate;
    }
    if (terminalCode != null) {
      payload['terminal_code'] = terminalCode;
    }

    final response = await apiClient.post(
      '/trips/$tripId/assistant/query',
      data: payload,
    );
    final data = _extractMap(response);
    return TripAssistantResponse.fromJson(data);
  }
}
