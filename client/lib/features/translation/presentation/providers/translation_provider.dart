import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/translation_repository.dart';
import '../../domain/models/translation_models.dart';

final translationRepositoryProvider = Provider<TranslationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TranslationRepository(apiClient: apiClient);
});

class PhrasebookLookupRequest {
  const PhrasebookLookupRequest({this.tripId, required this.languageOrCountry});

  final String? tripId;
  final String languageOrCountry;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhrasebookLookupRequest &&
          runtimeType == other.runtimeType &&
          tripId == other.tripId &&
          languageOrCountry == other.languageOrCountry;

  @override
  int get hashCode => Object.hash(tripId, languageOrCountry);
}

final phrasebookBundleProvider =
    FutureProvider.family<PhrasebookBundle, PhrasebookLookupRequest>((
      ref,
      request,
    ) async {
      final repo = ref.watch(translationRepositoryProvider);
      if (request.tripId != null && request.tripId!.trim().isNotEmpty) {
        return repo.getTripPhrasebook(
          request.tripId!,
          languageOverride: request.languageOrCountry.trim().isNotEmpty
              ? request.languageOrCountry.trim()
              : null,
        );
      }
      return repo.getPhrasebook(request.languageOrCountry);
    });
