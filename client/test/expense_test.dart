import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/features/expenses/data/expense_repository.dart';
import 'package:tapittrip/features/expenses/domain/models/expense.dart';
import 'package:tapittrip/features/expenses/domain/models/expense_summary.dart';
import 'package:tapittrip/features/expenses/domain/models/trip_budget.dart';
import 'package:tapittrip/features/expenses/presentation/pages/trip_expenses_page.dart';
import 'package:tapittrip/features/expenses/presentation/providers/expense_provider.dart';
import 'package:tapittrip/features/expenses/presentation/widgets/add_expense_bottom_sheet.dart';

class FakeExpenseApiClient extends ApiClient {
  FakeExpenseApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic getResponse;
  dynamic postResponse;
  dynamic patchResponse;
  String? lastGetPath;
  String? lastPostPath;
  dynamic lastPostData;
  String? lastPatchPath;
  dynamic lastPatchData;
  String? lastDeletePath;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastGetPath = path;
    if (path.contains('/budget')) {
      return getResponse ??
          {
            'data': {
              'id': 'b-1',
              'trip_id': 't-1',
              'currency': 'USD',
              'total_budget_minor': 100000,
              'daily_budget_minor': 20000,
            },
          };
    }
    if (path.contains('/summary')) {
      return getResponse ??
          {
            'data': {
              'trip_id': 't-1',
              'base_currency': 'USD',
              'total_budget_minor': 100000,
              'daily_budget_minor': 20000,
              'total_spent_base_minor': 2500,
              'remaining_budget_minor': 97500,
              'budget_utilization_percent': 2.5,
              'expenses_count': 1,
              'category_breakdown': [
                {
                  'category': 'dining',
                  'amount_minor': 2500,
                  'count': 1,
                  'percent': 100.0,
                },
              ],
              'daily_spending': [
                {'date': '2026-11-10', 'amount_minor': 2500, 'count': 1},
              ],
            },
          };
    }
    return getResponse ??
        {
          'data': [
            {
              'id': 'exp-1',
              'trip_id': 't-1',
              'payer_id': 'u-1',
              'category': 'dining',
              'title': 'Ramen in Shibuya',
              'amount_minor': 3000,
              'currency': 'JPY',
              'exchange_rate': 0.0067,
              'base_amount_minor': 20,
              'expense_date': '2026-11-10',
              'notes': 'Dinner with family',
              'version': 1,
            },
          ],
        };
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return postResponse ??
        {
          'data': {
            'id': 'exp-2',
            'trip_id': 't-1',
            'payer_id': 'u-1',
            'category': data['category'] ?? 'dining',
            'title': data['title'] ?? 'Sushi',
            'amount_minor': data['amount_minor'] ?? 2500,
            'currency': data['currency'] ?? 'USD',
            'exchange_rate': 1.0,
            'base_amount_minor': data['amount_minor'] ?? 2500,
            'expense_date': data['expense_date'] ?? '2026-11-10',
            'version': 1,
          },
        };
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPatchPath = path;
    lastPatchData = data;
    return patchResponse ??
        {
          'data': {
            'id': 'exp-1',
            'trip_id': 't-1',
            'payer_id': 'u-1',
            'category': 'dining',
            'title': data['title'] ?? 'Updated Ramen',
            'amount_minor': 3500,
            'currency': 'JPY',
            'exchange_rate': 0.0067,
            'base_amount_minor': 23,
            'expense_date': '2026-11-10',
            'version': 2,
          },
        };
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastDeletePath = path;
    return {'data': null};
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('TripBudget Model', () {
    test('deserializes JSON budget and minor conversions correctly', () {
      final json = {
        'id': 'b-1',
        'trip_id': 't-1',
        'currency': 'USD',
        'total_budget_minor': 150000,
        'daily_budget_minor': 25000,
      };

      final budget = TripBudget.fromJson(json);

      expect(budget.id, 'b-1');
      expect(budget.currency, 'USD');
      expect(budget.totalBudgetMinor, 150000);
      expect(budget.totalBudget, 1500.0);
      expect(budget.dailyBudget, 250.0);
    });
  });

  group('ExpenseSummary Model', () {
    test('deserializes JSON summary with category breakdowns and calculations', () {
      final json = {
        'trip_id': 't-1',
        'base_currency': 'USD',
        'total_budget_minor': 100000,
        'daily_budget_minor': 20000,
        'total_spent_base_minor': 25000,
        'remaining_budget_minor': 75000,
        'budget_utilization_percent': 25.0,
        'expenses_count': 5,
        'category_breakdown': [
          {
            'category': 'dining',
            'amount_minor': 15000,
            'count': 3,
            'percent': 60.0,
          },
        ],
        'daily_spending': [
          {'date': '2026-11-10', 'amount_minor': 25000, 'count': 5},
        ],
      };

      final summary = ExpenseSummary.fromJson(json);

      expect(summary.tripId, 't-1');
      expect(summary.totalSpentBase, 250.0);
      expect(summary.totalBudget, 1000.0);
      expect(summary.remainingBudget, 750.0);
      expect(summary.categoryBreakdown.first.category, 'dining');
      expect(summary.categoryBreakdown.first.amount, 150.0);
      expect(summary.dailySpending.first.date, '2026-11-10');
    });
  });

  group('Expense Model', () {
    test('deserializes JSON and formats currency amounts accurately', () {
      final json = {
        'id': 'exp-1',
        'trip_id': 't-1',
        'payer_id': 'u-1',
        'category': 'dining',
        'title': 'Ramen Dinner',
        'amount_minor': 2850,
        'currency': 'USD',
        'exchange_rate': 1.0,
        'base_amount_minor': 2850,
        'expense_date': '2026-11-10',
      };

      final expense = Expense.fromJson(json);

      expect(expense.title, 'Ramen Dinner');
      expect(expense.amount, 28.50);
      expect(expense.formatAmount(), '\$28.50');

      // Test JPY zero decimal formatting
      const jpyExpense = Expense(
        id: 'exp-2',
        tripId: 't-1',
        payerId: 'u-1',
        category: 'transport',
        title: 'Train ticket',
        amountMinor: 3500,
        currency: 'JPY',
        baseAmountMinor: 23,
        expenseDate: '2026-11-10',
      );

      expect(jpyExpense.formatAmount(), '¥3500');
    });
  });

  group('ExpenseRepository', () {
    test(
      'getExpenses, createExpense, and deleteExpense make correct API calls',
      () async {
        final fakeApi = FakeExpenseApiClient();
        final repo = ExpenseRepository(apiClient: fakeApi);

        final expenses = await repo.getExpenses('t-1');
        expect(fakeApi.lastGetPath, '/v1/trips/t-1/expenses');
        expect(expenses.length, 1);
        expect(expenses.first.title, 'Ramen in Shibuya');

        final created = await repo.createExpense(
          't-1',
          category: 'dining',
          title: 'Sushi Lunch',
          amountMinor: 4000,
          currency: 'USD',
          expenseDate: '2026-11-10',
        );
        expect(fakeApi.lastPostPath, '/v1/trips/t-1/expenses');
        expect(fakeApi.lastPostData['title'], 'Sushi Lunch');
        expect(created.id, 'exp-2');

        await repo.deleteExpense('exp-1');
        expect(fakeApi.lastDeletePath, '/v1/expenses/exp-1');
      },
    );
  });

  group('TripExpensesPage Widget', () {
    testWidgets('renders budget overview, category chips, and expense list', (
      tester,
    ) async {
      final fakeApi = FakeExpenseApiClient();
      final repo = ExpenseRepository(apiClient: fakeApi);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: TripExpensesPage(tripId: 't-1')),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Check header title
      expect(find.text('Expenses & Budget'), findsOneWidget);

      // Check budget summary card
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('\$25.00'), findsOneWidget);
      expect(find.textContaining('Remaining: \$975.00'), findsOneWidget);

      // Check category filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Dining'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);

      // Check expense item
      expect(find.text('Ramen in Shibuya'), findsOneWidget);
      expect(find.text('¥3000'), findsOneWidget);

      // Check FAB
      expect(find.text('Log Expense'), findsOneWidget);
    });
  });

  group('AddExpenseBottomSheet Widget', () {
    testWidgets('submits new expense form correctly', (tester) async {
      final fakeApi = FakeExpenseApiClient();
      final repo = ExpenseRepository(apiClient: fakeApi);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: Scaffold(body: AddExpenseBottomSheet(tripId: 't-1')),
          ),
        ),
      );

      // Fill in title
      await tester.enterText(
        find.widgetWithText(TextField, 'What did you pay for?'),
        'Matcha Latte',
      );

      // Fill in amount
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '6.50');

      // Tap Log Expense button
      await tester.tap(find.widgetWithText(FilledButton, 'Log Expense'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeApi.lastPostPath, '/v1/trips/t-1/expenses');
      expect(fakeApi.lastPostData['title'], 'Matcha Latte');
      expect(fakeApi.lastPostData['amount_minor'], 650);
    });
  });
}
