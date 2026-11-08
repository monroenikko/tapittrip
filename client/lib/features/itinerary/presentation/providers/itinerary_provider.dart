import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/ai_itinerary_repository.dart';
import '../../data/itinerary_repository.dart';
import '../../domain/models/itinerary_item.dart';
import '../../domain/models/trip_day.dart';

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ItineraryRepository(apiClient: apiClient);
});

final aiItineraryRepositoryProvider = Provider<AiItineraryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AiItineraryRepository(apiClient: apiClient);
});

/// Trip days provider parametrized by tripId.
final tripDaysProvider = FutureProvider.family<List<TripDay>, String>((
  ref,
  tripId,
) async {
  final repository = ref.watch(itineraryRepositoryProvider);
  return repository.fetchDays(tripId);
});

class ItineraryListNotifier extends AsyncNotifier<List<ItineraryItem>> {
  ItineraryListNotifier(this.tripId);

  final String tripId;
  late final ItineraryRepository _repository;

  @override
  Future<List<ItineraryItem>> build() async {
    _repository = ref.watch(itineraryRepositoryProvider);
    return _repository.fetchItems(tripId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchItems(tripId));
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
      tripId,
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
    String? tripDayId,
    String? placeId,
    Map<String, dynamic>? inlinePlace,
    String? status,
    String? notes,
  }) async {
    await _repository.updateItem(
      itemId,
      title: title,
      kind: kind,
      tripDayId: tripDayId,
      placeId: placeId,
      inlinePlace: inlinePlace,
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
      final updated = await _repository.reorderItems(tripId, orderedIds);
      state = AsyncValue.data(updated);
    } catch (_) {
      // Revert if network failed
      await refresh();
    }
  }
}

/// Itinerary items provider parametrized by tripId.
final itineraryListProvider =
    AsyncNotifierProvider.family<
      ItineraryListNotifier,
      List<ItineraryItem>,
      String
    >((tripId) => ItineraryListNotifier(tripId));
