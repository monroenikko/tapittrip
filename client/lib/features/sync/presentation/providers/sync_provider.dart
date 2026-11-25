import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../circles/data/trip_circle_repository.dart';
import '../../../flights/presentation/providers/flight_provider.dart';
import '../../../lounges/presentation/providers/lounge_provider.dart';
import '../../data/outbox_storage.dart';
import '../../domain/models/outbox_operation.dart';
import '../../services/sync_service.dart';

enum SyncStatus { synced, pending, syncing, conflict, rejected, offline }

class SyncState {
  const SyncState({
    this.status = SyncStatus.synced,
    this.pendingCount = 0,
    this.conflictCount = 0,
    this.rejectedCount = 0,
    this.lastSyncedAt,
    this.errorMessage,
    this.conflicts = const [],
    this.rejectedOperations = const [],
  });

  final SyncStatus status;
  final int pendingCount;
  final int conflictCount;
  final int rejectedCount;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final List<OutboxOperation> conflicts;
  final List<OutboxOperation> rejectedOperations;

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    int? conflictCount,
    int? rejectedCount,
    DateTime? lastSyncedAt,
    String? errorMessage,
    List<OutboxOperation>? conflicts,
    List<OutboxOperation>? rejectedOperations,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      conflictCount: conflictCount ?? this.conflictCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      conflicts: conflicts ?? this.conflicts,
      rejectedOperations: rejectedOperations ?? this.rejectedOperations,
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
  final flightRepo = ref.watch(flightRepositoryProvider);
  final circleRepo = ref.watch(tripCircleRepositoryProvider);
  return SyncService(
    apiClient: apiClient,
    outboxStorage: outboxStorage,
    loungeRepository: loungeRepo,
    flightRepository: flightRepo,
    onTripAccessRevoked: (tripId) => circleRepo.purgeTripCircleCaches(tripId),
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
    final operations = await _outboxStorage.getAllOperations();
    final conflicts = operations
        .where((op) => op.status == 'conflict')
        .toList();
    final rejected = operations.where((op) => op.status == 'rejected').toList();
    final pending = operations.where((op) => op.status == 'pending').toList();

    final status = conflicts.isNotEmpty
        ? SyncStatus.conflict
        : rejected.isNotEmpty
        ? SyncStatus.rejected
        : pending.isNotEmpty
        ? SyncStatus.pending
        : SyncStatus.synced;

    state = state.copyWith(
      status: status,
      pendingCount: pending.length,
      conflictCount: conflicts.length,
      rejectedCount: rejected.length,
      conflicts: conflicts,
      rejectedOperations: rejected,
    );
  }

  Future<void> sync({String? tripId}) async {
    state = state.copyWith(status: SyncStatus.syncing);

    try {
      await _syncService.syncAll(tripId: tripId);
      final operations = await _outboxStorage.getAllOperations();
      final conflicts = operations
          .where((op) => op.status == 'conflict')
          .toList();
      final rejected = operations
          .where((op) => op.status == 'rejected')
          .toList();
      final pending = operations.where((op) => op.status == 'pending').toList();

      final status = conflicts.isNotEmpty
          ? SyncStatus.conflict
          : rejected.isNotEmpty
          ? SyncStatus.rejected
          : pending.isNotEmpty
          ? SyncStatus.pending
          : SyncStatus.synced;

      state = state.copyWith(
        status: status,
        pendingCount: pending.length,
        conflictCount: conflicts.length,
        rejectedCount: rejected.length,
        conflicts: conflicts,
        rejectedOperations: rejected,
        lastSyncedAt: DateTime.now(),
        errorMessage: null,
      );
    } catch (e) {
      final operations = await _outboxStorage.getAllOperations();
      final conflicts = operations
          .where((op) => op.status == 'conflict')
          .toList();
      final rejected = operations
          .where((op) => op.status == 'rejected')
          .toList();
      final pending = operations.where((op) => op.status == 'pending').toList();

      state = state.copyWith(
        status: conflicts.isNotEmpty
            ? SyncStatus.conflict
            : rejected.isNotEmpty
            ? SyncStatus.rejected
            : SyncStatus.offline,
        pendingCount: pending.length,
        conflictCount: conflicts.length,
        rejectedCount: rejected.length,
        conflicts: conflicts,
        rejectedOperations: rejected,
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
      try {
        await refresh();
      } catch (_) {}
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> dismissRejected(String operationId) async {
    await _syncService.dismissRejectedOperation(operationId);
    await refresh();
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);
