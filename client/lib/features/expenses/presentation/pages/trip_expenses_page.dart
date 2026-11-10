import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/countries.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../circles/domain/models/circle_member.dart';
import '../../../circles/presentation/providers/trip_circle_provider.dart';
import '../../../trips/presentation/providers/trip_list_provider.dart';
import '../../data/currency_repository.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/group_balances.dart';
import '../providers/expense_provider.dart';
import '../widgets/add_expense_bottom_sheet.dart';
import '../widgets/set_budget_dialog.dart';
import '../widgets/settle_up_dialog.dart';

class TripExpensesPage extends ConsumerWidget {
  const TripExpensesPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final budgetAsync = ref.watch(tripBudgetProvider(tripId));
    final expensesAsync = ref.watch(tripExpensesProvider(tripId));
    final summaryAsync = ref.watch(expenseSummaryProvider(tripId));
    final balancesAsync = ref.watch(groupBalancesProvider(tripId));
    final selectedFilter = ref.watch(selectedExpenseCategoryFilterProvider);

    final authState = ref.watch(authProvider);
    final authUser = authState is Authenticated ? authState.user : null;
    final homeCurrency = authUser?.homeCurrency ?? 'USD';
    final homeCountry = authUser?.homeCountry;

    final members = authUser != null
        ? ref.watch(circleMembersProvider(tripId)).asData?.value ??
              const <CircleMember>[]
        : const <CircleMember>[];
    CircleMember? selfMember;
    if (authUser != null) {
      for (final m in members) {
        if (m.userId == authUser.id) {
          selfMember = m;
          break;
        }
      }
    }
    final isViewerOnly = selfMember != null && selfMember.isViewer;
    final canManageExpenses = !isViewerOnly;

    final trips = ref.watch(tripListProvider).asData?.value;
    final trip = trips?.where((t) => t.id == tripId).firstOrNull;
    final budget = budgetAsync.asData?.value;
    final expenses = expensesAsync.asData?.value;
    final expenseCurrencies = expenses?.map((e) => e.currency).toList();

    final destinationCurrency = CountryCurrencyHelper.resolveTripCurrency(
      explicitCurrency: trip?.destinationCurrency,
      destinationCountry: trip?.destinationCountry,
      title: trip?.title,
      budgetCurrency: budget?.currency,
      expenseCurrencies: expenseCurrencies,
      defaultCurrency: 'USD',
    );
    final baseLedgerCurrency =
        summaryAsync.asData?.value.baseCurrency ??
        budget?.currency ??
        destinationCurrency;

    final categories = const [
      'all',
      'dining',
      'transport',
      'accommodation',
      'activities',
      'shopping',
      'other',
    ];

    void refreshAll() {
      ref.invalidate(tripBudgetProvider(tripId));
      ref.invalidate(tripExpensesProvider(tripId));
      ref.invalidate(expenseSummaryProvider(tripId));
      ref.invalidate(groupBalancesProvider(tripId));
      if (authUser != null) {
        ref.invalidate(circleMembersProvider(tripId));
      }
    }

    Future<void> handleDeleteExpense(Expense expense) async {
      try {
        await ref
            .read(tripExpensesProvider(tripId).notifier)
            .deleteExpense(expense.id);
      } catch (e) {
        if (!context.mounted) return;
        final msg = e is ApiException ? e.message : 'Unable to delete expense.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: colorScheme.error),
        );
      }
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expenses & Budget'),
          actions: [
            if (canManageExpenses)
              IconButton(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                tooltip: 'Trip Budget',
                onPressed: () {
                  final currentBudget = budgetAsync.asData?.value;
                  SetBudgetDialog.show(
                    context,
                    tripId: tripId,
                    initialCurrency:
                        currentBudget?.currency ?? destinationCurrency,
                    initialTotalBudgetMinor: currentBudget?.totalBudgetMinor,
                    initialDailyBudgetMinor: currentBudget?.dailyBudgetMinor,
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: refreshAll,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Expenses'),
              Tab(
                icon: Icon(Icons.people_alt_outlined),
                text: 'Balances & Settle',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Expenses & Summary
            RefreshIndicator(
              onRefresh: () async => refreshAll(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (isViewerOnly)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'View-only access: you can review shared trip expenses and group balances.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (homeCountry == null || authUser?.permanentAddress == null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🌏', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set your permanent address',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Helps TapItTrip automatically convert destination expenses ($destinationCurrency) to your home currency',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () => context.push('/profile'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: const Text('Set'),
                          ),
                        ],
                      ),
                    ),

                  // Market Exchange Rate Snapshot Pill
                  if (destinationCurrency.toUpperCase() !=
                      homeCurrency.toUpperCase())
                    Consumer(
                      builder: (context, ref, _) {
                        final rateAsync = ref.watch(
                          currencyRateProvider((
                            from: destinationCurrency,
                            to: homeCurrency,
                          )),
                        );
                        return rateAsync.when(
                          data: (rate) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.trending_up_rounded,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Market rate (${rate.provider}): 1 $destinationCurrency ≈ ${rate.rate.toStringAsFixed(4)} $homeCurrency',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cloud_off_rounded,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Exchange rate unavailable offline ($destinationCurrency → $homeCurrency).',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Top Budget & Spending Overview Card
                  summaryAsync.when(
                    loading: () => const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (err, stack) => const SizedBox.shrink(),
                    data: (summary) {
                      final hasBudget =
                          summary.totalBudgetMinor != null &&
                          summary.totalBudgetMinor! > 0;
                      final util =
                          (summary.budgetUtilizationPercent ?? 0.0) / 100.0;
                      final isOver = util > 1.0;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Total Spent',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      summary.baseCurrency,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color:
                                                colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  if (hasBudget && canManageExpenses) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                      ),
                                      tooltip: 'Edit Budget',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        final currentBudget =
                                            budgetAsync.asData?.value;
                                        SetBudgetDialog.show(
                                          context,
                                          tripId: tripId,
                                          initialCurrency:
                                              currentBudget?.currency ??
                                              summary.baseCurrency,
                                          initialTotalBudgetMinor:
                                              currentBudget?.totalBudgetMinor,
                                          initialDailyBudgetMinor:
                                              currentBudget?.dailyBudgetMinor,
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                summary.formatBaseAmount(
                                  summary.totalSpentBaseMinor,
                                ),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (summary.personalSpentBaseMinor > 0 &&
                                  summary.sharedSpentBaseMinor > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Shared: ${summary.formatBaseAmount(summary.sharedSpentBaseMinor)} • Personal: ${summary.formatBaseAmount(summary.personalSpentBaseMinor)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              if (summary.unconvertedExpensesCount > 0) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer
                                        .withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${summary.unconvertedExpensesCount} expense(s) missing an FX rate snapshot (${summary.unconvertedTotals.map((t) => t.formatAmount()).join(', ')}).',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),

                              if (hasBudget) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: util.clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isOver
                                          ? colorScheme.error
                                          : colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Budget: ${summary.formatBaseAmount(summary.totalBudgetMinor)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    Text(
                                      isOver
                                          ? 'Over budget by ${summary.formatBaseAmount(-summary.remainingBudgetMinor!)}'
                                          : 'Remaining: ${summary.formatBaseAmount(summary.remainingBudgetMinor)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: isOver
                                                ? colorScheme.error
                                                : colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ] else if (canManageExpenses) ...[
                                OutlinedButton.icon(
                                  onPressed: () {
                                    SetBudgetDialog.show(
                                      context,
                                      tripId: tripId,
                                      initialCurrency: destinationCurrency,
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Set Trip Budget Target'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Filter Chips
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isAll = cat == 'all';
                        final isSelected = isAll
                            ? selectedFilter == null
                            : selectedFilter == cat;

                        return FilterChip(
                          label: Text(
                            isAll ? 'All' : _formatCategoryLabel(cat),
                          ),
                          selected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(
                                  selectedExpenseCategoryFilterProvider
                                      .notifier,
                                )
                                .setFilter(isAll ? null : cat);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Expense List
                  expensesAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error loading expenses: $err'),
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed: refreshAll,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (expenses) {
                      if (expenses.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: colorScheme.outline,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No expenses logged yet',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  canManageExpenses
                                      ? 'Tap "Log Expense" below to record spending.'
                                      : 'Shared trip expenses will appear here once logged.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: expenses.map((expense) {
                          final isForeign =
                              expense.currency.toUpperCase() !=
                              baseLedgerCurrency.toUpperCase();
                          final splitLabel = switch (expense.splitType) {
                            'equal' => 'Split equally',
                            'selected' =>
                              expense.splits.isNotEmpty
                                  ? 'Split (${expense.splits.length})'
                                  : 'Selected split',
                            'custom' => 'Custom split',
                            _ => expense.isPrivate ? 'Personal' : 'Shared',
                          };

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Expense.getCategoryColor(
                                    expense.category,
                                    colorScheme,
                                  ).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Expense.getCategoryIcon(expense.category),
                                  color: Expense.getCategoryColor(
                                    expense.category,
                                    colorScheme,
                                  ),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                expense.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${expense.expenseDate}${expense.payerName != null ? ' • Paid by ${expense.payerName}' : ''}${expense.notes != null ? ' • ${expense.notes}' : ''}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: expense.isPrivate
                                              ? colorScheme
                                                    .surfaceContainerHighest
                                              : colorScheme.secondaryContainer
                                                    .withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          expense.isPrivate
                                              ? 'Private • $splitLabel'
                                              : splitLabel,
                                          style: theme.textTheme.labelSmall,
                                        ),
                                      ),
                                      if (expense.isConversionUnavailable)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.errorContainer
                                                .withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'FX rate unavailable',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onErrorContainer,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        expense.formatAmount(),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (isForeign)
                                        Text(
                                          expense.isConversionUnavailable
                                              ? 'Unconverted'
                                              : '≈ ${expense.formatAmount(useBaseCurrency: true, baseCurrency: baseLedgerCurrency)}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color:
                                                    expense
                                                        .isConversionUnavailable
                                                    ? colorScheme.error
                                                    : colorScheme
                                                          .onSurfaceVariant,
                                              ),
                                        ),
                                    ],
                                  ),
                                  if (canManageExpenses)
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        size: 18,
                                      ),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          AddExpenseBottomSheet.show(
                                            context,
                                            tripId: tripId,
                                            initialExpense: expense,
                                            defaultCurrency:
                                                destinationCurrency,
                                            homeCurrency: baseLedgerCurrency,
                                          );
                                        } else if (val == 'delete') {
                                          handleDeleteExpense(expense);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: colorScheme.error,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: colorScheme.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Tab 2: Group Balances & Settle Up
            RefreshIndicator(
              onRefresh: () async => refreshAll(),
              child: balancesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error loading balances: $err'),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: refreshAll,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (groupBalances) {
                  return _buildBalancesTab(
                    context,
                    theme,
                    colorScheme,
                    groupBalances,
                    canManageExpenses,
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: canManageExpenses
            ? FloatingActionButton.extended(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Log Expense'),
                onPressed: () {
                  AddExpenseBottomSheet.show(
                    context,
                    tripId: tripId,
                    defaultCurrency: destinationCurrency,
                    homeCurrency: baseLedgerCurrency,
                  );
                },
              )
            : null,
      ),
    );
  }

  Widget _buildBalancesTab(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    GroupBalances groupBalances,
    bool canRecordSettlements,
  ) {
    final hasMultiCurrency =
        groupBalances.perCurrencyBalances.length > 1 ||
        groupBalances.perCurrencyBalances.keys.any(
          (c) => c != groupBalances.baseCurrency,
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Trip Companion Balances',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Net balance in ${groupBalances.baseCurrency}. Positive balances are owed; negative balances owe companions.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        ...groupBalances.balances.map((member) {
          Color badgeColor;
          Color textColor;
          String badgeText;

          if (member.isOwed) {
            badgeColor = colorScheme.primaryContainer;
            textColor = colorScheme.onPrimaryContainer;
            badgeText =
                'gets back ${member.formatBalance(groupBalances.baseCurrency)}';
          } else if (member.owes) {
            badgeColor = colorScheme.errorContainer;
            textColor = colorScheme.onErrorContainer;
            badgeText =
                'owes ${member.formatBalance(groupBalances.baseCurrency)}';
          } else {
            badgeColor = colorScheme.surfaceContainerHighest;
            textColor = colorScheme.onSurfaceVariant;
            badgeText = 'settled up';
          }

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                member.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: member.isDeparted
                  ? Text(
                      'Former companion (auditable history retained)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        Text(
          'Suggested Settlements (Simplified)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Calculated with minimal ledger transfers so companions can log repayments cleanly.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        if (groupBalances.isAllSettled) ...[
          Card(
            elevation: 0,
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Settled Up!',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No outstanding balances in ${groupBalances.baseCurrency}.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ...groupBalances.suggestedSettlements.map((s) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.payments_outlined,
                        color: colorScheme.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.payerName} → ${s.payeeName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Owes ${s.formatAmount()}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canRecordSettlements)
                      FilledButton.tonal(
                        onPressed: () {
                          SettleUpDialog.show(
                            context,
                            tripId: tripId,
                            payerId: s.payerId,
                            payerName: s.payerName,
                            payeeId: s.payeeId,
                            payeeName: s.payeeName,
                            initialAmountMinor: s.amountMinor,
                            currency: s.currency,
                          );
                        },
                        child: const Text('Settle Up'),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],

        if (groupBalances.unconvertedExpenses.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.secondary.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unconverted Foreign Expenses (${groupBalances.unconvertedExpenses.length})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Excluded from ${groupBalances.baseCurrency} net balances until an attributed rate snapshot is available:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                ...groupBalances.unconvertedExpenses.map(
                  (u) => Text(
                    '• ${u.title}: ${u.formatAmount()} (${u.payerName})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (hasMultiCurrency) ...[
          const SizedBox(height: 16),
          Text(
            'By Currency Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...groupBalances.perCurrencyBalances.entries.map(
            (entry) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...entry.value.map(
                      (b) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(b.name, style: theme.textTheme.bodySmall),
                            Text(
                              b.formatBalance(entry.key),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  groupBalances.accountingNotice,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (groupBalances.settlementHistory.isNotEmpty) ...[
          Text(
            'Settlement History',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...groupBalances.settlementHistory.map((record) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                ),
                title: Text(
                  '${record.payerName} paid ${record.payeeName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: record.notes != null ? Text(record.notes!) : null,
                trailing: Text(
                  record.formatAmount(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  String _formatCategoryLabel(String cat) {
    switch (cat.toLowerCase()) {
      case 'dining':
        return 'Dining';
      case 'transport':
        return 'Transport';
      case 'accommodation':
        return 'Stay';
      case 'activities':
        return 'Activities';
      case 'shopping':
        return 'Shopping';
      case 'other':
      default:
        return 'Other';
    }
  }
}
