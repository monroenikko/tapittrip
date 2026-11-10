import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../sync/domain/models/outbox_operation.dart';
import '../../../sync/presentation/providers/sync_provider.dart';
import '../../../sync/services/sync_service.dart';
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
    ref.invalidate(groupBalancesProvider(tripId));
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

  Future<void> _recordOutboxOperation(OutboxOperation operation) async {
    final outbox = ref.read(outboxStorageProvider);
    await outbox.saveOperation(operation);
    await ref.read(syncProvider.notifier).refresh();
  }

  Expense? _findExpense(String expenseId) {
    final list = state.asData?.value ?? const <Expense>[];
    for (final item in list) {
      if (item.id == expenseId) return item;
    }
    return null;
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
    String? payerId,
    required String category,
    required String title,
    required int amountMinor,
    required String currency,
    double? exchangeRate,
    String? rateSource,
    String? rateCapturedAt,
    String? conversionStatus,
    required String expenseDate,
    String? notes,
    String? itineraryItemId,
    String? stayId,
    String splitType = 'single',
    String? visibility,
    List<String>? participantIds,
    List<Map<String, dynamic>>? splits,
    String? receiptUrl,
  }) async {
    final repo = ref.read(expenseRepositoryProvider);
    final opId = SyncService.generateUuid();
    final current = state.asData?.value ?? const <Expense>[];

    try {
      final created = await repo.createExpense(
        tripId,
        payerId: payerId,
        category: category,
        title: title,
        amountMinor: amountMinor,
        currency: currency,
        exchangeRate: exchangeRate,
        rateSource: rateSource,
        rateCapturedAt: rateCapturedAt,
        conversionStatus: conversionStatus,
        expenseDate: expenseDate,
        notes: notes,
        itineraryItemId: itineraryItemId,
        stayId: stayId,
        splitType: splitType,
        visibility: visibility,
        participantIds: participantIds,
        splits: splits,
        receiptUrl: receiptUrl,
        clientOperationId: opId,
      );

      final next = [created, ...current];
      state = AsyncData(next);
      await repo.cacheExpenses(tripId, next);
      ref.invalidate(expenseSummaryProvider(tripId));
      ref.invalidate(groupBalancesProvider(tripId));
    } on NetworkException {
      final offlineId = SyncService.generateUuid();
      final resolvedVisibility =
          visibility ?? (splitType == 'single' ? 'private' : 'shared');
      final offlineExpense = Expense(
        id: offlineId,
        tripId: tripId,
        payerId: payerId ?? '',
        category: category,
        title: title,
        amountMinor: amountMinor,
        currency: currency,
        exchangeRate: exchangeRate,
        rateSource: rateSource ?? 'unavailable',
        rateCapturedAt: rateCapturedAt,
        conversionStatus: conversionStatus ?? 'unavailable',
        baseAmountMinor:
            (conversionStatus == 'converted' && exchangeRate != null)
            ? (amountMinor * exchangeRate).round()
            : null,
        expenseDate: expenseDate,
        itineraryItemId: itineraryItemId,
        stayId: stayId,
        splitType: splitType,
        visibility: resolvedVisibility,
        splits: (splits ?? const [])
            .map((e) => ExpenseSplitItem.fromJson(e))
            .toList(),
        notes: notes,
        receiptUrl: receiptUrl,
        version: 1,
        clientOperationId: opId,
      );

      final next = [offlineExpense, ...current];
      state = AsyncData(next);
      await repo.cacheExpenses(tripId, next);

      await _recordOutboxOperation(
        OutboxOperation(
          operationId: opId,
          tripId: tripId,
          entityType: 'expense',
          entityId: offlineId,
          operationType: 'create',
          baseVersion: 1,
          payload: {
            'payer_id': ?payerId,
            'category': category,
            'title': title,
            'amount_minor': amountMinor,
            'currency': currency,
            'exchange_rate': ?exchangeRate,
            'rate_source': ?rateSource,
            'rate_captured_at': ?rateCapturedAt,
            'conversion_status': ?conversionStatus,
            'expense_date': expenseDate,
            'notes': ?notes,
            'itinerary_item_id': ?itineraryItemId,
            'stay_id': ?stayId,
            'split_type': splitType,
            'visibility': resolvedVisibility,
            'participant_ids': ?participantIds,
            'splits': ?splits,
            'receipt_url': ?receiptUrl,
          },
          status: 'pending',
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  Future<void> updateExpense(
    String expenseId, {
    String? payerId,
    String? category,
    String? title,
    int? amountMinor,
    String? currency,
    double? exchangeRate,
    String? rateSource,
    String? rateCapturedAt,
    String? conversionStatus,
    String? expenseDate,
    String? notes,
    String? splitType,
    String? visibility,
    List<String>? participantIds,
    List<Map<String, dynamic>>? splits,
  }) async {
    final repo = ref.read(expenseRepositoryProvider);
    final existing = _findExpense(expenseId);
    final baseVersion = existing?.version ?? 1;
    final current = state.asData?.value ?? const <Expense>[];

    try {
      final updated = await repo.updateExpense(
        expenseId,
        payerId: payerId,
        category: category,
        title: title,
        amountMinor: amountMinor,
        currency: currency,
        exchangeRate: exchangeRate,
        rateSource: rateSource,
        rateCapturedAt: rateCapturedAt,
        conversionStatus: conversionStatus,
        expenseDate: expenseDate,
        notes: notes,
        splitType: splitType,
        visibility: visibility,
        participantIds: participantIds,
        splits: splits,
        baseVersion: existing != null ? baseVersion : null,
      );

      final next = current.map((e) => e.id == expenseId ? updated : e).toList();
      state = AsyncData(next);
      await repo.cacheExpenses(tripId, next);
      ref.invalidate(expenseSummaryProvider(tripId));
      ref.invalidate(groupBalancesProvider(tripId));
    } on ConflictException catch (e) {
      await _recordOutboxOperation(
        OutboxOperation(
          operationId: SyncService.generateUuid(),
          tripId: tripId,
          entityType: 'expense',
          entityId: expenseId,
          operationType: 'update',
          baseVersion: baseVersion,
          payload: {
            'title': ?title,
            'amount_minor': ?amountMinor,
            'currency': ?currency,
            'split_type': ?splitType,
            'visibility': ?visibility,
            'notes': ?notes,
          },
          status: 'conflict',
          conflictDetails: e.details,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      await refresh();
      rethrow;
    } on NetworkException {
      if (existing != null) {
        final optimistic = Expense(
          id: existing.id,
          tripId: existing.tripId,
          payerId: payerId ?? existing.payerId,
          createdByUserId: existing.createdByUserId,
          category: category ?? existing.category,
          title: title ?? existing.title,
          amountMinor: amountMinor ?? existing.amountMinor,
          currency: currency ?? existing.currency,
          exchangeRate: exchangeRate ?? existing.exchangeRate,
          rateSource: rateSource ?? existing.rateSource,
          rateCapturedAt: rateCapturedAt ?? existing.rateCapturedAt,
          conversionStatus: conversionStatus ?? existing.conversionStatus,
          baseAmountMinor: existing.baseAmountMinor,
          expenseDate: expenseDate ?? existing.expenseDate,
          itineraryItemId: existing.itineraryItemId,
          stayId: existing.stayId,
          splitType: splitType ?? existing.splitType,
          visibility: visibility ?? existing.visibility,
          splits: splits != null
              ? splits.map((s) => ExpenseSplitItem.fromJson(s)).toList()
              : existing.splits,
          notes: notes ?? existing.notes,
          receiptUrl: existing.receiptUrl,
          version: existing.version,
          clientOperationId: existing.clientOperationId,
          payerName: existing.payerName,
        );
        final next = current
            .map((e) => e.id == expenseId ? optimistic : e)
            .toList();
        state = AsyncData(next);
        await repo.cacheExpenses(tripId, next);
      }

      await _recordOutboxOperation(
        OutboxOperation(
          operationId: SyncService.generateUuid(),
          tripId: tripId,
          entityType: 'expense',
          entityId: expenseId,
          operationType: 'update',
          baseVersion: baseVersion,
          payload: {
            'payer_id': ?payerId,
            'category': ?category,
            'title': ?title,
            'amount_minor': ?amountMinor,
            'currency': ?currency,
            'exchange_rate': ?exchangeRate,
            'rate_source': ?rateSource,
            'rate_captured_at': ?rateCapturedAt,
            'conversion_status': ?conversionStatus,
            'expense_date': ?expenseDate,
            'notes': ?notes,
            'split_type': ?splitType,
            'visibility': ?visibility,
            'participant_ids': ?participantIds,
            'splits': ?splits,
          },
          status: 'pending',
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final repo = ref.read(expenseRepositoryProvider);
    final existing = _findExpense(expenseId);
    final baseVersion = existing?.version ?? 1;
    final current = state.asData?.value ?? const <Expense>[];

    try {
      await repo.deleteExpense(
        expenseId,
        baseVersion: existing != null ? baseVersion : null,
      );

      final next = current.where((e) => e.id != expenseId).toList();
      state = AsyncData(next);
      await repo.cacheExpenses(tripId, next);
      ref.invalidate(expenseSummaryProvider(tripId));
      ref.invalidate(groupBalancesProvider(tripId));
    } on ConflictException catch (e) {
      await _recordOutboxOperation(
        OutboxOperation(
          operationId: SyncService.generateUuid(),
          tripId: tripId,
          entityType: 'expense',
          entityId: expenseId,
          operationType: 'delete',
          baseVersion: baseVersion,
          status: 'conflict',
          conflictDetails: e.details,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      await refresh();
      rethrow;
    } on NetworkException {
      final next = current.where((e) => e.id != expenseId).toList();
      state = AsyncData(next);
      await repo.cacheExpenses(tripId, next);

      await _recordOutboxOperation(
        OutboxOperation(
          operationId: SyncService.generateUuid(),
          tripId: tripId,
          entityType: 'expense',
          entityId: expenseId,
          operationType: 'delete',
          baseVersion: baseVersion,
          status: 'pending',
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
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
