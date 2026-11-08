import '../../../core/network/api_client.dart';
import '../domain/models/ai_itinerary_plan.dart';
import '../domain/models/itinerary_item.dart';
import '../domain/models/trip_assistant_response.dart';

class AiItineraryRepository {
  AiItineraryRepository({required this.apiClient});

  final ApiClient apiClient;

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
      '/v1/trips/$tripId/ai-plan/generate',
      data: payload,
    );
    final data = response['data'] as Map<String, dynamic>;
    return AiItineraryPlan.fromJson(data);
  }

  Future<List<ItineraryItem>> applyPlan(
    String tripId,
    List<AiDaySuggestion> days,
  ) async {
    final payload = {'days': days.map((d) => d.toJson()).toList()};

    final response = await apiClient.post(
      '/v1/trips/$tripId/ai-plan/apply',
      data: payload,
    );
    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => ItineraryItem.fromJson(Map<String, dynamic>.from(e as Map)))
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
      '/v1/trips/$tripId/assistant/query',
      data: payload,
    );
    final data = response['data'] as Map<String, dynamic>;
    return TripAssistantResponse.fromJson(data);
  }
}
