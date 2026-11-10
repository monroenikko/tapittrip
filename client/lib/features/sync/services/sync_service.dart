import 'dart:math';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../lounges/data/lounge_repository.dart';
import '../data/outbox_storage.dart';
import '../domain/models/outbox_operation.dart';
import '../domain/models/sync_result.dart';

class SyncAllSummary {
  const SyncAllSummary({
    required this.pushedCount,
    required this.pulledCount,
    required this.conflictCount,
    required this.newCursor,
    this.rejectedCount = 0,
  });

  final int pushedCount;
  final int pulledCount;
  final int conflictCount;
  final int newCursor;
  final int rejectedCount;
}

class SyncService {
  SyncService({
    required this.apiClient,
    required this.outboxStorage,
    this.loungeRepository,
    this.onTripAccessRevoked,
    String? deviceKey,
  }) : deviceKey = deviceKey ?? _generateDeviceKey();

  final ApiClient apiClient;
  final OutboxStorage outboxStorage;
  final LoungeRepository? loungeRepository;
  final Future<void> Function(String tripId)? onTripAccessRevoked;
  final String deviceKey;

  dynamic _extractData(dynamic response) {
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return response['data'];
    }
    return response;
  }

  static String _generateDeviceKey() {
    final rand = Random();
    return 'device_${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(999999)}';
  }

  /// Queues a local offline mutation to the durable outbox.
  Future<OutboxOperation> queueMutation({
    String? tripId,
    required String entityType,
    required String entityId,
    required String operationType,
    Map<String, dynamic>? payload,
    int baseVersion = 1,
  }) async {
    final operationId = generateUuid();
    final operation = OutboxOperation(
      operationId: operationId,
      tripId: tripId,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      payload: payload,
      baseVersion: baseVersion,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await outboxStorage.saveOperation(operation);
    return operation;
  }

  /// Pushes all pending outbox operations to the server.
  Future<List<SyncOperationResult>> pushPending() async {
    final pending = await outboxStorage.getPendingOperations();
    final toSend = pending.where((op) => op.status == 'pending').toList();

    if (toSend.isEmpty) return [];

    final payload = {
      'device_key': deviceKey,
      'operations': toSend.map((op) => op.toJson()).toList(),
    };

    final response = await apiClient.post('/sync/push', data: payload);
    final data = _extractData(response) as Map<String, dynamic>;
    final rawResults = (data['results'] as List<dynamic>? ?? [])
        .map(
          (e) =>
              SyncOperationResult.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    for (final result in rawResults) {
      if (result.status == 'accepted') {
        await outboxStorage.removeOperation(result.operationId);
      } else if (result.status == 'conflict') {
        final existing = toSend.firstWhere(
          (op) => op.operationId == result.operationId,
          orElse: () => toSend.first,
        );
        await outboxStorage.updateOperation(
          existing.copyWith(
            status: 'conflict',
            conflictDetails: result.conflictDetails,
          ),
        );
      } else if (result.status == 'rejected') {
        final existing = toSend.firstWhere(
          (op) => op.operationId == result.operationId,
          orElse: () => toSend.first,
        );
        await outboxStorage.updateOperation(
          existing.copyWith(
            status: 'rejected',
            conflictDetails: result.conflictDetails,
          ),
        );
        final reason =
            result.conflictDetails?['reason']?.toString().toLowerCase() ?? '';
        if (existing.tripId != null &&
            (reason.contains('forbidden') ||
                reason.contains('not a member') ||
                reason.contains('not authorized'))) {
          await onTripAccessRevoked?.call(existing.tripId!);
        }
      }
    }

    return rawResults;
  }

  Future<void> dismissRejectedOperation(String operationId) async {
    await outboxStorage.removeOperation(operationId);
  }

  /// Pulls recent mutations from the server using monotonic cursors.
  Future<PullResult> pullLatest({String? tripId, int limit = 50}) async {
    final cursor = await outboxStorage.getCursor(tripId);
    final queryParams = <String, dynamic>{
      'device_key': deviceKey,
      'cursor': cursor,
      'limit': limit,
    };
    if (tripId != null) {
      queryParams['trip_id'] = tripId;
    }

    final dynamic response;
    try {
      response = await apiClient.get(
        '/sync/pull',
        queryParameters: queryParams,
      );
    } on ApiException catch (e) {
      if (tripId != null && (e.statusCode == 403 || e.code == 'forbidden')) {
        await onTripAccessRevoked?.call(tripId);
      }
      rethrow;
    }
    final data = _extractData(response) as Map<String, dynamic>;
    final pullResult = PullResult.fromJson(data);

    if (pullResult.cursor > cursor) {
      await outboxStorage.saveCursor(pullResult.cursor, tripId);
    }

    return pullResult;
  }

  /// Pushes local outbox and then pulls remote updates.
  Future<SyncAllSummary> syncAll({String? tripId}) async {
    final pushResults = await pushPending();
    final conflictCount = pushResults
        .where((r) => r.status == 'conflict')
        .length;
    final rejectedCount = pushResults
        .where((r) => r.status == 'rejected')
        .length;
    final acceptedCount = pushResults
        .where((r) => r.status == 'accepted')
        .length;

    final pullResult = await pullLatest(tripId: tripId);

    // Proactively pre-fetch and cache hub airport lounge directory in background
    if (loungeRepository != null) {
      loungeRepository!.prefetchAirports(const [
        'MNL',
        'HND',
        'NRT',
        'SIN',
        'BKK',
        'ICN',
        'KIX',
        'DPS',
        'SFO',
        'LAX',
      ]);
    }

    return SyncAllSummary(
      pushedCount: acceptedCount,
      pulledCount: pullResult.operations.length,
      conflictCount: conflictCount,
      newCursor: pullResult.cursor,
      rejectedCount: rejectedCount,
    );
  }

  /// Resolves an existing conflict by either adopting server version or re-applying local edit.
  Future<void> resolveConflict(
    String operationId, {
    required bool keepLocal,
  }) async {
    final all = await outboxStorage.getAllOperations();
    final operation = all.firstWhere((op) => op.operationId == operationId);

    if (keepLocal) {
      final serverVersion =
          (operation.conflictDetails?['server_version'] as num?)?.toInt() ??
          (operation.baseVersion + 1);

      final updated = operation.copyWith(
        baseVersion: serverVersion,
        status: 'pending',
        conflictDetails: null,
      );
      await outboxStorage.updateOperation(updated);
      await pushPending();
    } else {
      // Discard local edit
      await outboxStorage.removeOperation(operationId);
    }
  }

  static String generateUuid() {
    final rand = Random();
    String hex(int length) =>
        List.generate(length, (_) => rand.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
  }
}
