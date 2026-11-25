import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../itinerary/domain/models/trip_assistant_response.dart';

final stayRecommendationRepositoryProvider = Provider((ref) {
  return StayRecommendationRepository(apiClient: ref.watch(apiClientProvider));
});

class StayRecommendationRepository {
  StayRecommendationRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<TripAssistantResponse> fetch(String tripId) async {
    final response = await apiClient.post(
      '/trips/$tripId/stay-recommendations',
    );
    final body = Map<String, dynamic>.from(response as Map);
    return TripAssistantResponse.fromJson(
      body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body,
    );
  }
}
