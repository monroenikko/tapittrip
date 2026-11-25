import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/travel_document_repository.dart';
import '../../domain/models/travel_document.dart';

final travelDocumentRepositoryProvider = Provider<TravelDocumentRepository>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return TravelDocumentRepository(apiClient: apiClient);
});

final tripDocumentsProvider =
    FutureProvider.family<List<TravelDocument>, String>((ref, tripId) async {
      final repo = ref.watch(travelDocumentRepositoryProvider);
      return repo.listDocuments(tripId);
    });
