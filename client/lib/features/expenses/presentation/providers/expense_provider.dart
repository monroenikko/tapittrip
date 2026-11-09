import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/expense_repository.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/expense_summary.dart';
import '../../domain/models/group_balances.dart';
import '../../domain/models/trip_budget.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExpenseRepository(apiClient: apiClient);
});

class ExpenseCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? cat) => state = cat;
}

final selectedExpenseCategoryFilterProvider =
    NotifierProvider<ExpenseCategoryFilterNotifier, String?>(
      ExpenseCategoryFilterNotifier.new,
    );

class TripBudgetNotifier extends AsyncNotifier<TripBudget?> {
  TripBudgetNotifier(this.tripId);
  final String tripId;

  @override
  Future<TripBudget?> build() async {
    final repo = ref.watch(expenseRepositoryProvider);
    return repo.getBudget(tripId);
  }

  Future<void> setBudget({
    required String currency,
    required int totalBudgetMinor,
    int? dailyBudgetMinor,
  }) async {
    final repo = ref.read(expenseRepositoryProvider);
    final updated = await repo.setBudget(
      tripId,
      currency: currency,
      totalBudgetMinor: totalBudgetMinor,
      dailyBudgetMinor: dailyBudgetMinor,
    );
    state = AsyncData(updated);
    ref.invalidate(expenseSummaryProvider(tripId));
  }
}

final tripBudgetProvider =
    AsyncNotifierProvider.family<TripBudgetNotifier, TripBudget?, String>(
      (tripId) => TripBudgetNotifier(tripId),
    );

class TripExpensesNotifier extends AsyncNotifier<List<Expense>> {
  TripExpensesNotifier(this.tripId);
  final String tripId;

  @override
  Future<List<Expense>> build() async {
    final repo = ref.watch(expenseRepositoryProvider);
    final filterCategory = ref.watch(selectedExpenseCategoryFilterProvider);
    return repo.getExpenses(tripId, category: filterCategory);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(expenseRepositoryProvider);
      final filterCategory = ref.read(selectedExpenseCategoryFilterProvider);
      return repo.getExpenses(tripId, category: filterCategory);
    });
  }

  Future<void> addExpense({
    required String category,
    required String title,
    required int amountMinor,
    required String currency,
    double? exchangeRate,
    required String expenseDate,
    String? notes,
    String? itineraryItemId,
    String? stayId,
    String splitType = 'single',
    String? receiptUrl,
  }) async {
    final repo = ref.read(expenseRepositoryProvider);
    final created = await repo.createExpense(
      tripId,
      category: category,
      title: title,
      amountMinor: amountMinor,
      currency: currency,
      exchangeRate: exchangeRate,
      expenseDate: expenseDate,
      notes: notes,
      itineraryItemId: itineraryItemId,
      stayId: stayId,
      splitType: splitType,
      receiptUrl: receiptUrl,
    );

    final current = state.asData?.value ?? [];
    state = AsyncData([created, ...current]);
    ref.invalidate(expenseSummaryProvider(tripId));
    ref.invalidate(groupBalancesProvider(tripId));
  }

  Future<void> updateExpense(
    String expenseId, {
    String? category,
    String? title,
    int? amountMinor,
    String? currency,
    double? exchangeRate,
    String? expenseDate,
    String? notes,
  }) async {
    final repo = ref.read(expenseRepositoryProvider);
    final updated = await repo.updateExpense(
      expenseId,
      category: category,
      title: title,
      amountMinor: amountMinor,
      currency: currency,
      exchangeRate: exchangeRate,
      expenseDate: expenseDate,
      notes: notes,
    );

    final current = state.asData?.value ?? [];
    state = AsyncData(
      current.map((e) => e.id == expenseId ? updated : e).toList(),
    );
    ref.invalidate(expenseSummaryProvider(tripId));
    ref.invalidate(groupBalancesProvider(tripId));
  }

  Future<void> deleteExpense(String expenseId) async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.deleteExpense(expenseId);

    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((e) => e.id != expenseId).toList());
    ref.invalidate(expenseSummaryProvider(tripId));
    ref.invalidate(groupBalancesProvider(tripId));
  }
}

final tripExpensesProvider =
    AsyncNotifierProvider.family<TripExpensesNotifier, List<Expense>, String>(
      (tripId) => TripExpensesNotifier(tripId),
    );

final expenseSummaryProvider = FutureProvider.family<ExpenseSummary, String>((
  ref,
  tripId,
) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getSummary(tripId);
});

final groupBalancesProvider = FutureProvider.family<GroupBalances, String>((
  ref,
  tripId,
) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getGroupBalances(tripId);
});
