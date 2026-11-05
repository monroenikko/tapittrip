import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/planning_mode.dart';
import '../domain/models/trip.dart';

abstract interface class TripRepository {
  Future<List<Trip>> getTrips();
  Future<Trip> getTrip(String id);
  Future<Trip> createTrip({
    required String title,
    String? startDate,
    String? endDate,
    String? primaryTimezone,
    String? originCountry,
    String? destinationCountry,
    String? tripType,
    PlanningMode planningMode = PlanningMode.diy,
  });
  Future<Trip> updateTrip(
    String id, {
    String? title,
    String? startDate,
    String? endDate,
    String? primaryTimezone,
    String? originCountry,
    String? destinationCountry,
    String? tripType,
    PlanningMode? planningMode,
    String? status,
  });
  Future<void> deleteTrip(String id);
}

class RemoteTripRepository implements TripRepository {
  const RemoteTripRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Trip>> getTrips() async {
    final response = await _apiClient.get('/trips');
    if (response is List) {
      return response
          .map((item) => Trip.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<Trip> getTrip(String id) async {
    final response = await _apiClient.get('/trips/$id');
    return Trip.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Trip> createTrip({
    required String title,
    String? startDate,
    String? endDate,
    String? primaryTimezone,
    String? originCountry,
    String? destinationCountry,
    String? tripType,
    PlanningMode planningMode = PlanningMode.diy,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'planning_mode': planningMode.value,
      'start_date': ?startDate,
      'end_date': ?endDate,
      'primary_timezone': ?primaryTimezone,
      'origin_country': ?originCountry,
      'destination_country': ?destinationCountry,
      'trip_type': ?tripType,
    };

    final response = await _apiClient.post('/trips', data: payload);
    return Trip.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Trip> updateTrip(
    String id, {
    String? title,
    String? startDate,
    String? endDate,
    String? primaryTimezone,
    String? originCountry,
    String? destinationCountry,
    String? tripType,
    PlanningMode? planningMode,
    String? status,
  }) async {
    final payload = <String, dynamic>{
      'title': ?title,
      'start_date': ?startDate,
      'end_date': ?endDate,
      'primary_timezone': ?primaryTimezone,
      'origin_country': ?originCountry,
      'destination_country': ?destinationCountry,
      'trip_type': ?tripType,
      'planning_mode': ?planningMode?.value,
      'status': ?status,
    };

    final response = await _apiClient.put('/trips/$id', data: payload);
    return Trip.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTrip(String id) async {
    await _apiClient.delete('/trips/$id');
  }
}

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RemoteTripRepository(apiClient);
});
