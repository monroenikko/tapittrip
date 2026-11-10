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
import 'package:tapittrip/features/expenses/data/currency_repository.dart';
import 'package:tapittrip/features/expenses/data/expense_repository.dart';
import 'package:tapittrip/features/expenses/presentation/pages/trip_expenses_page.dart';
import 'package:tapittrip/features/expenses/presentation/providers/expense_provider.dart';
import 'package:tapittrip/features/expenses/presentation/widgets/add_expense_bottom_sheet.dart';
import 'package:tapittrip/features/expenses/presentation/widgets/settle_up_dialog.dart';
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
        homeCurrency: 'USD',
        email: '$userId@example.com',
      ),
    );
  }
}

class _FakeSlice5ApiClient extends ApiClient {
  _FakeSlice5ApiClient() : super(tokenStorage: InMemoryTokenStorage());

  bool throwNetwork = false;
  bool throwRateUnavailable = false;
  bool throwConflictOnPatch = false;
  bool throwForbiddenOnTripA = false;

  String? lastPostPath;
  Map<String, dynamic>? lastPostData;
  String? lastPatchPath;
  Map<String, dynamic>? lastPatchData;

  final List<Map<String, dynamic>> members = [
    {
      'id': 'mem-1',
      'trip_id': 'trip-a',
      'user_id': 'u-alice',
      'display_name': 'Alice',
      'role': 'owner',
      'invitation_status': 'accepted',
    },
    {
      'id': 'mem-2',
      'trip_id': 'trip-a',
      'user_id': 'u-bob',
      'display_name': 'Bob',
      'role': 'editor',
      'invitation_status': 'accepted',
    },
    {
      'id': 'mem-3',
      'trip_id': 'trip-a',
      'user_id': 'u-charlie',
      'display_name': 'Charlie',
      'role': 'viewer',
      'invitation_status': 'accepted',
    },
  ];

  final List<Map<String, dynamic>> expenses = [
    {
      'id': 'exp-1',
      'trip_id': 'trip-a',
      'payer_id': 'u-alice',
      'created_by_user_id': 'u-alice',
      'category': 'dining',
      'title': 'Offline Ramen Bar',
      'amount_minor': 4000,
      'currency': 'JPY',
      'exchange_rate': null,
      'rate_source': 'unavailable',
      'conversion_status': 'unavailable',
      'base_amount_minor': null,
      'expense_date': '2026-11-10',
      'split_type': 'equal',
      'visibility': 'shared',
      'version': 2,
      'payer': {'id': 'u-alice', 'name': 'Alice'},
      'splits': [
        {'user_id': 'u-alice', 'amount_minor': 2000},
        {'user_id': 'u-bob', 'amount_minor': 2000},
      ],
    },
  ];

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

    if (path == '/currencies/rates') {
      if (throwNetwork) throw const NetworkException();
      if (throwRateUnavailable) {
        throw const ApiException(
          code: 'exchange_rate_unavailable',
          message: 'Exchange rate unavailable.',
          statusCode: 503,
        );
      }
      return {
        'data': {
          'from': queryParameters?['from'] ?? 'JPY',
          'to': queryParameters?['to'] ?? 'USD',
          'rate': 0.007,
          'reciprocal_rate': 142.8571,
          'as_of': '2026-11-10T10:00:00Z',
          'provider': 'open_exchange_rates',
          'available': true,
        },
      };
    }

    if (throwNetwork) {
      throw const NetworkException();
    }

    if (path == '/trips/trip-a/members') {
      return members;
    }
    if (path == '/trips/trip-a/travelers') {
      return const [];
    }
    if (path == '/trips/trip-a/budget') {
      return {
        'data': {
          'id': 'b-1',
          'trip_id': 'trip-a',
          'currency': 'USD',
          'total_budget_minor': 100000,
        },
      };
    }
    if (path == '/trips/trip-a/expenses') {
      return {'data': expenses};
    }
    if (path == '/trips/trip-a/expenses/summary') {
      return {
        'data': {
          'trip_id': 'trip-a',
          'base_currency': 'USD',
          'total_budget_minor': 100000,
          'total_spent_base_minor': 3000,
          'shared_spent_base_minor': 2000,
          'personal_spent_base_minor': 1000,
          'remaining_budget_minor': 97000,
          'budget_utilization_percent': 3.0,
          'expenses_count': expenses.length,
          'unconverted_expenses_count': 1,
          'unconverted_totals': [
            {'currency': 'JPY', 'amount_minor': 4000, 'count': 1},
          ],
          'accounting_notice': 'Tracks recorded expenses and balances only; TapItTrip does not process or verify real money transfers.',
          'category_breakdown': const [],
          'daily_spending': const [],
        },
      };
    }
    if (path == '/trips/trip-a/settlements') {
      return {
        'data': {
          'trip_id': 'trip-a',
          'base_currency': 'USD',
          'balances': [
            {
              'user_id': 'u-alice',
              'name': 'Alice',
              'net_balance_minor': 1000,
              'status': 'is_owed',
              'is_departed': false,
            },
            {
              'user_id': 'u-bob',
              'name': 'Bob',
              'net_balance_minor': -1000,
              'status': 'owes',
              'is_departed': true,
            },
          ],
          'suggested_settlements': [
            {
              'payer_id': 'u-bob',
              'payer_name': 'Bob',
              'payee_id': 'u-alice',
              'payee_name': 'Alice',
              'amount_minor': 1000,
              'currency': 'USD',
            },
          ],
          'settlement_history': const [],
          'per_currency_balances': {
            'USD': [
              {
                'user_id': 'u-alice',
                'name': 'Alice',
                'net_balance_minor': 1000,
                'status': 'is_owed',
              },
              {
                'user_id': 'u-bob',
                'name': 'Bob',
                'net_balance_minor': -1000,
                'status': 'owes',
              },
            ],
            'JPY': [
              {
                'user_id': 'u-alice',
                'name': 'Alice',
                'net_balance_minor': 2000,
                'status': 'is_owed',
              },
              {
                'user_id': 'u-bob',
                'name': 'Bob',
                'net_balance_minor': -2000,
                'status': 'owes',
              },
            ],
          },
          'unconverted_expenses': [
            {
              'id': 'exp-1',
              'title': 'Offline Ramen Bar',
              'amount_minor': 4000,
              'currency': 'JPY',
              'payer_id': 'u-alice',
              'payer_name': 'Alice',
              'expense_date': '2026-11-10',
              'reason': 'exchange_rate_unavailable',
            },
          ],
          'accounting_notice': 'Balances and settlements are trip ledger records only; TapItTrip does not transfer funds or verify external payments.',
        },
      };
    }

    return const {'data': null};
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

    if (path == '/trips/trip-a/expenses') {
      final created = {
        'id': 'exp-created-${expenses.length + 1}',
        'trip_id': 'trip-a',
        'payer_id': lastPostData?['payer_id'] ?? 'u-alice',
        'created_by_user_id': 'u-alice',
        'category': lastPostData?['category'] ?? 'dining',
        'title': lastPostData?['title'] ?? 'Created',
        'amount_minor': lastPostData?['amount_minor'] ?? 1000,
        'currency': lastPostData?['currency'] ?? 'USD',
        'exchange_rate': lastPostData?['exchange_rate'],
        'rate_source': lastPostData?['rate_source'] ?? 'identity',
        'conversion_status': lastPostData?['conversion_status'] ?? 'converted',
        'base_amount_minor': lastPostData?['conversion_status'] == 'unavailable'
            ? null
            : lastPostData?['amount_minor'],
        'expense_date': lastPostData?['expense_date'] ?? '2026-11-10',
        'split_type': lastPostData?['split_type'] ?? 'single',
        'visibility': lastPostData?['visibility'] ?? 'private',
        'version': 1,
        'client_operation_id': lastPostData?['client_operation_id'],
      };
      expenses.insert(0, created);
      return {'data': created};
    }

    if (path == '/trips/trip-a/settlements') {
      return {
        'data': {
          'id': 'set-1',
          'trip_id': 'trip-a',
          'payer_id': lastPostData?['payer_id'] ?? 'u-bob',
          'payee_id': lastPostData?['payee_id'] ?? 'u-alice',
          'amount_minor': lastPostData?['amount_minor'] ?? 1000,
          'currency': lastPostData?['currency'] ?? 'USD',
          'settled_at': '2026-11-10T10:00:00Z',
          'notes': lastPostData?['notes'],
          'client_operation_id': lastPostData?['client_operation_id'],
        },
      };
    }

    return const {'data': {}};
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
      throw const ConflictException(
        message: 'Expense was modified on another device.',
        details: {
          'server_version': 3,
          'server_payload': {
            'id': 'exp-1',
            'title': 'Server Ramen Edit',
            'version': 3,
          },
        },
      );
    }

    if (throwNetwork) {
      throw const NetworkException();
    }

    return {'data': expenses.first};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TC-7 Group Expense Splits, Multi-Currency & Privacy UI', () {
    test(
      'TC-7.1 allocateEqualMinor distributes odd minor units without drift',
      () {
        final shares = ExpenseRepository.allocateEqualMinor(1001, [
          'u-1',
          'u-2',
          'u-3',
        ]);
        expect(shares['u-1'], 334);
        expect(shares['u-2'], 334);
        expect(shares['u-3'], 333);
        expect(shares.values.fold<int>(0, (a, b) => a + b), 1001);
      },
    );

    test('TC-7.2 CurrencyRepository never invents rates offline without a cached snapshot', () async {
      final api = _FakeSlice5ApiClient();
      final storage = _InMemorySecureStorage();
      final repo = CurrencyRepository(apiClient: api, secureStorage: storage);

      // 1. Offline with empty cache -> throws CurrencyRateUnavailableException and tryGetRateDetails marks unavailable
      api.throwRateUnavailable = true;
      await expectLater(
        () => repo.getRateDetails('JPY', 'USD'),
        throwsA(isA<CurrencyRateUnavailableException>()),
      );
      final unavailable = await repo.tryGetRateDetails('JPY', 'USD');
      expect(unavailable.isUnavailable, isTrue);
      expect(unavailable.provider, 'unavailable');

      // 2. Fetch live snapshot once -> cached snapshot is returned offline later with original attribution
      api.throwRateUnavailable = false;
      final fetched = await repo.getRateDetails('JPY', 'USD');
      expect(fetched.isAvailable, isTrue);
      expect(fetched.rate, 0.007);
      expect(fetched.provider, 'open_exchange_rates');

      api.throwNetwork = true;
      final offlineCached = await repo.getRateDetails('JPY', 'USD');
      expect(offlineCached.isOffline, isTrue);
      expect(offlineCached.isUnavailable, isFalse);
      expect(offlineCached.rate, 0.007);
      expect(offlineCached.provider, 'open_exchange_rates');
    });

    testWidgets(
      'TC-7.1 & TC-7.2 AddExpenseBottomSheet supports payer, selected splits, custom sum guard, and offline unavailable FX',
      (tester) async {
        final api = _FakeSlice5ApiClient();
        api.throwRateUnavailable = true;
        final storage = _InMemorySecureStorage();
        final expenseRepo = ExpenseRepository(apiClient: api, storage: storage);
        final circleRepo = TripCircleRepository(
          apiClient: api,
          storage: storage,
        );
        final currencyRepo = CurrencyRepository(
          apiClient: api,
          secureStorage: storage,
        );
        final outbox = InMemoryOutboxStorage();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                () =>
                    _FakeAuthNotifier(userId: 'u-alice', displayName: 'Alice'),
              ),
              expenseRepositoryProvider.overrideWithValue(expenseRepo),
              tripCircleRepositoryProvider.overrideWithValue(circleRepo),
              currencyRepositoryProvider.overrideWithValue(currencyRepo),
              outboxStorageProvider.overrideWithValue(outbox),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const Scaffold(
                body: AddExpenseBottomSheet(
                  tripId: 'trip-a',
                  defaultCurrency: 'JPY',
                  homeCurrency: 'USD',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'What did you pay for?'),
          'Shinkansen Tickets',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Amount'),
          '5000',
        );
        await tester.pumpAndSettle();

        // Honest unavailable rate banner instead of invented conversion
        expect(
          find.textContaining(
            'Conversion rate unavailable offline. Stored in JPY without inventing a conversion rate.',
          ),
          findsOneWidget,
        );

        // Select Paid by -> Bob
        final payerDropdown = find.text('Alice (You)');
        await tester.ensureVisible(payerDropdown);
        await tester.tap(payerDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bob').last);
        await tester.pumpAndSettle();

        // Choose Select travelers and exclude Alice
        await tester.ensureVisible(find.text('Select travelers'));
        await tester.tap(find.text('Select travelers'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilterChip, 'Alice'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Split across 2 travelers'), findsOneWidget);

        final logExpenseButton = find.widgetWithText(
          FilledButton,
          'Log Expense',
        );
        await tester.ensureVisible(logExpenseButton);
        await tester.tap(logExpenseButton);
        await tester.pumpAndSettle();

        expect(api.lastPostPath, '/trips/trip-a/expenses');
        expect(api.lastPostData?['payer_id'], 'u-bob');
        expect(api.lastPostData?['split_type'], 'selected');
        expect(api.lastPostData?['visibility'], 'shared');
        expect(api.lastPostData?['participant_ids'], ['u-bob', 'u-charlie']);
        expect(api.lastPostData?['conversion_status'], 'unavailable');
        expect(api.lastPostData?['rate_source'], 'unavailable');
        expect(api.lastPostData?['client_operation_id'], isNotNull);
      },
    );

    testWidgets(
      'TC-7.1 Custom split validation blocks mismatched sums before API call',
      (tester) async {
        final api = _FakeSlice5ApiClient();
        final storage = _InMemorySecureStorage();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                () =>
                    _FakeAuthNotifier(userId: 'u-alice', displayName: 'Alice'),
              ),
              expenseRepositoryProvider.overrideWithValue(
                ExpenseRepository(apiClient: api, storage: storage),
              ),
              tripCircleRepositoryProvider.overrideWithValue(
                TripCircleRepository(apiClient: api, storage: storage),
              ),
              currencyRepositoryProvider.overrideWithValue(
                CurrencyRepository(apiClient: api, secureStorage: storage),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const Scaffold(
                body: AddExpenseBottomSheet(
                  tripId: 'trip-a',
                  defaultCurrency: 'USD',
                  homeCurrency: 'USD',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'What did you pay for?'),
          'Museum Passes',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Amount'),
          '10.00',
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Custom amounts'));
        await tester.tap(find.text('Custom amounts'));
        await tester.pumpAndSettle();

        // Overwrite first share to create deliberate mismatch ($8 + $3.33 + $3.33 != $10.00)
        final shareFields = find.descendant(
          of: find.byType(AddExpenseBottomSheet),
          matching: find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.prefixText != null,
          ),
        );
        await tester.enterText(shareFields.first, '8.00');
        await tester.pumpAndSettle();

        final logExpenseButton = find.widgetWithText(
          FilledButton,
          'Log Expense',
        );
        await tester.ensureVisible(logExpenseButton);
        await tester.tap(logExpenseButton);
        await tester.pumpAndSettle();

        expect(api.lastPostPath, isNull);
        expect(find.textContaining('must equal total'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-7.2 & TC-7.3 TripExpensesPage enforces viewer read-only state, unconverted & multi-currency display, and SettleUpDialog disclaimer',
      (tester) async {
        final api = _FakeSlice5ApiClient();
        final storage = _InMemorySecureStorage();

        // Viewer mode hides write controls
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                () => _FakeAuthNotifier(
                  userId: 'u-charlie',
                  displayName: 'Charlie',
                ),
              ),
              expenseRepositoryProvider.overrideWithValue(
                ExpenseRepository(apiClient: api, storage: storage),
              ),
              tripCircleRepositoryProvider.overrideWithValue(
                TripCircleRepository(apiClient: api, storage: storage),
              ),
              currencyRepositoryProvider.overrideWithValue(
                CurrencyRepository(apiClient: api, secureStorage: storage),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TripExpensesPage(tripId: 'trip-a'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'View-only access: you can review shared trip expenses and group balances.',
          ),
          findsOneWidget,
        );
        expect(find.text('Log Expense'), findsNothing);
        expect(find.byTooltip('Trip Budget'), findsNothing);
        expect(find.byType(PopupMenuButton<String>), findsNothing);
        final verticalScrollable = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        );
        await tester.scrollUntilVisible(
          find.text('FX rate unavailable'),
          150,
          scrollable: verticalScrollable.first,
        );
        expect(find.text('FX rate unavailable'), findsOneWidget);

        await tester.tap(find.text('Balances & Settle'));
        await tester.pumpAndSettle();

        expect(find.text('Settle Up'), findsNothing);
        expect(
          find.text('Former companion (auditable history retained)'),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.textContaining('does not transfer funds'),
          150,
          scrollable: verticalScrollable.last,
        );
        expect(find.textContaining('does not transfer funds'), findsOneWidget);
        expect(
          find.textContaining('Unconverted Foreign Expenses'),
          findsOneWidget,
        );
        expect(find.text('By Currency Breakdown'), findsOneWidget);

        // SettleUpDialog directly renders honest ledger disclaimer & sends idempotency key
        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('settle_up_scope'),
            overrides: [
              expenseRepositoryProvider.overrideWithValue(
                ExpenseRepository(apiClient: api, storage: storage),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const Scaffold(
                body: SettleUpDialog(
                  tripId: 'trip-a',
                  payerId: 'u-bob',
                  payerName: 'Bob',
                  payeeId: 'u-alice',
                  payeeName: 'Alice',
                  initialAmountMinor: 1000,
                  currency: 'USD',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('does not transfer funds or verify payments'),
          findsOneWidget,
        );
        await tester.tap(find.text('Confirm Settle'));
        await tester.pumpAndSettle();
        expect(api.lastPostPath, '/trips/trip-a/settlements');
        expect(api.lastPostData?['client_operation_id'], isNotNull);
      },
    );

    test('TC-7.3 Offline expense queues in OutboxStorage across restart, 409 records conflict, and 403 purges caches', () async {
      final api = _FakeSlice5ApiClient();
      final storage = _InMemorySecureStorage();
      final outbox = InMemoryOutboxStorage();
      final syncService = SyncService(apiClient: api, outboxStorage: outbox);

      final container1 = ProviderContainer(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(
            ExpenseRepository(apiClient: api, storage: storage),
          ),
          outboxStorageProvider.overrideWithValue(outbox),
          syncServiceProvider.overrideWithValue(syncService),
        ],
      );

      final initial = await container1.read(
        tripExpensesProvider('trip-a').future,
      );
      expect(initial, hasLength(1));

      // 1. Offline addExpense persists to local cache & durable outbox
      api.throwNetwork = true;
      await container1
          .read(tripExpensesProvider('trip-a').notifier)
          .addExpense(
            payerId: 'u-alice',
            category: 'dining',
            title: 'Offline Matcha Cafe',
            amountMinor: 1500,
            currency: 'JPY',
            conversionStatus: 'unavailable',
            rateSource: 'unavailable',
            expenseDate: '2026-11-10',
            splitType: 'equal',
          );

      expect(container1.read(syncProvider).status, SyncStatus.pending);
      final pending = await outbox.getPendingOperations();
      expect(pending, hasLength(1));
      expect(pending.first.entityType, 'expense');
      expect(pending.first.operationType, 'create');
      expect(pending.first.payload?['title'], 'Offline Matcha Cafe');
      container1.dispose();

      // 2. Restart ProviderContainer offline -> cached offline item still present
      final container2 = ProviderContainer(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(
            ExpenseRepository(apiClient: api, storage: storage),
          ),
          outboxStorageProvider.overrideWithValue(outbox),
          syncServiceProvider.overrideWithValue(
            SyncService(apiClient: api, outboxStorage: outbox),
          ),
        ],
      );
      addTearDown(container2.dispose);

      final restored = await container2.read(
        tripExpensesProvider('trip-a').future,
      );
      expect(restored.any((e) => e.title == 'Offline Matcha Cafe'), isTrue);

      // 3. Online 409 ConflictException records conflict op and refreshes
      await outbox.clear();
      api.throwNetwork = false;
      api.throwConflictOnPatch = true;
      await container2.read(tripExpensesProvider('trip-a').notifier).refresh();

      await expectLater(
        () => container2
            .read(tripExpensesProvider('trip-a').notifier)
            .updateExpense('exp-1', title: 'Stale Rename'),
        throwsA(isA<ConflictException>()),
      );
      expect(api.lastPatchData?['base_version'], 2);
      expect(container2.read(syncProvider).status, SyncStatus.conflict);
      expect(
        (await outbox.getAllOperations()).any((op) => op.status == 'conflict'),
        isTrue,
      );

      // 4. Removed member 403 purges all expense/budget/summary/settlement caches
      final repo = ExpenseRepository(apiClient: api, storage: storage);
      await repo.getBudget('trip-a');
      await repo.getSummary('trip-a');
      await repo.getGroupBalances('trip-a');
      expect(storage.rawValue('cached_expenses_trip-a'), isNotNull);
      expect(storage.rawValue('cached_budget_trip-a'), isNotNull);
      expect(storage.rawValue('cached_summary_trip-a'), isNotNull);
      expect(storage.rawValue('cached_settlements_trip-a'), isNotNull);

      api.throwForbiddenOnTripA = true;
      await expectLater(
        () => repo.getExpenses('trip-a'),
        throwsA(isA<ApiException>()),
      );
      expect(storage.rawValue('cached_expenses_trip-a'), isNull);
      expect(storage.rawValue('cached_budget_trip-a'), isNull);
      expect(storage.rawValue('cached_summary_trip-a'), isNull);
      expect(storage.rawValue('cached_settlements_trip-a'), isNull);
    });
  });
}
