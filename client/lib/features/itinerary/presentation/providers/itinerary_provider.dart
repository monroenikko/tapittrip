import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../sync/domain/models/outbox_operation.dart';
import '../../../sync/presentation/providers/sync_provider.dart';
import '../../../sync/services/sync_service.dart';
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
    final existing = state.asData?.value
        .where((it) => it.id == itemId)
        .firstOrNull;
    final baseVersion = existing?.version ?? 1;
    final payload = <String, dynamic>{
      'title': ?title,
      'kind': ?kind,
      'trip_day_id': ?tripDayId,
      'notes': ?notes,
      'status': ?status,
    };

    try {
      await _repository.updateItem(
        itemId,
        title: title,
        kind: kind,
        tripDayId: tripDayId,
        placeId: placeId,
        inlinePlace: inlinePlace,
        status: status,
        notes: notes,
        baseVersion: existing?.version,
      );
      await refresh();
    } on ConflictException catch (e) {
      await _recordOutboxOperation(
        OutboxOperation(
          operationId: SyncService.generateUuid(),
          tripId: tripId,
          entityType: 'itinerary_item',
          entityId: itemId,
          operationType: 'update',
          baseVersion: baseVersion,
          payload: payload,
          status: 'conflict',
          conflictDetails: e.details,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      await refresh();
      rethrow;
    } on NetworkException {
      if (existing != null) {
        final updatedLocal = existing.copyWith(
          title: title,
          kind: kind,
          tripDayId: tripDayId,
          notes: notes,
          status: status,
        );
        final list = [
          for (final item in state.asData?.value ?? const <ItineraryItem>[])
            item.id == itemId ? updatedLocal : item,
        ];
        state = AsyncValue.data(list);
        await _repository.cacheItems(tripId, list);
      }
      await _recordOutboxOperation(
        OutboxOperation(
          operationId: SyncService.generateUuid(),
          tripId: tripId,
          entityType: 'itinerary_item',
          entityId: itemId,
          operationType: 'update',
          baseVersion: baseVersion,
          payload: payload,
          status: 'pending',
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  Future<void> toggleVisited(ItineraryItem item) async {
    final newStatus = item.status == 'visited' ? 'planned' : 'visited';
    await updateItem(item.id, status: newStatus);
  }

  Future<void> deleteItem(String itemId) async {
    final existing = state.asData?.value
        .where((it) => it.id == itemId)
        .firstOrNull;
    try {
      await _repository.deleteItem(itemId);
      await refresh();
    } on NetworkException {
      final list = (state.asData?.value ?? const <ItineraryItem>[])
          .where((it) => it.id != itemId)
          .toList();
      state = AsyncValue.data(list);
      await _repository.cacheItems(tripId, list);
      await _recordOutboxOperation(
        OutboxOperation(
          operationId: SyncService.generateUuid(),
          tripId: tripId,
          entityType: 'itinerary_item',
          entityId: itemId,
          operationType: 'delete',
          baseVersion: existing?.version ?? 1,
          status: 'pending',
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  /// Reorder a flat list using ReorderableList.onReorderItem indices (newIndex already adjusted).
  Future<bool> reorder(int oldIndex, int newIndex) async {
    final current = state.value;
    if (current == null || current.isEmpty) return false;

    final items = List<ItineraryItem>.from(current);
    final boundedOld = oldIndex.clamp(0, items.length - 1);
    final boundedNew = newIndex.clamp(0, items.length - 1);
    final item = items.removeAt(boundedOld);
    items.insert(boundedNew, item);

    return applyReorderedItems(items);
  }

  /// Persist a complete reordered item list and optional day assignments.
  Future<bool> applyReorderedItems(
    List<ItineraryItem> reorderedItems, {
    Map<String, String?>? dayAssignments,
  }) async {
    if (reorderedItems.isEmpty) return true;

    final expectedVersions = <String, int>{
      for (final item in reorderedItems) item.id: item.version,
    };

    final normalized = [
      for (var i = 0; i < reorderedItems.length; i++)
        reorderedItems[i].copyWith(sortOrder: i),
    ];

    // Optimistically update local state immediately for zero-latency drag & drop
    state = AsyncValue.data(normalized);

    final orderedIds = normalized.map((e) => e.id).toList();

    try {
      final updated = await _repository.reorderItems(
        tripId,
        orderedIds,
        dayAssignments: dayAssignments,
        expectedVersions: expectedVersions,
      );
      if (updated.isNotEmpty) {
        final byId = {for (final item in updated) item.id: item};
        final merged = [for (final item in normalized) byId[item.id] ?? item];
        state = AsyncValue.data(merged);
      }
      return true;
    } on ConflictException catch (e) {
      final conflictEntityId =
          e.serverPayload['id']?.toString() ?? orderedIds.first;
      final conflictIndex = orderedIds.indexOf(conflictEntityId);
      await _recordOutboxOperation(
        OutboxOperation(
          operationId: SyncService.generateUuid(),
          tripId: tripId,
          entityType: 'itinerary_item',
          entityId: conflictEntityId,
          operationType: 'update',
          baseVersion: expectedVersions[conflictEntityId] ?? 1,
          payload: {
            'sort_order': conflictIndex >= 0 ? conflictIndex : 0,
            if (dayAssignments != null &&
                dayAssignments.containsKey(conflictEntityId))
              'trip_day_id': dayAssignments[conflictEntityId],
          },
          status: 'conflict',
          conflictDetails: e.details,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      await refresh();
      return false;
    } on NetworkException {
      await _repository.cacheItems(tripId, normalized);
      for (var i = 0; i < normalized.length; i++) {
        final item = normalized[i];
        await _recordOutboxOperation(
          OutboxOperation(
            operationId: SyncService.generateUuid(),
            tripId: tripId,
            entityType: 'itinerary_item',
            entityId: item.id,
            operationType: 'update',
            baseVersion: item.version,
            payload: {
              'sort_order': i,
              if (dayAssignments != null && dayAssignments.containsKey(item.id))
                'trip_day_id': dayAssignments[item.id],
            },
            status: 'pending',
            createdAt: DateTime.now().toUtc(),
          ),
        );
      }
      return true;
    } catch (_) {
      await refresh();
      return false;
    }
  }

  Future<void> _recordOutboxOperation(OutboxOperation operation) async {
    try {
      await SyncService.saveWithChainedVersion(
        ref.read(outboxStorageProvider),
        operation,
      );
      await ref.read(syncProvider.notifier).refresh();
    } catch (_) {}
  }

  /// Move a single activity to an exact ordinal index (0-based) within a target day.
  Future<bool> moveItemToOrdinal({
    required ItineraryItem item,
    required String? targetDayId,
    required int targetOrdinalIndex,
    List<TripDay> knownDays = const [],
  }) async {
    final current = state.value;
    if (current == null) return false;

    final remaining = current.where((e) => e.id != item.id).toList();
    TripDay? targetDay;
    if (targetDayId != null) {
      for (final d in knownDays) {
        if (d.id == targetDayId) {
          targetDay = d;
          break;
        }
      }
    }

    final updatedItem = item.copyWith(
      tripDayId: targetDayId,
      clearTripDay: targetDayId == null,
      day: targetDay,
    );

    final List<ItineraryItem> reordered;
    if (knownDays.isEmpty) {
      final list = List<ItineraryItem>.from(remaining);
      final clamped = targetOrdinalIndex.clamp(0, list.length);
      list.insert(clamped, updatedItem);
      reordered = list;
    } else {
      final buckets = <String?, List<ItineraryItem>>{
        for (final d in knownDays) d.id: [],
        null: [],
      };

      for (final entry in remaining) {
        final key =
            entry.tripDayId != null && buckets.containsKey(entry.tripDayId)
            ? entry.tripDayId
            : null;
        buckets[key]!.add(entry);
      }

      final targetKey = targetDayId != null && buckets.containsKey(targetDayId)
          ? targetDayId
          : null;
      final targetBucket = buckets[targetKey]!;
      final clamped = targetOrdinalIndex.clamp(0, targetBucket.length);
      targetBucket.insert(clamped, updatedItem);

      reordered = [
        for (final d in knownDays) ...buckets[d.id]!,
        ...buckets[null]!,
      ];
    }

    final dayAssignments = <String, String?>{};
    if (item.tripDayId != updatedItem.tripDayId) {
      dayAssignments[item.id] = updatedItem.tripDayId;
    }

    return applyReorderedItems(
      reordered,
      dayAssignments: dayAssignments.isNotEmpty ? dayAssignments : null,
    );
  }

  /// Toggle a Trip Circle member vote ('up' or 'down') on an itinerary item.
  Future<void> toggleVote(ItineraryItem item, String direction) async {
    final targetVote = item.viewerVote == direction ? 'none' : direction;
    try {
      final updated = await _repository.voteItem(item.id, vote: targetVote);
      final current = state.asData?.value ?? const <ItineraryItem>[];
      final list = [
        for (final entry in current) entry.id == item.id ? updated : entry,
      ];
      state = AsyncValue.data(list);
      await _repository.cacheItems(tripId, list);
    } catch (_) {
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
