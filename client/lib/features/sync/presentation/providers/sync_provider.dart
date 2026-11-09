import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../lounges/presentation/providers/lounge_provider.dart';
import '../../data/outbox_storage.dart';
import '../../domain/models/outbox_operation.dart';
import '../../services/sync_service.dart';

enum SyncStatus { synced, pending, syncing, conflict, offline }

class SyncState {
  const SyncState({
    this.status = SyncStatus.synced,
    this.pendingCount = 0,
    this.conflictCount = 0,
    this.lastSyncedAt,
    this.errorMessage,
    this.conflicts = const [],
  });

  final SyncStatus status;
  final int pendingCount;
  final int conflictCount;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final List<OutboxOperation> conflicts;

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    int? conflictCount,
    DateTime? lastSyncedAt,
    String? errorMessage,
    List<OutboxOperation>? conflicts,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      conflictCount: conflictCount ?? this.conflictCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      conflicts: conflicts ?? this.conflicts,
    );
  }
}

final outboxStorageProvider = Provider<OutboxStorage>((ref) {
  return const SecureOutboxStorage();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final outboxStorage = ref.watch(outboxStorageProvider);
  final loungeRepo = ref.watch(loungeRepositoryProvider);
  return SyncService(
    apiClient: apiClient,
    outboxStorage: outboxStorage,
    loungeRepository: loungeRepo,
  );
});

class SyncNotifier extends Notifier<SyncState> {
  late final SyncService _syncService;
  late final OutboxStorage _outboxStorage;

  @override
  SyncState build() {
    _syncService = ref.watch(syncServiceProvider);
    _outboxStorage = ref.watch(outboxStorageProvider);

    // Initial check of outbox count
    _initCheck();

    return const SyncState();
  }

  Future<void> _initCheck() async {
    await refresh();
  }

  Future<void> refresh() async {
    final operations = await _outboxStorage.getPendingOperations();
    final conflicts = operations
        .where((op) => op.status == 'conflict')
        .toList();
    final pending = operations.where((op) => op.status == 'pending').toList();

    final status = conflicts.isNotEmpty
        ? SyncStatus.conflict
        : pending.isNotEmpty
        ? SyncStatus.pending
        : SyncStatus.synced;

    state = state.copyWith(
      status: status,
      pendingCount: pending.length,
      conflictCount: conflicts.length,
      conflicts: conflicts,
    );
  }

  Future<void> sync({String? tripId}) async {
    state = state.copyWith(status: SyncStatus.syncing);

    try {
      await _syncService.syncAll(tripId: tripId);
      final operations = await _outboxStorage.getPendingOperations();
      final conflicts = operations
          .where((op) => op.status == 'conflict')
          .toList();
      final pending = operations.where((op) => op.status == 'pending').toList();

      final status = conflicts.isNotEmpty
          ? SyncStatus.conflict
          : pending.isNotEmpty
          ? SyncStatus.pending
          : SyncStatus.synced;

      state = state.copyWith(
        status: status,
        pendingCount: pending.length,
        conflictCount: conflicts.length,
        conflicts: conflicts,
        lastSyncedAt: DateTime.now(),
        errorMessage: null,
      );
    } catch (e) {
      final operations = await _outboxStorage.getPendingOperations();
      final conflicts = operations
          .where((op) => op.status == 'conflict')
          .toList();
      final pending = operations.where((op) => op.status == 'pending').toList();

      state = state.copyWith(
        status: conflicts.isNotEmpty ? SyncStatus.conflict : SyncStatus.offline,
        pendingCount: pending.length,
        conflictCount: conflicts.length,
        conflicts: conflicts,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> resolveConflict(
    String operationId, {
    required bool keepLocal,
  }) async {
    try {
      await _syncService.resolveConflict(operationId, keepLocal: keepLocal);
      await refresh();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);
