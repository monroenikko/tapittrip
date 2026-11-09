import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/journal_repository.dart';
import '../../domain/models/journal_entry.dart';

class TripJournalNotifier extends AsyncNotifier<List<JournalEntry>> {
  TripJournalNotifier(this.tripId);
  final String tripId;

  @override
  Future<List<JournalEntry>> build() async {
    final repo = ref.watch(journalRepositoryProvider);
    return repo.getJournalEntries(tripId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(journalRepositoryProvider);
      return repo.getJournalEntries(tripId);
    });
  }

  Future<JournalEntry> createEntry({
    required String title,
    required String content,
    required String entryDate,
    String? locationName,
    String? weather,
    String? mood,
    bool isShared = false,
    String? itineraryItemId,
    List<String>? photos,
  }) async {
    final repo = ref.read(journalRepositoryProvider);
    final created = await repo.createJournalEntry(
      tripId,
      title: title,
      content: content,
      entryDate: entryDate,
      locationName: locationName,
      weather: weather,
      mood: mood,
      isShared: isShared,
      itineraryItemId: itineraryItemId,
      photos: photos,
    );

    final current = state.asData?.value ?? [];
    state = AsyncData([created, ...current]);
    return created;
  }

  Future<JournalEntry> updateEntry(
    String entryId, {
    String? title,
    String? content,
    String? entryDate,
    String? locationName,
    String? weather,
    String? mood,
    bool? isShared,
    String? itineraryItemId,
    List<String>? photos,
  }) async {
    final repo = ref.read(journalRepositoryProvider);
    final updated = await repo.updateJournalEntry(
      entryId,
      title: title,
      content: content,
      entryDate: entryDate,
      locationName: locationName,
      weather: weather,
      mood: mood,
      isShared: isShared,
      itineraryItemId: itineraryItemId,
      photos: photos,
    );

    final current = state.asData?.value ?? [];
    state = AsyncData(
      current.map((e) => e.id == entryId ? updated : e).toList(),
    );
    return updated;
  }

  Future<JournalEntry> toggleShare(JournalEntry entry) async {
    return updateEntry(entry.id, isShared: !entry.isShared);
  }

  Future<void> deleteEntry(String entryId) async {
    final repo = ref.read(journalRepositoryProvider);
    await repo.deleteJournalEntry(entryId);

    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((e) => e.id != entryId).toList());
  }

  Future<JournalEntry> uploadPhoto(
    String entryId, {
    required String fileName,
    required List<int> bytes,
  }) async {
    final repo = ref.read(journalRepositoryProvider);
    final updated = await repo.uploadPhoto(
      entryId,
      fileName: fileName,
      bytes: bytes,
    );

    final current = state.asData?.value ?? [];
    state = AsyncData(
      current.map((e) => e.id == entryId ? updated : e).toList(),
    );
    return updated;
  }
}

final tripJournalProvider =
    AsyncNotifierProvider.family<
      TripJournalNotifier,
      List<JournalEntry>,
      String
    >((tripId) => TripJournalNotifier(tripId));
