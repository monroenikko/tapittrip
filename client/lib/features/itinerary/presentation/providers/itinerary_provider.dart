import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/itinerary_repository.dart';
import '../../domain/models/itinerary_item.dart';
import '../../domain/models/trip_day.dart';

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ItineraryRepository(apiClient: apiClient);
});

/// Scoped provider for the active trip ID on itinerary screens.
final currentTripIdProvider = Provider<String>((ref) {
  throw UnimplementedError(
    'currentTripIdProvider must be provided via ProviderScope',
  );
});

final tripDaysProvider = FutureProvider<List<TripDay>>((ref) async {
  final tripId = ref.watch(currentTripIdProvider);
  final repository = ref.watch(itineraryRepositoryProvider);
  return repository.fetchDays(tripId);
});

class ItineraryListNotifier extends AsyncNotifier<List<ItineraryItem>> {
  late final ItineraryRepository _repository;
  late final String _tripId;

  @override
  Future<List<ItineraryItem>> build() async {
    _repository = ref.watch(itineraryRepositoryProvider);
    _tripId = ref.watch(currentTripIdProvider);
    return _repository.fetchItems(_tripId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchItems(_tripId));
  }

  Future<void> addItem({
    required String title,
    String kind = 'attraction',
    String? tripDayId,
    String? placeId,
    Map<String, dynamic>? inlinePlace,
    String? notes,
    String? startsAtUtc,
    String? endsAtUtc,
  }) async {
    await _repository.createItem(
      _tripId,
      title: title,
      kind: kind,
      tripDayId: tripDayId,
      placeId: placeId,
      inlinePlace: inlinePlace,
      notes: notes,
      startsAtUtc: startsAtUtc,
      endsAtUtc: endsAtUtc,
    );
    await refresh();
  }

  Future<void> updateItem(
    String itemId, {
    String? title,
    String? kind,
    String? status,
    String? notes,
  }) async {
    await _repository.updateItem(
      itemId,
      title: title,
      kind: kind,
      status: status,
      notes: notes,
    );
    await refresh();
  }

  Future<void> toggleVisited(ItineraryItem item) async {
    final newStatus = item.status == 'visited' ? 'planned' : 'visited';
    await updateItem(item.id, status: newStatus);
  }

  Future<void> deleteItem(String itemId) async {
    await _repository.deleteItem(itemId);
    await refresh();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state.value;
    if (current == null) return;

    final items = List<ItineraryItem>.from(current);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // Optimistically update local state immediately
    state = AsyncValue.data(items);

    final orderedIds = items.map((e) => e.id).toList();

    try {
      final updated = await _repository.reorderItems(_tripId, orderedIds);
      state = AsyncValue.data(updated);
    } catch (_) {
      // Revert if network failed
      await refresh();
    }
  }
}

final itineraryListProvider =
    AsyncNotifierProvider<ItineraryListNotifier, List<ItineraryItem>>(
      ItineraryListNotifier.new,
    );
