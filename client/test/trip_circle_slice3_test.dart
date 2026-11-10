import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/auth/domain/models/auth_state.dart';
import 'package:tapittrip/features/auth/domain/models/auth_user.dart';
import 'package:tapittrip/features/auth/presentation/providers/auth_provider.dart';
import 'package:tapittrip/features/circles/data/trip_circle_repository.dart';
import 'package:tapittrip/features/circles/presentation/pages/circle_inbox_page.dart';
import 'package:tapittrip/features/circles/presentation/pages/trip_circle_page.dart';
import 'package:tapittrip/features/itinerary/data/itinerary_repository.dart';
import 'package:tapittrip/features/itinerary/domain/models/itinerary_item.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/notifications/data/notification_repository.dart';
import 'package:tapittrip/features/notifications/domain/models/notification_preference.dart';
import 'package:tapittrip/features/notifications/presentation/pages/notification_preferences_page.dart';
import 'package:tapittrip/features/notifications/presentation/providers/notification_provider.dart';
import 'package:tapittrip/features/stays/data/stay_repository.dart';
import 'package:tapittrip/features/stays/domain/models/stay.dart';
import 'package:tapittrip/features/stays/presentation/providers/stay_provider.dart';
import 'package:tapittrip/features/stays/presentation/widgets/stay_card.dart';
import 'package:tapittrip/features/sync/data/outbox_storage.dart';
import 'package:tapittrip/features/sync/domain/models/outbox_operation.dart';
import 'package:tapittrip/features/sync/presentation/providers/sync_provider.dart';
import 'package:tapittrip/features/sync/presentation/widgets/sync_status_indicator.dart';
import 'package:tapittrip/features/sync/services/sync_service.dart';
import 'package:tapittrip/features/trips/data/trip_repository.dart';

class _FakeSlice3ApiClient extends ApiClient {
  _FakeSlice3ApiClient() : super(tokenStorage: InMemoryTokenStorage());

  bool throwConflictOnPatch = false;
  bool throwOfflineOnPatch = false;
  bool throwForbiddenOnTripA = false;
  String? lastPatchPath;
  Map<String, dynamic>? lastPatchData;
  String? lastPostPath;
  Map<String, dynamic>? lastPostData;
  Map<String, dynamic>? lastPutData;

  final List<Map<String, dynamic>> announcements = [
    {
      'id': 'ann-1',
      'trip_id': 'trip-a',
      'author_id': 'owner-1',
      'author_name': 'Alice Organizer',
      'title': 'Meet at Gate 4',
      'body': 'Shuttle boards 08:00 sharp.',
      'is_pinned': true,
      'client_operation_id': 'op-ann-1',
      'version': 1,
    },
  ];

  final List<Map<String, dynamic>> notifications = [
    {
      'id': 'notif-1',
      'trip_id': 'trip-a',
      'trip_title': 'Kyoto Autumn',
      'announcement_id': 'ann-1',
      'category': 'circle_announcement',
      'title': 'Meet at Gate 4',
      'body': 'Shuttle boards 08:00 sharp. (Nov 10, 08:00 JST)',
      'timezone': 'Europe/London',
      'trip_local_time_label': 'Nov 10, 08:00 JST',
      'status': 'suppressed_quiet_hours',
      'is_read': false,
    },
  ];

  Map<String, dynamic> prefsJson = {
    'id': 'pref-1',
    'user_id': 'user-1',
    'morning_summary_enabled': true,
    'morning_summary_time': '08:00',
    'activity_reminders_enabled': true,
    'activity_reminder_lead_minutes': 30,
    'checklist_reminders_enabled': true,
    'stay_reminders_enabled': true,
    'circle_announcements_enabled': true,
    'quiet_hours_enabled': false,
    'quiet_hours_start': '22:00',
    'quiet_hours_end': '07:00',
    'geofence_arrival_enabled': true,
    'timezone_behavior': 'destination',
  };

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (throwForbiddenOnTripA && path.contains('trip-a')) {
      throw const ApiException(
        code: 'forbidden',
        message: 'You are not a member of this trip.',
        statusCode: 403,
      );
    }

    if (path == '/trips') {
      return [
        {
          'id': 'trip-a',
          'owner_id': 'owner-1',
          'title': 'Kyoto Autumn',
          'destination_country': 'JP',
          'trip_type': 'leisure',
          'planning_mode': 'diy',
          'status': 'planned',
          'version': 1,
          'role': 'owner',
        },
      ];
    }

    if (path.endsWith('/members')) {
      return [
        {
          'id': 'mem-1',
          'trip_id': 'trip-a',
          'user_id': 'owner-1',
          'display_name': 'Alice Organizer',
          'role': 'owner',
          'invitation_status': 'accepted',
        },
      ];
    }

    if (path.endsWith('/invitations') ||
        path.endsWith('/feed') ||
        path == '/me/invitations' ||
        path == '/me/ownership-transfers') {
      return const [];
    }

    if (path.endsWith('/ownership-transfer')) {
      return null;
    }

    if (path == '/trips/trip-a/announcements') {
      return announcements;
    }

    if (path == '/me/notifications') {
      return notifications;
    }

    if (path == '/me/notification-preferences') {
      return prefsJson;
    }

    if (path == '/trips/trip-a/itinerary-items') {
      return [
        {
          'id': 'item-1',
          'trip_id': 'trip-a',
          'kind': 'attraction',
          'title': 'Arashiyama Bamboo Grove',
          'sort_order': 0,
          'status': 'planned',
          'version': 2,
        },
        {
          'id': 'item-2',
          'trip_id': 'trip-a',
          'kind': 'meal',
          'title': 'Nishiki Market',
          'sort_order': 1,
          'status': 'planned',
          'version': 1,
        },
      ];
    }

    if (path == '/trips/trip-a/stays') {
      return [
        {
          'id': 'stay-1',
          'trip_id': 'trip-a',
          'name': 'Gion Ryokan',
          'stay_type': 'hotel',
          'timezone': 'Asia/Tokyo',
          'version': 3,
        },
      ];
    }

    if (path == '/sync/pull') {
      return {'cursor': 10, 'operations': const [], 'has_more': false};
    }

    return const [];
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPostPath = path;
    lastPostData = data is Map ? Map<String, dynamic>.from(data) : null;

    if (path == '/trips/trip-a/itinerary-items/reorder') {
      if (throwConflictOnPatch) {
        throw const ConflictException(
          message: 'Itinerary ordering changed on another device.',
          details: {
            'server_version': 4,
            'server_payload': {
              'id': 'item-1',
              'title': 'Arashiyama Sunrise',
              'sort_order': 1,
              'version': 4,
            },
          },
        );
      }
      if (throwOfflineOnPatch) {
        throw const NetworkException();
      }
      return const [];
    }

    if (path == '/trips/trip-a/announcements') {
      final created = {
        'id': 'ann-2',
        'trip_id': 'trip-a',
        'author_id': 'owner-1',
        'author_name': 'Alice Organizer',
        'title': data['title'],
        'body': data['body'],
        'is_pinned': data['is_pinned'] ?? false,
        'client_operation_id': data['client_operation_id'],
        'version': 1,
      };
      announcements.insert(0, created);
      return created;
    }

    if (path == '/me/notifications/notif-1/read') {
      notifications[0] = {
        ...notifications[0],
        'is_read': true,
        'read_at': '2026-11-10T10:00:00Z',
      };
      return notifications[0];
    }

    if (path == '/sync/push') {
      final ops = (data['operations'] as List<dynamic>? ?? []);
      return {
        'data': {
          'results': ops.map((op) {
            final map = op as Map;
            if (map['trip_id'] == 'trip-a' && throwForbiddenOnTripA) {
              return {
                'operation_id': map['operation_id'],
                'status': 'rejected',
                'conflict_details': {
                  'reason': 'User is not a member of this trip',
                },
              };
            }
            return {
              'operation_id': map['operation_id'],
              'status': 'accepted',
              'server_version':
                  ((map['base_version'] as num?)?.toInt() ?? 1) + 1,
            };
          }).toList(),
        },
      };
    }

    return const {};
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPatchPath = path;
    lastPatchData = data is Map ? Map<String, dynamic>.from(data) : null;

    if (throwConflictOnPatch) {
      throw ConflictException(
        message: 'Conflict detected.',
        details: {
          'server_version': 5,
          'server_payload': path.contains('/stays/')
              ? {
                  'id': 'stay-1',
                  'name': 'Server Stay Name',
                  'booking_reference': null,
                  'version': 5,
                }
              : {
                  'id': 'item-1',
                  'title': 'Server Edited Title',
                  'sort_order': 0,
                  'version': 5,
                },
        },
      );
    }

    if (throwOfflineOnPatch) {
      throw const NetworkException();
    }

    if (path == '/itinerary-items/item-1') {
      return {
        'id': 'item-1',
        'trip_id': 'trip-a',
        'kind': 'attraction',
        'title': data['title'] ?? 'Arashiyama Bamboo Grove',
        'sort_order': 0,
        'status': 'planned',
        'version': 3,
      };
    }

    if (path == '/stays/stay-1') {
      return {
        'id': 'stay-1',
        'trip_id': 'trip-a',
        'name': data['name'] ?? 'Gion Ryokan',
        'stay_type': 'hotel',
        'timezone': 'Asia/Tokyo',
        'version': 4,
      };
    }

    return const {};
  }

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (path == '/me/notification-preferences' && data is Map) {
      lastPutData = Map<String, dynamic>.from(data);
      prefsJson = {...prefsJson, ...lastPutData!};
      return prefsJson;
    }
    return const {};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('TC-4 Offline Queue, Conflict Detection & Cache Isolation', () {
    test('ItineraryListNotifier & StayListNotifier send base_version, queue offline edits, and record 409 conflicts', () async {
      final api = _FakeSlice3ApiClient();
      final outbox = InMemoryOutboxStorage();
      const storage = FlutterSecureStorage();
      final itineraryRepo = ItineraryRepository(
        apiClient: api,
        storage: storage,
      );
      final stayRepo = StayRepository(apiClient: api, storage: storage);
      final syncService = SyncService(apiClient: api, outboxStorage: outbox);

      final container = ProviderContainer(
        overrides: [
          itineraryRepositoryProvider.overrideWithValue(itineraryRepo),
          stayRepositoryProvider.overrideWithValue(stayRepo),
          outboxStorageProvider.overrideWithValue(outbox),
          syncServiceProvider.overrideWithValue(syncService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(itineraryListProvider('trip-a').future);
      await container.read(stayListProvider('trip-a').future);

      // 1. Offline itinerary edit queues durable outbox op
      api.throwOfflineOnPatch = true;
      await container
          .read(itineraryListProvider('trip-a').notifier)
          .updateItem('item-1', title: 'Offline Walk');
      expect(container.read(syncProvider).status, equals(SyncStatus.pending));
      final pendingOps = await outbox.getAllOperations();
      expect(pendingOps, hasLength(1));
      expect(pendingOps.first.entityType, 'itinerary_item');
      expect(pendingOps.first.baseVersion, 2);

      // 2. 409 ConflictException records conflict on itinerary PATCH with base_version
      await outbox.clear();
      api.throwOfflineOnPatch = false;
      api.throwConflictOnPatch = true;

      await expectLater(
        () => container
            .read(itineraryListProvider('trip-a').notifier)
            .updateItem('item-1', title: 'Stale Rename'),
        throwsA(isA<ConflictException>()),
      );
      expect(api.lastPatchData?['base_version'], equals(2));
      expect(container.read(syncProvider).status, equals(SyncStatus.conflict));

      // 3. Reorder sends expected_versions and captures 409 conflict safely
      final reorderedOk = await container
          .read(itineraryListProvider('trip-a').notifier)
          .applyReorderedItems([
            const ItineraryItem(
              id: 'item-2',
              tripId: 'trip-a',
              kind: 'meal',
              title: 'Nishiki Market',
              sortOrder: 0,
              status: 'planned',
              version: 1,
            ),
            const ItineraryItem(
              id: 'item-1',
              tripId: 'trip-a',
              kind: 'attraction',
              title: 'Arashiyama Bamboo Grove',
              sortOrder: 1,
              status: 'planned',
              version: 2,
            ),
          ]);
      expect(reorderedOk, isFalse);
      expect(
        (api.lastPostData?['expected_versions'] as Map)['item-1'],
        equals(2),
      );

      // 4. Stay PATCH sends base_version and records redacted Stay conflict
      await expectLater(
        () => container
            .read(stayListProvider('trip-a').notifier)
            .updateStay('stay-1', name: 'Local Stay Rename'),
        throwsA(isA<ConflictException>()),
      );
      expect(api.lastPatchData?['base_version'], equals(3));

      final conflicts = (await outbox.getAllOperations())
          .where((op) => op.status == 'conflict')
          .toList();
      expect(conflicts.length, equals(3));
    });

    test('403 revocation and rejected sync purge only revoked trip caches and reminders while keeping other trips intact', () async {
      const storage = FlutterSecureStorage();
      FlutterSecureStorage.setMockInitialValues({
        'cached_stays_trip-a': jsonEncode([
          {
            'id': 's1',
            'trip_id': 'trip-a',
            'name': 'Secret Hotel',
            'stay_type': 'hotel',
            'timezone': 'UTC',
            'version': 1,
          },
        ]),
        'cached_itinerary_trip-a': jsonEncode([
          {
            'id': 'i1',
            'trip_id': 'trip-a',
            'kind': 'attraction',
            'title': 'Revoked Stop',
            'sort_order': 0,
            'status': 'planned',
            'version': 1,
          },
        ]),
        'cached_checklists_trip-a': '[]',
        'cached_expenses_trip-a': '[]',
        'cached_reminders_trip-a': '[]',
        'cached_announcements_trip-a': '[]',
        'scheduled_local_notifications_trip-a': jsonEncode({
          'rem-1': 'scheduled',
        }),
        'cached_stays_trip-b': jsonEncode([
          {
            'id': 's2',
            'trip_id': 'trip-b',
            'name': 'Own Trip Hotel',
            'stay_type': 'hotel',
            'timezone': 'UTC',
            'version': 1,
          },
        ]),
      });

      final api = _FakeSlice3ApiClient()..throwForbiddenOnTripA = true;
      final outbox = InMemoryOutboxStorage();
      await outbox.saveOperation(
        OutboxOperation(
          operationId: 'op-revoked-1',
          tripId: 'trip-a',
          entityType: 'itinerary_item',
          entityId: 'i1',
          operationType: 'update',
          payload: {'title': 'Stale'},
          baseVersion: 1,
          status: 'pending',
          createdAt: DateTime.now().toUtc(),
        ),
      );

      final circleRepo = TripCircleRepository(apiClient: api, storage: storage);
      final syncService = SyncService(
        apiClient: api,
        outboxStorage: outbox,
        onTripAccessRevoked: (id) => circleRepo.purgeTripCircleCaches(id),
      );

      final results = await syncService.pushPending();
      expect(results.first.status, 'rejected');

      // Revoked trip-a caches and local reminders were wiped
      expect(await storage.read(key: 'cached_stays_trip-a'), isNull);
      expect(await storage.read(key: 'cached_itinerary_trip-a'), isNull);
      expect(await storage.read(key: 'cached_checklists_trip-a'), isNull);
      expect(await storage.read(key: 'cached_expenses_trip-a'), isNull);
      expect(await storage.read(key: 'cached_reminders_trip-a'), isNull);
      expect(await storage.read(key: 'cached_announcements_trip-a'), isNull);
      expect(
        await storage.read(key: 'scheduled_local_notifications_trip-a'),
        isNull,
      );

      // Separate trip-b cache remains intact (TC-4.5)
      expect(await storage.read(key: 'cached_stays_trip-b'), isNotNull);

      // Direct 403 repository fetch also purges rather than serving stale cache
      await storage.write(key: 'cached_stays_trip-a', value: '[{"id":"x"}]');
      final stayRepo = StayRepository(apiClient: api, storage: storage);
      await expectLater(
        () => stayRepo.fetchStays('trip-a'),
        throwsA(isA<ApiException>()),
      );
      expect(await storage.read(key: 'cached_stays_trip-a'), isNull);
    });

    testWidgets(
      'SyncStatusIndicator opens conflict selector for multiple conflicts and resolves via ConflictResolutionDialog',
      (tester) async {
        final api = _FakeSlice3ApiClient();
        final outbox = InMemoryOutboxStorage();
        await outbox.saveOperation(
          OutboxOperation(
            operationId: 'conf-1',
            tripId: 'trip-a',
            entityType: 'itinerary_item',
            entityId: 'item-1',
            operationType: 'update',
            payload: {'title': 'Local Morning Temple', 'sort_order': 2},
            baseVersion: 1,
            status: 'conflict',
            conflictDetails: {
              'server_version': 2,
              'server_payload': {
                'title': 'Server Noon Shrine',
                'sort_order': 0,
              },
            },
            createdAt: DateTime.now().toUtc(),
          ),
        );
        await outbox.saveOperation(
          OutboxOperation(
            operationId: 'conf-2',
            tripId: 'trip-a',
            entityType: 'stay',
            entityId: 'stay-1',
            operationType: 'update',
            payload: {'name': 'Local Hotel Name'},
            baseVersion: 1,
            status: 'conflict',
            conflictDetails: {
              'server_version': 3,
              'server_payload': {'name': 'Server Ryokan Name'},
            },
            createdAt: DateTime.now().toUtc(),
          ),
        );

        final syncService = SyncService(apiClient: api, outboxStorage: outbox);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              outboxStorageProvider.overrideWithValue(outbox),
              syncServiceProvider.overrideWithValue(syncService),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const Scaffold(
                body: Center(child: SyncStatusIndicator(tripId: 'trip-a')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Conflict (2)'), findsOneWidget);

        await tester.tap(find.text('Conflict (2)'));
        await tester.pumpAndSettle();

        // Selector sheet lists both conflicts
        expect(find.text('2 Sync Conflicts'), findsOneWidget);
        expect(find.text('Local Morning Temple'), findsOneWidget);
        expect(find.text('Local Hotel Name'), findsOneWidget);

        // Open first conflict and choose Keep My Offline Edit
        await tester.tap(find.text('Local Morning Temple'));
        await tester.pumpAndSettle();
        expect(find.text('Version Conflict Detected'), findsOneWidget);
        expect(find.textContaining('sort_order: 2'), findsOneWidget);

        await tester.tap(find.text('Keep My Offline Edit'));
        await tester.pumpAndSettle();

        // Remaining conflict count drops to 1
        expect(find.text('Conflict (1)'), findsOneWidget);
      },
    );

    testWidgets(
      'StayCard safely omits redacted booking reference and private address for companion friends_family stay',
      (tester) async {
        const redactedStay = Stay(
          id: 'stay-ff',
          tripId: 'trip-a',
          name: 'Aunt Yuki House',
          stayType: 'friends_family',
          address: null,
          phone: null,
          bookingReference: null,
          notes: null,
          googleMapsUrl: null,
          googleMapsDirectionsUrl: null,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(body: StayCard(stay: redactedStay)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Aunt Yuki House'), findsOneWidget);
        expect(find.textContaining('Booking Ref:'), findsNothing);
      },
    );
  });

  group('TC-5 Circle Announcements, Notices Inbox & Preferences UI', () {
    testWidgets(
      'TripCirclePage renders organizer Circle Announcements even when activity feed is empty and supports posting',
      (tester) async {
        final api = _FakeSlice3ApiClient();
        const storage = FlutterSecureStorage();
        final circleRepo = TripCircleRepository(
          apiClient: api,
          storage: storage,
        );
        final tripRepo = RemoteTripRepository(api);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tripCircleRepositoryProvider.overrideWithValue(circleRepo),
              tripRepositoryProvider.overrideWithValue(tripRepo),
              authProvider.overrideWith(() => _FakeAuthNotifier('owner-1')),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TripCirclePage(tripId: 'trip-a'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Circle Announcements'), findsOneWidget);
        expect(find.text('Meet at Gate 4'), findsOneWidget);
        expect(find.text('Post'), findsOneWidget);

        await tester.tap(find.text('Post'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Title'),
          'Dinner Change',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Message'),
          'Reservation moved to 19:30.',
        );
        await tester.tap(find.text('Publish'));
        await tester.pumpAndSettle();

        expect(api.lastPostPath, '/trips/trip-a/announcements');
        expect(api.lastPostData?['client_operation_id'], isNotEmpty);
        expect(find.text('Dinner Change'), findsOneWidget);
      },
    );

    testWidgets(
      'CircleInboxPage shows Circle Notices with trip-local time & quiet-hours context and marks read',
      (tester) async {
        final api = _FakeSlice3ApiClient();
        const storage = FlutterSecureStorage();
        final circleRepo = TripCircleRepository(
          apiClient: api,
          storage: storage,
        );
        final tripRepo = RemoteTripRepository(api);
        final notifRepo = NotificationRepository(
          apiClient: api,
          storage: storage,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tripCircleRepositoryProvider.overrideWithValue(circleRepo),
              tripRepositoryProvider.overrideWithValue(tripRepo),
              notificationRepositoryProvider.overrideWithValue(notifRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const CircleInboxPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Circle Notices'), findsOneWidget);
        expect(find.text('Meet at Gate 4'), findsOneWidget);
        expect(
          find.textContaining('Nov 10, 08:00 JST • Queued after quiet hours'),
          findsOneWidget,
        );

        await tester.tap(find.text('Mark read'));
        await tester.pumpAndSettle();

        expect(api.lastPostPath, '/me/notifications/notif-1/read');
        expect(find.text('Mark read'), findsNothing);
      },
    );

    testWidgets(
      'NotificationPreferencesPage toggles Circle Announcements and Timezone Behavior',
      (tester) async {
        final api = _FakeSlice3ApiClient();
        const storage = FlutterSecureStorage();
        final notifRepo = NotificationRepository(
          apiClient: api,
          storage: storage,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              notificationRepositoryProvider.overrideWithValue(notifRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const NotificationPreferencesPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Circle Announcements'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Circle Announcements'));
        await tester.pumpAndSettle();
        expect(find.text('Circle Announcements'), findsOneWidget);
        await tester.tap(find.text('Circle Announcements'));
        await tester.pumpAndSettle();
        expect(api.lastPutData?['circle_announcements_enabled'], isFalse);

        await tester.scrollUntilVisible(
          find.text('Quiet Hours Timezone'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Quiet Hours Timezone'));
        await tester.pumpAndSettle();
        expect(find.text('Quiet Hours Timezone'), findsOneWidget);
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Home').last);
        await tester.pumpAndSettle();
        expect(api.lastPutData?['timezone_behavior'], 'home');

        final parsed = NotificationPreference.fromJson(api.prefsJson);
        expect(parsed.circleAnnouncementsEnabled, isFalse);
        expect(parsed.timezoneBehavior, 'home');
      },
    );
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this.userId);
  final String userId;

  @override
  AuthState build() {
    return Authenticated(
      token: 'fake-token',
      user: AuthUser(
        id: userId,
        name: 'Alice Organizer',
        displayName: 'Alice Organizer',
        email: 'alice@example.com',
      ),
    );
  }
}
