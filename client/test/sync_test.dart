import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/features/stays/data/stay_repository.dart';
import 'package:tapittrip/features/stays/domain/models/stay.dart';
import 'package:tapittrip/features/stays/presentation/providers/stay_provider.dart';
import 'package:tapittrip/features/sync/data/outbox_storage.dart';
import 'package:tapittrip/features/sync/domain/models/outbox_operation.dart';
import 'package:tapittrip/features/sync/presentation/providers/sync_provider.dart';
import 'package:tapittrip/features/sync/presentation/widgets/conflict_resolution_dialog.dart';
import 'package:tapittrip/features/sync/presentation/widgets/sync_status_indicator.dart';
import 'package:tapittrip/features/sync/services/sync_service.dart';

class FakeSyncApiClient extends ApiClient {
  FakeSyncApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic getResponse;
  dynamic postResponse;
  Future<dynamic> Function(String path, Map<String, dynamic>? data)? onPost;
  Map<String, dynamic>? lastPostData;
  Map<String, dynamic>? lastGetParams;

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPostData = data as Map<String, dynamic>?;
    if (onPost != null) {
      return onPost!(path, lastPostData);
    }
    return postResponse ??
        {
          'data': {
            'results': [
              {
                'operation_id':
                    (data?['operations'] as List?)?.first?['operation_id'] ??
                    'op-1',
                'status': 'accepted',
                'server_sequence': 101,
                'current_version': 2,
              },
            ],
          },
        };
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastGetParams = queryParameters;
    return getResponse ??
        {
          'data': {
            'cursor': 105,
            'operations': [
              {
                'id': 'sync-op-1',
                'operation_id': 'op-remote-1',
                'trip_id': 'trip-123',
                'entity_type': 'checklist_item',
                'entity_id': 'item-123',
                'operation_type': 'update',
                'payload': {'title': 'Passport', 'is_packed': true},
                'base_version': 1,
                'server_sequence': 105,
                'created_at': DateTime.now().toIso8601String(),
              },
            ],
            'has_more': false,
          },
        };
  }
}

void main() {
  group('OutboxStorage', () {
    test('persists operations, filters pending, and advances cursor', () async {
      final storage = InMemoryOutboxStorage();

      final op1 = OutboxOperation(
        operationId: 'op-1',
        tripId: 'trip-1',
        entityType: 'checklist_item',
        entityId: 'item-1',
        operationType: 'update',
        payload: {'is_packed': true},
        baseVersion: 1,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final op2 = OutboxOperation(
        operationId: 'op-2',
        tripId: 'trip-1',
        entityType: 'stay',
        entityId: 'stay-1',
        operationType: 'update',
        payload: {'name': 'Hotel A'},
        baseVersion: 1,
        status: 'synced',
        createdAt: DateTime.now(),
      );

      await storage.saveOperation(op1);
      await storage.saveOperation(op2);

      final all = await storage.getAllOperations();
      expect(all.length, 2);

      final pending = await storage.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.operationId, 'op-1');

      // Cursor persistence
      expect(await storage.getCursor('trip-1'), 0);
      await storage.saveCursor(42, 'trip-1');
      expect(await storage.getCursor('trip-1'), 42);

      // Remove operation
      await storage.removeOperation('op-1');
      final remaining = await storage.getPendingOperations();
      expect(remaining.isEmpty, true);
    });
  });

  group('SyncService', () {
    late FakeSyncApiClient fakeClient;
    late InMemoryOutboxStorage storage;
    late SyncService syncService;

    setUp(() {
      fakeClient = FakeSyncApiClient();
      storage = InMemoryOutboxStorage();
      syncService = SyncService(
        apiClient: fakeClient,
        outboxStorage: storage,
        deviceKey: 'test-device-uuid',
      );
    });

    test('queueMutation creates pending operation in durable outbox', () async {
      final op = await syncService.queueMutation(
        tripId: 'trip-1',
        entityType: 'checklist_item',
        entityId: 'item-1',
        operationType: 'update',
        payload: {'is_packed': true},
        baseVersion: 1,
      );

      expect(op.status, 'pending');
      expect(op.baseVersion, 1);
      final pending = await storage.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.operationId, op.operationId);
    });

    test('pushPending removes accepted operations from outbox', () async {
      final op = await syncService.queueMutation(
        tripId: 'trip-1',
        entityType: 'checklist_item',
        entityId: 'item-1',
        operationType: 'update',
        payload: {'is_packed': true},
        baseVersion: 1,
      );

      fakeClient.postResponse = {
        'data': {
          'results': [
            {
              'operation_id': op.operationId,
              'status': 'accepted',
              'server_sequence': 50,
              'current_version': 2,
            },
          ],
        },
      };

      final results = await syncService.pushPending();
      expect(results.length, 1);
      expect(results.first.status, 'accepted');

      final remaining = await storage.getPendingOperations();
      expect(remaining.isEmpty, true);
    });

    test('pushPending flags conflict in outbox with server details', () async {
      final op = await syncService.queueMutation(
        tripId: 'trip-1',
        entityType: 'checklist_item',
        entityId: 'item-1',
        operationType: 'update',
        payload: {'title': 'Offline Edit'},
        baseVersion: 1,
      );

      fakeClient.postResponse = {
        'data': {
          'results': [
            {
              'operation_id': op.operationId,
              'status': 'conflict',
              'server_sequence': 60,
              'current_version': 3,
              'conflict_details': {
                'server_version': 3,
                'server_payload': {'title': 'Server Remote Edit'},
              },
            },
          ],
        },
      };

      final results = await syncService.pushPending();
      expect(results.length, 1);
      expect(results.first.status, 'conflict');

      final pending = await storage.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.status, 'conflict');
      expect(pending.first.conflictDetails?['server_version'], 3);
    });

    test(
      'resolveConflict with keepLocal=true updates baseVersion and pushes',
      () async {
        final op = OutboxOperation(
          operationId: 'conflict-op-1',
          tripId: 'trip-1',
          entityType: 'checklist_item',
          entityId: 'item-1',
          operationType: 'update',
          payload: {'title': 'Offline Winner'},
          baseVersion: 1,
          status: 'conflict',
          conflictDetails: {'server_version': 4},
          createdAt: DateTime.now(),
        );
        await storage.saveOperation(op);

        fakeClient.postResponse = {
          'data': {
            'results': [
              {
                'operation_id': 'conflict-op-1',
                'status': 'accepted',
                'server_sequence': 75,
                'current_version': 5,
              },
            ],
          },
        };

        await syncService.resolveConflict('conflict-op-1', keepLocal: true);

        // Operation should be pushed and removed after accepted
        final pending = await storage.getPendingOperations();
        expect(pending.isEmpty, true);
        expect(fakeClient.lastPostData?['operations'][0]['base_version'], 4);
      },
    );

    test('resolveConflict with keepLocal=false discards local edit', () async {
      final op = OutboxOperation(
        operationId: 'conflict-op-2',
        tripId: 'trip-1',
        entityType: 'checklist_item',
        entityId: 'item-1',
        operationType: 'update',
        payload: {'title': 'Discard Me'},
        baseVersion: 1,
        status: 'conflict',
        conflictDetails: {'server_version': 2},
        createdAt: DateTime.now(),
      );
      await storage.saveOperation(op);

      await syncService.resolveConflict('conflict-op-2', keepLocal: false);

      final remaining = await storage.getAllOperations();
      expect(remaining.isEmpty, true);
    });

    test('pullLatest fetches remote changes and advances cursor', () async {
      fakeClient.getResponse = {
        'data': {
          'cursor': 200,
          'operations': [
            {
              'id': 'op-remote-10',
              'operation_id': 'op-remote-10',
              'trip_id': 'trip-1',
              'entity_type': 'stay',
              'entity_id': 'stay-10',
              'operation_type': 'create',
              'payload': {'name': 'Tokyo Hotel'},
              'base_version': 1,
              'server_sequence': 200,
              'created_at': DateTime.now().toIso8601String(),
            },
          ],
          'has_more': false,
        },
      };

      final result = await syncService.pullLatest(tripId: 'trip-1');
      expect(result.cursor, 200);
      expect(result.operations.length, 1);
      expect(await storage.getCursor('trip-1'), 200);
    });

    test('pushPending preserves rejected operations with reason instead of discarding silently', () async {
      final op = await syncService.queueMutation(
        tripId: 'trip-1',
        entityType: 'checklist_item',
        entityId: 'item-1',
        operationType: 'update',
        payload: {'title': 'Demoted Offline Edit'},
        baseVersion: 1,
      );

      fakeClient.postResponse = {
        'data': {
          'results': [
            {
              'operation_id': op.operationId,
              'status': 'rejected',
              'server_sequence': 90,
              'current_version': null,
              'conflict_details': {
                'reason':
                    'Unauthorized trip membership or insufficient permissions',
              },
            },
          ],
        },
      };

      final results = await syncService.pushPending();
      expect(results.first.status, 'rejected');

      // Excluded from pending retries, yet retained in outbox with reason (TC-3.2)
      expect(await storage.getPendingOperations(), isEmpty);
      final all = await storage.getAllOperations();
      expect(all.length, 1);
      expect(all.first.status, 'rejected');
      expect(
        all.first.conflictDetails?['reason'],
        'Unauthorized trip membership or insufficient permissions',
      );

      await syncService.dismissRejectedOperation(op.operationId);
      expect(await storage.getAllOperations(), isEmpty);
    });

    test('pushPending chunks large queues and preserves un-pushed chunks after network interruption', () async {
      // Queue 30 operations (> maxPushBatchSize = 25)
      for (var i = 0; i < 30; i++) {
        await syncService.queueMutation(
          tripId: 'trip-1',
          entityType: 'checklist_item',
          entityId: 'item-$i',
          operationType: 'update',
          payload: {'title': 'Item $i'},
          baseVersion: 1,
        );
      }

      var chunkCalls = 0;
      fakeClient.onPost = (path, data) async {
        chunkCalls++;
        final ops = List<Map<String, dynamic>>.from(
          data?['operations'] as List? ?? const [],
        );
        if (chunkCalls == 1) {
          expect(ops.length, 25);
          return {
            'data': {
              'results': [
                for (var i = 0; i < ops.length; i++)
                  {
                    'operation_id': ops[i]['operation_id'],
                    'status': 'accepted',
                    'server_sequence': i + 1,
                    'current_version': 2,
                  },
              ],
            },
          };
        }
        // Simulate sudden network drop on second chunk (ops 25..29)
        throw const NetworkException();
      };

      await expectLater(
        syncService.pushPending(),
        throwsA(isA<NetworkException>()),
      );

      // First chunk (25 ops) removed cleanly; remaining 5 ops stay pending for retry
      final remaining = await storage.getPendingOperations();
      expect(remaining.length, 5);
      expect(remaining.first.entityId, 'item-25');

      // Reconnect and finish remaining chunk cleanly
      fakeClient.onPost = (path, data) async {
        final ops = List<Map<String, dynamic>>.from(
          data?['operations'] as List? ?? const [],
        );
        expect(ops.length, 5);
        return {
          'data': {
            'results': [
              for (var i = 0; i < ops.length; i++)
                {
                  'operation_id': ops[i]['operation_id'],
                  'status': 'accepted',
                  'server_sequence': 26 + i,
                  'current_version': 2,
                },
            ],
          },
        };
      };

      final finalResults = await syncService.pushPending();
      expect(finalResults.length, 5);
      expect(await storage.getPendingOperations(), isEmpty);
    });
  });

  group('Presentation Widgets', () {
    testWidgets(
      'SyncStatusIndicator displays synced icon when all changes synced',
      (tester) async {
        final storage = InMemoryOutboxStorage();
        final client = FakeSyncApiClient();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              outboxStorageProvider.overrideWithValue(storage),
              apiClientProvider.overrideWithValue(client),
            ],
            child: const MaterialApp(
              home: Scaffold(body: SyncStatusIndicator()),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'SyncStatusIndicator displays pending count badge when mutations pending',
      (tester) async {
        final storage = InMemoryOutboxStorage();
        await storage.saveOperation(
          OutboxOperation(
            operationId: 'pending-1',
            entityType: 'checklist_item',
            entityId: 'item-1',
            operationType: 'update',
            createdAt: DateTime.now(),
          ),
        );
        await storage.saveOperation(
          OutboxOperation(
            operationId: 'pending-2',
            entityType: 'itinerary_item',
            entityId: 'item-2',
            operationType: 'update',
            createdAt: DateTime.now(),
          ),
        );

        final client = FakeSyncApiClient();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              outboxStorageProvider.overrideWithValue(storage),
              apiClientProvider.overrideWithValue(client),
            ],
            child: const MaterialApp(
              home: Scaffold(body: SyncStatusIndicator()),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('2'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'SyncStatusIndicator displays conflict warning when conflict detected',
      (tester) async {
        final storage = InMemoryOutboxStorage();
        await storage.saveOperation(
          OutboxOperation(
            operationId: 'conflict-1',
            entityType: 'checklist_item',
            entityId: 'item-1',
            operationType: 'update',
            status: 'conflict',
            conflictDetails: {
              'server_version': 2,
              'server_payload': {'title': 'Passport (Renewed)'},
            },
            createdAt: DateTime.now(),
          ),
        );

        final client = FakeSyncApiClient();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              outboxStorageProvider.overrideWithValue(storage),
              apiClientProvider.overrideWithValue(client),
            ],
            child: const MaterialApp(
              home: Scaffold(body: SyncStatusIndicator()),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Conflict (1)'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'ConflictResolutionDialog renders conflict details and options',
      (tester) async {
        final conflict = OutboxOperation(
          operationId: 'conflict-test-1',
          entityType: 'checklist_item',
          entityId: 'item-test-1',
          operationType: 'update',
          baseVersion: 1,
          status: 'conflict',
          payload: {'title': 'My Offline Title'},
          conflictDetails: {
            'server_version': 2,
            'server_payload': {'title': 'Remote Cloud Title'},
          },
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ConflictResolutionDialog(conflict: conflict),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Version Conflict Detected'), findsOneWidget);
        expect(find.text('Keep Server Version'), findsOneWidget);
        expect(find.text('Keep My Offline Edit'), findsOneWidget);
        expect(find.textContaining('Remote Cloud Title'), findsOneWidget);
        expect(find.textContaining('My Offline Title'), findsOneWidget);
      },
    );

    testWidgets(
      'SyncStatusIndicator surfaces rejected edits dialog and dismisses cleanly',
      (tester) async {
        final storage = InMemoryOutboxStorage();
        await storage.saveOperation(
          OutboxOperation(
            operationId: 'rej-1',
            entityType: 'checklist_item',
            entityId: 'item-1',
            operationType: 'update',
            status: 'rejected',
            conflictDetails: {
              'reason':
                  'Unauthorized trip membership or insufficient permissions',
            },
            createdAt: DateTime.now(),
          ),
        );

        final client = FakeSyncApiClient();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              outboxStorageProvider.overrideWithValue(storage),
              apiClientProvider.overrideWithValue(client),
            ],
            child: const MaterialApp(
              home: Scaffold(body: SyncStatusIndicator()),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Rejected (1)'), findsOneWidget);

        await tester.tap(find.text('Rejected (1)'));
        await tester.pumpAndSettle();

        expect(find.text('Offline Edit Rejected'), findsOneWidget);
        expect(find.textContaining('insufficient permissions'), findsOneWidget);

        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
        expect(await storage.getAllOperations(), isEmpty);
      },
    );

    testWidgets(
      'ConflictResolutionDialog surfaces remote deletion status cleanly',
      (tester) async {
        final conflict = OutboxOperation(
          operationId: 'conflict-del-1',
          entityType: 'checklist_item',
          entityId: 'item-del-1',
          operationType: 'update',
          baseVersion: 1,
          status: 'conflict',
          payload: {'title': 'Kept Item'},
          conflictDetails: {
            'server_version': 2,
            'server_payload': {
              'id': 'item-del-1',
              'title': 'Original Item',
              'deleted': true,
            },
          },
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ConflictResolutionDialog(conflict: conflict),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'Status: Deleted on another device while offline',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Original Item'), findsOneWidget);
        expect(find.textContaining('Kept Item'), findsOneWidget);
      },
    );
  });

  group('Offline Version Hardening', () {
    test('consecutive offline stay edits bump optimistic version and include coordinates', () async {
      final storage = InMemoryOutboxStorage();
      final apiClient = FakeSyncApiClient();
      final repo = _FakeOfflineStayRepository(apiClient: apiClient);

      final container = ProviderContainer(
        overrides: [
          outboxStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWithValue(apiClient),
          stayRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final initialStays = await container.read(
        stayListProvider('trip-1').future,
      );
      expect(initialStays.first.version, 1);

      final notifier = container.read(stayListProvider('trip-1').notifier);

      // First offline update (queues baseVersion: 1 while local state preserves confirmed server version 1)
      final first = await notifier.updateStay(
        'stay-1',
        name: 'Tokyo Inn',
        latitude: 35.6945,
        longitude: 139.7006,
      );
      expect(first.version, 1);

      // Second offline update while still offline (chains outbox baseVersion: 2)
      final second = await notifier.updateStay(
        'stay-1',
        notes: 'Ask for quiet room',
      );
      expect(second.version, 1);

      final pending = await storage.getPendingOperations();
      expect(pending.length, 2);
      expect(pending[0].baseVersion, 1);
      expect(pending[0].payload?['name'], 'Tokyo Inn');
      expect(pending[0].payload?['latitude'], 35.6945);
      expect(pending[0].payload?['longitude'], 139.7006);
      expect(pending[1].baseVersion, 2);
      expect(pending[1].payload?['notes'], 'Ask for quiet room');
    });
  });
}

class _FakeOfflineStayRepository extends StayRepository {
  _FakeOfflineStayRepository({required super.apiClient});

  List<Stay> cached = [
    const Stay(
      id: 'stay-1',
      tripId: 'trip-1',
      name: 'Shinjuku Hotel',
      stayType: 'hotel',
      version: 1,
    ),
  ];

  @override
  Future<List<Stay>> fetchStays(String tripId) async => cached;

  @override
  Future<void> cacheStays(String tripId, List<Stay> stays) async {
    cached = stays;
  }

  @override
  Future<Stay> updateStay(
    String stayId, {
    String? name,
    String? stayType,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? timezone,
    String? phone,
    String? bookingReference,
    String? notes,
    dynamic luggageProfile,
    int? baseVersion,
  }) async {
    throw const NetworkException();
  }
}
