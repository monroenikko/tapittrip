import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/booking_import_repository.dart';
import '../../domain/models/booking_import.dart';

final bookingImportRepositoryProvider = Provider<BookingImportRepository>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingImportRepository(apiClient: apiClient);
});

final tripBookingImportsProvider =
    FutureProvider.family<List<BookingImport>, String>((ref, tripId) async {
      final repo = ref.watch(bookingImportRepositoryProvider);
      return repo.listImports(tripId);
    });
