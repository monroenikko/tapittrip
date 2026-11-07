import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/checklist_repository.dart';
import '../../domain/models/checklist.dart';
import '../../domain/models/checklist_item.dart';
import '../../domain/models/media_attachment.dart';

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChecklistRepository(apiClient: apiClient);
});

class ChecklistListNotifier extends AsyncNotifier<List<Checklist>> {
  ChecklistListNotifier(this.tripId);

  final String tripId;
  late final ChecklistRepository _repository;

  @override
  Future<List<Checklist>> build() async {
    _repository = ref.watch(checklistRepositoryProvider);
    return _repository.fetchChecklists(tripId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchChecklists(tripId));
  }

  Future<Checklist> createChecklist({
    required String title,
    String type = 'packing',
    String? description,
  }) async {
    final checklist = await _repository.createChecklist(
      tripId,
      title: title,
      type: type,
      description: description,
    );

    final current = state.asData?.value ?? [];
    state = AsyncValue.data([...current, checklist]);
    return checklist;
  }

  Future<Checklist> applyTemplate(String template) async {
    final checklist = await _repository.applyTemplate(
      tripId,
      template: template,
    );

    await refresh();
    return checklist;
  }

  Future<void> deleteChecklist(String checklistId) async {
    final previous = state.asData?.value ?? [];
    state = AsyncValue.data(
      previous.where((c) => c.id != checklistId).toList(),
    );

    try {
      await _repository.deleteChecklist(checklistId);
    } catch (_) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<ChecklistItem> addItem({
    required String checklistId,
    required String title,
    String category = 'other',
    int quantity = 1,
    String? notes,
    String? photoUrl,
  }) async {
    final item = await _repository.addItem(
      checklistId,
      title: title,
      category: category,
      quantity: quantity,
      notes: notes,
      photoUrl: photoUrl,
    );

    final current = state.asData?.value ?? [];
    state = AsyncValue.data(
      current.map((c) {
        if (c.id == checklistId) {
          final updatedItems = [...c.items, item];
          final total = updatedItems.length;
          final packed = updatedItems.where((i) => i.isPacked).length;
          final progress = total > 0 ? ((packed / total) * 100).round() : 0;

          return c.copyWith(
            items: updatedItems,
            totalItemsCount: total,
            packedItemsCount: packed,
            progressPercentage: progress,
          );
        }
        return c;
      }).toList(),
    );

    return item;
  }

  Future<void> toggleItem(String itemId) async {
    final previous = state.asData?.value ?? [];

    // Optimistic instant toggle in local state for zero latency UI feedback
    state = AsyncValue.data(
      previous.map((checklist) {
        final itemIndex = checklist.items.indexWhere((i) => i.id == itemId);
        if (itemIndex == -1) return checklist;

        final targetItem = checklist.items[itemIndex];
        final toggledItem = targetItem.copyWith(
          isPacked: !targetItem.isPacked,
          packedAt: !targetItem.isPacked ? DateTime.now() : null,
          version: targetItem.version + 1,
        );

        final newItems = List<ChecklistItem>.from(checklist.items);
        newItems[itemIndex] = toggledItem;

        final total = newItems.length;
        final packed = newItems.where((i) => i.isPacked).length;
        final progress = total > 0 ? ((packed / total) * 100).round() : 0;

        return checklist.copyWith(
          items: newItems,
          totalItemsCount: total,
          packedItemsCount: packed,
          progressPercentage: progress,
        );
      }).toList(),
    );

    try {
      final updated = await _repository.toggleItem(itemId);

      // Reconcile with server response
      final current = state.asData?.value ?? [];
      state = AsyncValue.data(
        current.map((checklist) {
          final itemIndex = checklist.items.indexWhere((i) => i.id == itemId);
          if (itemIndex == -1) return checklist;

          final newItems = List<ChecklistItem>.from(checklist.items);
          newItems[itemIndex] = updated;

          final total = newItems.length;
          final packed = newItems.where((i) => i.isPacked).length;
          final progress = total > 0 ? ((packed / total) * 100).round() : 0;

          return checklist.copyWith(
            items: newItems,
            totalItemsCount: total,
            packedItemsCount: packed,
            progressPercentage: progress,
          );
        }).toList(),
      );
    } catch (_) {
      // Revert if request failed
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<void> updateItem({
    required String itemId,
    String? title,
    String? category,
    int? quantity,
    String? notes,
    String? photoUrl,
    bool? isPacked,
  }) async {
    final updated = await _repository.updateItem(
      itemId,
      title: title,
      category: category,
      quantity: quantity,
      notes: notes,
      photoUrl: photoUrl,
      isPacked: isPacked,
    );

    final current = state.asData?.value ?? [];
    state = AsyncValue.data(
      current.map((checklist) {
        final itemIndex = checklist.items.indexWhere((i) => i.id == itemId);
        if (itemIndex == -1) return checklist;

        final newItems = List<ChecklistItem>.from(checklist.items);
        newItems[itemIndex] = updated;

        final total = newItems.length;
        final packed = newItems.where((i) => i.isPacked).length;
        final progress = total > 0 ? ((packed / total) * 100).round() : 0;

        return checklist.copyWith(
          items: newItems,
          totalItemsCount: total,
          packedItemsCount: packed,
          progressPercentage: progress,
        );
      }).toList(),
    );
  }

  Future<void> deleteItem(String itemId) async {
    final previous = state.asData?.value ?? [];

    state = AsyncValue.data(
      previous.map((checklist) {
        final filteredItems = checklist.items
            .where((i) => i.id != itemId)
            .toList();
        final total = filteredItems.length;
        final packed = filteredItems.where((i) => i.isPacked).length;
        final progress = total > 0 ? ((packed / total) * 100).round() : 0;

        return checklist.copyWith(
          items: filteredItems,
          totalItemsCount: total,
          packedItemsCount: packed,
          progressPercentage: progress,
        );
      }).toList(),
    );

    try {
      await _repository.deleteItem(itemId);
    } catch (_) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<ChecklistItem> uploadItemPhoto({
    required String itemId,
    required String fileName,
    required List<int> bytes,
    String? title,
    String? notes,
  }) async {
    final updated = await _repository.uploadItemPhoto(
      itemId,
      fileName: fileName,
      bytes: bytes,
      title: title,
      notes: notes,
    );

    final current = state.asData?.value ?? [];
    state = AsyncValue.data(
      current.map((checklist) {
        final itemIndex = checklist.items.indexWhere((i) => i.id == itemId);
        if (itemIndex == -1) return checklist;

        final newItems = List<ChecklistItem>.from(checklist.items);
        newItems[itemIndex] = updated;

        return checklist.copyWith(items: newItems);
      }).toList(),
    );

    return updated;
  }
}

/// Checklists list provider parameterized by tripId.
final checklistListProvider =
    AsyncNotifierProvider.family<
      ChecklistListNotifier,
      List<Checklist>,
      String
    >((tripId) => ChecklistListNotifier(tripId));

/// Trip media attachments provider.
final tripMediaProvider = FutureProvider.family<List<MediaAttachment>, String>((
  ref,
  tripId,
) async {
  final repository = ref.watch(checklistRepositoryProvider);
  return repository.fetchTripMedia(tripId);
});
