import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/checklists/data/checklist_repository.dart';
import 'package:tapittrip/features/checklists/domain/models/checklist.dart';
import 'package:tapittrip/features/checklists/domain/models/checklist_item.dart';
import 'package:tapittrip/features/checklists/presentation/providers/checklist_provider.dart';
import 'package:tapittrip/features/checklists/presentation/widgets/checklist_category_tabs.dart';
import 'package:tapittrip/features/checklists/presentation/widgets/checklist_item_tile.dart';
import 'package:tapittrip/features/checklists/presentation/widgets/checklist_progress_card.dart';
import 'package:tapittrip/features/checklists/presentation/widgets/checklists_view.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic getResponse;
  dynamic postResponse;
  dynamic patchResponse;
  bool shouldThrow = false;
  ApiException? exceptionToThrow;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const NetworkException();
    }
    return getResponse;
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const NetworkException();
    }
    return postResponse;
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const NetworkException();
    }
    return patchResponse;
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const NetworkException();
    }
    return null;
  }
}

class FakeSecureStorage extends FlutterSecureStorage {
  FakeSecureStorage([Map<String, String>? initial])
    : _data = initial != null ? Map.from(initial) : {};

  final Map<String, String> _data;

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
    return _data[key];
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
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }
}

void main() {
  group('Checklist & ChecklistItem Models', () {
    test('ChecklistItem parses from JSON and serializes correctly', () {
      final json = {
        'id': 'item-1',
        'checklist_id': 'check-1',
        'trip_id': 'trip-1',
        'title': 'Passport',
        'category': 'documents',
        'is_packed': true,
        'quantity': 2,
        'notes': 'Keep in daypack',
        'packed_at': '2026-05-10T12:00:00Z',
        'version': 2,
      };

      final item = ChecklistItem.fromJson(json);

      expect(item.id, 'item-1');
      expect(item.title, 'Passport');
      expect(item.category, 'documents');
      expect(item.isPacked, isTrue);
      expect(item.quantity, 2);
      expect(item.notes, 'Keep in daypack');
      expect(item.version, 2);

      final serialized = item.toJson();
      expect(serialized['id'], 'item-1');
      expect(serialized['title'], 'Passport');
      expect(serialized['is_packed'], isTrue);
      expect(serialized['quantity'], 2);
    });

    test('Checklist calculates progress percentage dynamically', () {
      final item1 = const ChecklistItem(
        id: '1',
        checklistId: 'c1',
        tripId: 't1',
        title: 'Item 1',
        isPacked: true,
      );
      final item2 = const ChecklistItem(
        id: '2',
        checklistId: 'c1',
        tripId: 't1',
        title: 'Item 2',
        isPacked: false,
      );

      final checklist = Checklist(
        id: 'c1',
        tripId: 't1',
        title: 'Main List',
        items: [item1, item2],
      );

      expect(checklist.totalItemsCount, 2);
      expect(checklist.packedItemsCount, 1);
      expect(checklist.progressPercentage, 50);
    });
  });

  group('ChecklistRepository Offline & Network', () {
    test('fetches checklists and caches to local storage', () async {
      final fakeApi = FakeApiClient();
      final fakeStorage = FakeSecureStorage();
      final repo = ChecklistRepository(
        apiClient: fakeApi,
        storage: fakeStorage,
      );

      fakeApi.getResponse = [
        {
          'id': 'cl-1',
          'trip_id': 'trip-100',
          'title': 'Packing Essentials',
          'type': 'packing',
          'sort_order': 0,
          'total_items_count': 1,
          'packed_items_count': 0,
          'progress_percentage': 0,
          'items': [
            {
              'id': 'item-1',
              'checklist_id': 'cl-1',
              'trip_id': 'trip-100',
              'title': 'Universal Adapter',
              'category': 'electronics',
              'is_packed': false,
              'quantity': 1,
              'version': 1,
            },
          ],
        },
      ];

      final lists = await repo.fetchChecklists('trip-100');
      expect(lists.length, 1);
      expect(lists.first.title, 'Packing Essentials');
      expect(lists.first.items.length, 1);

      // Verify cached in secure storage
      final cached = await fakeStorage.read(key: 'cached_checklists_trip-100');
      expect(cached, isNotNull);
      final decoded = jsonDecode(cached!) as List;
      expect(decoded.length, 1);
    });

    test('falls back to offline cache on network failure', () async {
      final fakeApi = FakeApiClient();
      final fakeStorage = FakeSecureStorage({
        'cached_checklists_trip-offline': jsonEncode([
          {
            'id': 'cl-offline',
            'trip_id': 'trip-offline',
            'title': 'Cached Offline Pack',
            'type': 'packing',
            'sort_order': 0,
            'total_items_count': 0,
            'packed_items_count': 0,
            'progress_percentage': 0,
            'items': [],
          },
        ]),
      });

      fakeApi.shouldThrow = true;
      fakeApi.exceptionToThrow = const NetworkException();

      final repo = ChecklistRepository(
        apiClient: fakeApi,
        storage: fakeStorage,
      );

      final lists = await repo.fetchChecklists('trip-offline');
      expect(lists.length, 1);
      expect(lists.first.title, 'Cached Offline Pack');
    });
  });

  group('Checklist UI Widgets', () {
    testWidgets('ChecklistProgressCard renders progress and completion badge', (
      tester,
    ) async {
      // 1. Incomplete state (1 of 2 packed)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: ChecklistProgressCard(
              totalItems: 2,
              packedItems: 1,
              progressPercentage: 50,
              checklistTitle: 'Japan Packing',
            ),
          ),
        ),
      );

      expect(find.text('Japan Packing'), findsOneWidget);
      expect(find.text('1 of 2 packed'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('All packed and ready for departure! 🎉'), findsNothing);

      // 2. Complete state (2 of 2 packed)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: ChecklistProgressCard(
              totalItems: 2,
              packedItems: 2,
              progressPercentage: 100,
              checklistTitle: 'Japan Packing',
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(
        find.text('All packed and ready for departure! 🎉'),
        findsOneWidget,
      );
    });

    testWidgets(
      'ChecklistCategoryTabs switches categories and displays counts',
      (tester) async {
        String selected = 'all';

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (ctx, setState) {
                  return ChecklistCategoryTabs(
                    selectedCategory: selected,
                    categoryCounts: const {
                      'all': 5,
                      'documents': 2,
                      'electronics': 3,
                    },
                    onCategorySelected: (cat) {
                      setState(() => selected = cat);
                    },
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('All (5)'), findsOneWidget);
        expect(find.text('Documents (2)'), findsOneWidget);
        expect(find.text('Electronics (3)'), findsOneWidget);

        await tester.tap(find.text('Documents (2)'));
        await tester.pumpAndSettle();

        expect(selected, 'documents');
      },
    );

    testWidgets('ChecklistItemTile displays info and triggers onToggle', (
      tester,
    ) async {
      bool toggled = false;
      const item = ChecklistItem(
        id: 'item-1',
        checklistId: 'c1',
        tripId: 't1',
        title: 'Sony Noise-Cancelling Headphones',
        category: 'electronics',
        quantity: 2,
        notes: 'Pack in carry-on',
        isPacked: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ChecklistItemTile(item: item, onToggle: () => toggled = true),
          ),
        ),
      );

      expect(find.text('Sony Noise-Cancelling Headphones'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
      expect(find.text('Pack in carry-on'), findsOneWidget);

      await tester.tap(find.byType(ChecklistItemTile));
      await tester.pump();

      expect(toggled, isTrue);
    });

    testWidgets('ChecklistsView renders checklists and allows item checkoff', (
      tester,
    ) async {
      final fakeApi = FakeApiClient();
      final fakeStorage = FakeSecureStorage();

      final initialChecklists = [
        Checklist(
          id: 'cl-tokyo',
          tripId: 'trip-tokyo',
          title: 'Tokyo Pack',
          totalItemsCount: 2,
          packedItemsCount: 0,
          progressPercentage: 0,
          items: const [
            ChecklistItem(
              id: 'it-1',
              checklistId: 'cl-tokyo',
              tripId: 'trip-tokyo',
              title: 'JR Rail Pass Voucher',
              category: 'documents',
              isPacked: false,
            ),
            ChecklistItem(
              id: 'it-2',
              checklistId: 'cl-tokyo',
              tripId: 'trip-tokyo',
              title: 'Pocket WiFi / e-SIM',
              category: 'electronics',
              isPacked: false,
            ),
          ],
        ),
      ];

      fakeApi.getResponse = initialChecklists.map((c) => c.toJson()).toList();
      fakeApi.postResponse = {
        'id': 'it-1',
        'checklist_id': 'cl-tokyo',
        'trip_id': 'trip-tokyo',
        'title': 'JR Rail Pass Voucher',
        'category': 'documents',
        'is_packed': true,
        'quantity': 1,
        'version': 2,
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            checklistRepositoryProvider.overrideWithValue(
              ChecklistRepository(apiClient: fakeApi, storage: fakeStorage),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: ChecklistsView(tripId: 'trip-tokyo'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tokyo Pack'), findsNWidgets(2)); // chip and title
      expect(find.text('JR Rail Pass Voucher'), findsOneWidget);
      expect(find.text('Pocket WiFi / e-SIM'), findsOneWidget);
      expect(find.text('0 of 2 packed'), findsOneWidget);

      // Tap on JR Rail Pass Voucher tile to toggle packed
      await tester.tap(find.text('JR Rail Pass Voucher'));
      await tester.pumpAndSettle();

      // Optimistic update reflects 1 of 2 packed immediately!
      expect(find.text('1 of 2 packed'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });
  });
}
