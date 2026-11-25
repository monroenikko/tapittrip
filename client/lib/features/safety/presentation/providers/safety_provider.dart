import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/safety_repository.dart';
import '../../domain/models/destination_safety_profile.dart';

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SafetyRepository(apiClient: apiClient);
});

class SafetyLookupRequest {
  const SafetyLookupRequest({this.tripId, required this.country});

  final String? tripId;
  final String country;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafetyLookupRequest &&
          runtimeType == other.runtimeType &&
          tripId == other.tripId &&
          country == other.country;

  @override
  int get hashCode => Object.hash(tripId, country);
}

final destinationSafetyProfileProvider =
    FutureProvider.family<DestinationSafetyProfile, SafetyLookupRequest>((
      ref,
      request,
    ) async {
      final repo = ref.watch(safetyRepositoryProvider);
      if (request.tripId != null && request.tripId!.trim().isNotEmpty) {
        return repo.getTripSafetyProfile(
          request.tripId!,
          countryOverride: request.country.trim().isNotEmpty
              ? request.country.trim()
              : null,
        );
      }
      return repo.getCountrySafetyProfile(request.country);
    });

final curatedSafetyDirectoryProvider =
    FutureProvider<List<DestinationSafetyProfile>>((ref) async {
      final repo = ref.watch(safetyRepositoryProvider);
      return repo.listCuratedProfiles();
    });
