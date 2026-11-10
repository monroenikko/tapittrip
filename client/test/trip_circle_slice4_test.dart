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
import 'package:tapittrip/features/checklists/data/checklist_repository.dart';
import 'package:tapittrip/features/checklists/domain/models/checklist_item.dart';
import 'package:tapittrip/features/checklists/presentation/providers/checklist_provider.dart';
import 'package:tapittrip/features/checklists/presentation/widgets/checklists_view.dart';
import 'package:tapittrip/features/circles/data/trip_circle_repository.dart';
import 'package:tapittrip/features/circles/domain/models/trip_traveler.dart';
import 'package:tapittrip/features/circles/presentation/widgets/managed_travelers_section.dart';
import 'package:tapittrip/features/sync/data/outbox_storage.dart';
import 'package:tapittrip/features/sync/presentation/providers/sync_provider.dart';
import 'package:tapittrip/features/sync/services/sync_service.dart';

class _InMemorySecureStorage extends FlutterSecureStorage {
  _InMemorySecureStorage([Map<String, String>? seed])
    : _store = seed != null ? Map<String, String>.from(seed) : {};

  final Map<String, String> _store;

  String? rawValue(String key) => _store[key];

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier({required this.userId, required this.displayName});

  final String userId;
  final String displayName;

  @override
  AuthState build() {
    return Authenticated(
      token: 'fake-token',
      user: AuthUser(
        id: userId,
        name: displayName,
        displayName: displayName,
        email: '$userId@example.com',
      ),
    );
  }
}

class _FakeSlice4ApiClient extends ApiClient {
  _FakeSlice4ApiClient({required this.actorUserId})
    : super(tokenStorage: InMemoryTokenStorage());

  final String actorUserId;
  bool throwNetwork = false;
  bool throwConflictOnToggle = false;
  bool throwForbiddenOnTripA = false;

  final List<String> toggleCalls = [];
  String? lastPostPath;
  Map<String, dynamic>? lastPostData;
  String? lastPatchPath;
  Map<String, dynamic>? lastPatchData;

  final List<Map<String, dynamic>> members = [
    {
      'id': 'mem-owner',
      'trip_id': 'trip-a',
      'user_id': 'owner-1',
      'display_name': 'Alice Organizer',
      'role': 'owner',
      'invitation_status': 'accepted',
    },
    {
      'id': 'mem-viewer',
      'trip_id': 'trip-a',
      'user_id': 'viewer-1',
      'display_name': 'Bob Viewer',
      'role': 'viewer',
      'invitation_status': 'accepted',
    },
  ];

  final List<Map<String, dynamic>> travelers = [
    {
      'id': 'trav-leo',
      'trip_id': 'trip-a',
      'managing_user_id': 'owner-1',
      'managing_user_name': 'Alice Organizer',
      'display_name': 'Leo',
      'traveler_category': 'child',
      'restricted_notes': 'Peanut allergy',
      'version': 1,
    },
  ];

  final List<Map<String, dynamic>> items = [
    {
      'id': 'item-owner',
      'checklist_id': 'chk-1',
      'trip_id': 'trip-a',
      'title': 'Hotel Voucher',
      'category': 'documents',
      'is_packed': false,
      'quantity': 1,
      'assigned_user_id': 'owner-1',
      'assigned_user_name': 'Alice Organizer',
      'version': 1,
    },
    {
      'id': 'item-viewer',
      'checklist_id': 'chk-1',
      'trip_id': 'trip-a',
      'title': 'Train Pass',
      'category': 'documents',
      'is_packed': false,
      'quantity': 1,
      'assigned_user_id': 'viewer-1',
      'assigned_user_name': 'Bob Viewer',
      'version': 2,
    },
    {
      'id': 'item-leo',
      'checklist_id': 'chk-1',
      'trip_id': 'trip-a',
      'title': 'Kids Sunscreen',
      'category': 'toiletries',
      'is_packed': false,
      'quantity': 2,
      'assigned_traveler_id': 'trav-leo',
      'assigned_traveler_name': 'Leo',
      'version': 1,
    },
  ];

  Map<String, dynamic> _checklistPayload() {
    final total = items.length;
    final packed = items.where((i) => i['is_packed'] == true).length;
    return {
      'id': 'chk-1',
      'trip_id': 'trip-a',
      'title': 'Family Packing',
      'items': items.map((e) => Map<String, dynamic>.from(e)).toList(),
      'total_items_count': total,
      'packed_items_count': packed,
      'progress_percentage': total > 0 ? ((packed / total) * 100).round() : 0,
    };
  }

  Map<String, dynamic> _serializeTravelerForActor(Map<String, dynamic> raw) {
    final isManager = raw['managing_user_id'] == actorUserId;
    return {
      ...raw,
      'restricted_notes': isManager ? raw['restricted_notes'] : null,
      'can_edit': isManager,
      'can_delete': isManager,
    };
  }

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
    if (throwNetwork) {
      throw const NetworkException();
    }

    if (path == '/trips/trip-a/members') {
      return members;
    }
    if (path == '/trips/trip-a/travelers') {
      return travelers.map(_serializeTravelerForActor).toList();
    }
    if (path == '/trips/trip-a/checklists') {
      return [_checklistPayload()];
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

    if (throwNetwork) {
      throw const NetworkException();
    }

    if (path == '/trips/trip-a/travelers') {
      final created = {
        'id': 'trav-new',
        'trip_id': 'trip-a',
        'managing_user_id': actorUserId,
        'managing_user_name': actorUserId == 'owner-1'
            ? 'Alice Organizer'
            : 'Bob Viewer',
        'display_name': lastPostData?['display_name'] ?? 'Traveler',
        'traveler_category': lastPostData?['traveler_category'] ?? 'child',
        'restricted_notes': lastPostData?['restricted_notes'],
        'version': 1,
      };
      travelers.add(created);
      return _serializeTravelerForActor(created);
    }

    if (path == '/checklists/chk-1/items') {
      final assignedUserId = lastPostData?['assigned_user_id'] as String?;
      final assignedTravelerId =
          lastPostData?['assigned_traveler_id'] as String?;
      final userName = assignedUserId == null
          ? null
          : members.firstWhere(
                  (m) => m['user_id'] == assignedUserId,
                  orElse: () => {'display_name': 'Member'},
                )['display_name']
                as String?;
      final travelerName = assignedTravelerId == null
          ? null
          : travelers.firstWhere(
                  (t) => t['id'] == assignedTravelerId,
                  orElse: () => {'display_name': 'Traveler'},
                )['display_name']
                as String?;

      final created = <String, dynamic>{
        'id': 'item-created-${items.length + 1}',
        'checklist_id': 'chk-1',
        'trip_id': 'trip-a',
        'title': lastPostData?['title'] ?? 'New Item',
        'category': lastPostData?['category'] ?? 'other',
        'is_packed': false,
        'quantity': lastPostData?['quantity'] ?? 1,
        'notes': lastPostData?['notes'],
        'photo_url': lastPostData?['photo_url'],
        'assigned_user_id': ?assignedUserId,
        'assigned_user_name': ?userName,
        'assigned_traveler_id': ?assignedTravelerId,
        'assigned_traveler_name': ?travelerName,
        'version': 1,
      };
      items.add(created);
      return created;
    }

    if (path.startsWith('/checklist-items/') && path.endsWith('/toggle')) {
      final itemId = path.split('/')[2];
      toggleCalls.add(itemId);
      if (throwConflictOnToggle) {
        throw const ConflictException(
          message: 'Checklist item was updated on another device.',
          details: {
            'server_version': 5,
            'server_payload': {
              'id': 'item-viewer',
              'is_packed': true,
              'version': 5,
            },
          },
        );
      }
      final idx = items.indexWhere((i) => i['id'] == itemId);
      if (idx >= 0) {
        final nextPacked = !(items[idx]['is_packed'] == true);
        final actorName = actorUserId == 'owner-1'
            ? 'Alice Organizer'
            : 'Bob Viewer';
        items[idx] = {
          ...items[idx],
          'is_packed': nextPacked,
          'completed_by_user_id': nextPacked ? actorUserId : null,
          'completed_by_name': nextPacked ? actorName : null,
          'version': ((items[idx]['version'] as num?)?.toInt() ?? 1) + 1,
        };
        return items[idx];
      }
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

    if (throwNetwork) {
      throw const NetworkException();
    }

    if (path.startsWith('/checklist-items/')) {
      final itemId = path.split('/')[2];
      final idx = items.indexWhere((i) => i['id'] == itemId);
      if (idx >= 0) {
        final updated = Map<String, dynamic>.from(items[idx]);
        if (lastPatchData!.containsKey('title')) {
          updated['title'] = lastPatchData!['title'];
        }
        if (lastPatchData!.containsKey('assigned_user_id') &&
            lastPatchData!['assigned_user_id'] == null) {
          updated.remove('assigned_user_id');
          updated.remove('assigned_user_name');
        } else if (lastPatchData!['assigned_user_id'] != null) {
          updated['assigned_user_id'] = lastPatchData!['assigned_user_id'];
        }
        if (lastPatchData!.containsKey('assigned_traveler_id') &&
            lastPatchData!['assigned_traveler_id'] == null) {
          updated.remove('assigned_traveler_id');
          updated.remove('assigned_traveler_name');
        } else if (lastPatchData!['assigned_traveler_id'] != null) {
          updated['assigned_traveler_id'] =
              lastPatchData!['assigned_traveler_id'];
        }
        updated['version'] = ((updated['version'] as num?)?.toInt() ?? 1) + 1;
        items[idx] = updated;
        return updated;
      }
    }

    return const {};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TC-6 Managed Travelers & Collaborative Checklist Assignments', () {
    test('TC-6.1 models parse and clear assignee fields properly', () {
      final item = ChecklistItem.fromJson({
        'id': 'item-1',
        'checklist_id': 'chk-1',
        'trip_id': 'trip-a',
        'title': 'Stroller Rain Cover',
        'category': 'gear',
        'is_packed': true,
        'quantity': 1,
        'assigned_traveler_id': 'trav-leo',
        'assigned_traveler_name': 'Leo',
        'completed_by_user_id': 'owner-1',
        'completed_by_name': 'Alice Organizer',
        'version': 3,
      });

      expect(item.assignedTravelerId, 'trav-leo');
      expect(item.assigneeLabel, 'Leo');
      expect(item.completedByName, 'Alice Organizer');
      expect(item.version, 3);

      final cleared = item.copyWith(clearAssignee: true);
      expect(cleared.assignedUserId, isNull);
      expect(cleared.assignedTravelerId, isNull);
      expect(cleared.assigneeLabel, isNull);

      final traveler = TripTraveler.fromJson({
        'id': 'trav-leo',
        'trip_id': 'trip-a',
        'managing_user_id': 'owner-1',
        'managing_user_name': 'Alice Organizer',
        'display_name': 'Leo',
        'traveler_category': 'child',
        'restricted_notes': null,
        'can_edit': false,
        'can_delete': false,
        'version': 2,
      });

      expect(traveler.categoryLabel, 'Child');
      expect(traveler.restrictedNotes, isNull);
      expect(traveler.canEdit, isFalse);
      expect(traveler.version, 2);
    });

    testWidgets(
      'TC-6.1 organizer filters by assignee and assigns new item to managed traveler',
      (tester) async {
        final api = _FakeSlice4ApiClient(actorUserId: 'owner-1');
        final storage = _InMemorySecureStorage();
        final outbox = InMemoryOutboxStorage();
        final circleRepo = TripCircleRepository(
          apiClient: api,
          storage: storage,
        );
        final checklistRepo = ChecklistRepository(
          apiClient: api,
          storage: storage,
        );
        final syncService = SyncService(apiClient: api, outboxStorage: outbox);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                () => _FakeAuthNotifier(
                  userId: 'owner-1',
                  displayName: 'Alice Organizer',
                ),
              ),
              tripCircleRepositoryProvider.overrideWithValue(circleRepo),
              checklistRepositoryProvider.overrideWithValue(checklistRepo),
              outboxStorageProvider.overrideWithValue(outbox),
              syncServiceProvider.overrideWithValue(syncService),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: ChecklistsView(tripId: 'trip-a'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hotel Voucher'), findsOneWidget);
        expect(find.text('Train Pass'), findsOneWidget);
        expect(find.text('Kids Sunscreen'), findsOneWidget);
        expect(find.text('For Leo (Managed)'), findsOneWidget);
        expect(find.text('Assigned: Bob Viewer'), findsOneWidget);

        // Filter by managed traveler "Leo"
        await tester.tap(find.widgetWithText(ChoiceChip, 'Leo'));
        await tester.pumpAndSettle();

        expect(find.text('Kids Sunscreen'), findsOneWidget);
        expect(find.text('Train Pass'), findsNothing);
        expect(find.text('Hotel Voucher'), findsNothing);

        // Reset filter & assign a new item to Leo via AddChecklistItemBottomSheet
        await tester.tap(find.widgetWithText(ChoiceChip, 'All assignees'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add Item'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Item Name *'),
          'Rain Poncho',
        );
        final assignDropdown = find.text('Unassigned (Anyone)');
        await tester.ensureVisible(assignDropdown);
        await tester.tap(assignDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Leo (Child)').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Add to List'));
        await tester.tap(find.text('Add to List'));
        await tester.pumpAndSettle();

        expect(api.lastPostPath, '/checklists/chk-1/items');
        expect(api.lastPostData?['assigned_traveler_id'], 'trav-leo');
        expect(api.lastPostData?['assigned_user_id'], isNull);
        expect(find.text('Rain Poncho'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-6.2 viewer toggles only own assigned item and has no edit/delete or manage controls',
      (tester) async {
        final api = _FakeSlice4ApiClient(actorUserId: 'viewer-1');
        final storage = _InMemorySecureStorage();
        final outbox = InMemoryOutboxStorage();
        final circleRepo = TripCircleRepository(
          apiClient: api,
          storage: storage,
        );
        final checklistRepo = ChecklistRepository(
          apiClient: api,
          storage: storage,
        );
        final syncService = SyncService(apiClient: api, outboxStorage: outbox);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                () => _FakeAuthNotifier(
                  userId: 'viewer-1',
                  displayName: 'Bob Viewer',
                ),
              ),
              tripCircleRepositoryProvider.overrideWithValue(circleRepo),
              checklistRepositoryProvider.overrideWithValue(checklistRepo),
              outboxStorageProvider.overrideWithValue(outbox),
              syncServiceProvider.overrideWithValue(syncService),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: ChecklistsView(tripId: 'trip-a'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'View-only access: you can check off items assigned to you.',
          ),
          findsOneWidget,
        );
        expect(find.text('Add Item'), findsNothing);
        expect(find.byTooltip('Starter Packs'), findsNothing);
        expect(find.byTooltip('New List'), findsNothing);
        expect(find.byType(PopupMenuButton<String>), findsNothing);

        // Tapping someone else's assigned item does not toggle
        await tester.tap(find.text('Hotel Voucher'));
        await tester.pumpAndSettle();
        expect(api.toggleCalls, isEmpty);

        // Tapping own assigned item toggles via API with base_version & attribution
        await tester.tap(find.text('Train Pass'));
        await tester.pumpAndSettle();

        expect(api.toggleCalls, ['item-viewer']);
        expect(api.lastPostPath, '/checklist-items/item-viewer/toggle');
        expect(api.lastPostData?['base_version'], 2);
        expect(find.text('Packed by Bob Viewer'), findsOneWidget);
      },
    );

    test('TC-6.2 offline completion survives restart in cache/outbox, 409 records conflict, and 403 purges cache', () async {
      final api = _FakeSlice4ApiClient(actorUserId: 'viewer-1');
      final storage = _InMemorySecureStorage();
      final outbox = InMemoryOutboxStorage();
      final syncService = SyncService(apiClient: api, outboxStorage: outbox);

      final container1 = ProviderContainer(
        overrides: [
          checklistRepositoryProvider.overrideWithValue(
            ChecklistRepository(apiClient: api, storage: storage),
          ),
          outboxStorageProvider.overrideWithValue(outbox),
          syncServiceProvider.overrideWithValue(syncService),
        ],
      );

      final loaded = await container1.read(
        checklistListProvider('trip-a').future,
      );
      expect(loaded, hasLength(1));

      // 1. Go offline and toggle viewer's item
      api.throwNetwork = true;
      await container1
          .read(checklistListProvider('trip-a').notifier)
          .toggleItem('item-viewer');

      expect(container1.read(syncProvider).status, SyncStatus.pending);
      final queuedOps = await outbox.getPendingOperations();
      expect(queuedOps, hasLength(1));
      expect(queuedOps.first.entityType, 'checklist_item');
      expect(queuedOps.first.entityId, 'item-viewer');
      expect(queuedOps.first.baseVersion, 2);
      expect(queuedOps.first.payload?['is_packed'], isTrue);
      container1.dispose();

      // 2. Simulate app restart with fresh ProviderContainer while still offline
      final container2 = ProviderContainer(
        overrides: [
          checklistRepositoryProvider.overrideWithValue(
            ChecklistRepository(apiClient: api, storage: storage),
          ),
          outboxStorageProvider.overrideWithValue(outbox),
          syncServiceProvider.overrideWithValue(
            SyncService(apiClient: api, outboxStorage: outbox),
          ),
        ],
      );
      addTearDown(container2.dispose);

      final restored = await container2.read(
        checklistListProvider('trip-a').future,
      );
      final restoredItem = restored.first.items.firstWhere(
        (i) => i.id == 'item-viewer',
      );
      expect(restoredItem.isPacked, isTrue);
      expect(await outbox.getPendingOperations(), hasLength(1));

      // 3. Reconnect with stale version 409 conflict
      await outbox.clear();
      api.throwNetwork = false;
      api.throwConflictOnToggle = true;

      await expectLater(
        () => container2
            .read(checklistListProvider('trip-a').notifier)
            .toggleItem('item-viewer'),
        throwsA(isA<ConflictException>()),
      );
      expect(container2.read(syncProvider).status, SyncStatus.conflict);
      final allOps = await outbox.getAllOperations();
      expect(allOps.any((op) => op.status == 'conflict'), isTrue);

      // 4. Member removed -> 403 purges cached checklists and travelers
      final circleRepo = TripCircleRepository(apiClient: api, storage: storage);
      await circleRepo.getTravelers('trip-a');
      expect(storage.rawValue('cached_checklists_trip-a'), isNotNull);
      expect(storage.rawValue('cached_travelers_trip-a'), isNotNull);

      api.throwForbiddenOnTripA = true;
      await expectLater(
        () => ChecklistRepository(
          apiClient: api,
          storage: storage,
        ).fetchChecklists('trip-a'),
        throwsA(isA<ApiException>()),
      );
      expect(storage.rawValue('cached_checklists_trip-a'), isNull);
      expect(storage.rawValue('cached_travelers_trip-a'), isNull);
    });

    testWidgets(
      'TC-6.3 ManagedTravelersSection shows private notes only to manager and allows creating minimal profile',
      (tester) async {
        // Non-managing viewer view: private note redacted & add/edit/delete hidden
        final viewerApi = _FakeSlice4ApiClient(actorUserId: 'viewer-1');
        final viewerStorage = _InMemorySecureStorage();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tripCircleRepositoryProvider.overrideWithValue(
                TripCircleRepository(
                  apiClient: viewerApi,
                  storage: viewerStorage,
                ),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: ManagedTravelersSection(
                    tripId: 'trip-a',
                    canManageTravelers: false,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Managed Travelers'), findsOneWidget);
        expect(
          find.textContaining('without creating an account'),
          findsOneWidget,
        );
        expect(find.text('Leo'), findsOneWidget);
        expect(find.text('Managed by Alice Organizer'), findsOneWidget);
        expect(find.textContaining('Peanut allergy'), findsNothing);
        expect(find.text('Add'), findsNothing);
        expect(find.byTooltip('Edit traveler'), findsNothing);
        expect(find.byTooltip('Remove traveler'), findsNothing);

        // Managing organizer view: sees own private note & can create new minimal profile
        final ownerApi = _FakeSlice4ApiClient(actorUserId: 'owner-1');
        final ownerStorage = _InMemorySecureStorage();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tripCircleRepositoryProvider.overrideWithValue(
                TripCircleRepository(
                  apiClient: ownerApi,
                  storage: ownerStorage,
                ),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: ManagedTravelersSection(
                    tripId: 'trip-a',
                    canManageTravelers: true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Private note: Peanut allergy'), findsOneWidget);
        expect(find.byTooltip('Edit traveler'), findsOneWidget);
        expect(find.byTooltip('Remove traveler'), findsOneWidget);

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'First Name or Nickname *'),
          'Max',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Private Notes (visible only to you)'),
          'Needs travel crib',
        );
        await tester.tap(find.text('Save Traveler'));
        await tester.pumpAndSettle();

        expect(ownerApi.lastPostPath, '/trips/trip-a/travelers');
        expect(ownerApi.lastPostData?['display_name'], 'Max');
        expect(ownerApi.lastPostData?['restricted_notes'], 'Needs travel crib');
        expect(find.text('Max'), findsOneWidget);
      },
    );
  });
}
