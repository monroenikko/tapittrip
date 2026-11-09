import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/countries.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/country_residence_dialog.dart';
import '../../../trips/presentation/providers/trip_list_provider.dart';
import '../../data/currency_repository.dart';
import '../../domain/models/expense.dart';
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

    final trips = ref.watch(tripListProvider).asData?.value;
    final trip = trips?.where((t) => t.id == tripId).firstOrNull;
    final destinationCurrency =
        trip?.destinationCurrency ??
        CountryCurrencyHelper.resolveCurrency(
          trip?.destinationCountry ?? trip?.title,
          defaultCurrency: 'USD',
        );

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
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expenses & Budget'),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              tooltip: 'Trip Budget',
              onPressed: () {
                final budget = budgetAsync.asData?.value;
                SetBudgetDialog.show(
                  context,
                  tripId: tripId,
                  initialCurrency: budget?.currency ?? homeCurrency,
                  initialTotalBudgetMinor: budget?.totalBudgetMinor,
                  initialDailyBudgetMinor: budget?.dailyBudgetMinor,
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
                  // Country Residence Prompt Banner if not set
                  if (homeCountry == null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.secondary.withValues(alpha: 0.2),
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
                                  'Set your home country',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                Text(
                                  'Auto-converts $destinationCurrency to your home currency',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () =>
                                CountryResidenceDialog.show(context),
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

                  // Live Market Exchange Rate Pill
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
                                      'Market rate: 1 $destinationCurrency ≈ ${rate.rate.toStringAsFixed(4)} $homeCurrency',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
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
                                  if (hasBudget) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      tooltip: 'Edit Budget',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        final currentBudget = budgetAsync.asData?.value;
                                        SetBudgetDialog.show(
                                          context,
                                          tripId: tripId,
                                          initialCurrency: currentBudget?.currency ?? summary.baseCurrency,
                                          initialTotalBudgetMinor: currentBudget?.totalBudgetMinor,
                                          initialDailyBudgetMinor: currentBudget?.dailyBudgetMinor,
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                summary.formatBaseAmount(summary.totalSpentBaseMinor),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
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
                                          ? Colors.redAccent
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
                                                ? Colors.redAccent
                                                : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                OutlinedButton.icon(
                                  onPressed: () {
                                    SetBudgetDialog.show(
                                      context,
                                      tripId: tripId,
                                      initialCurrency: authUser?.homeCurrency ?? summary.baseCurrency,
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
                        child: Text('Error loading expenses: $err'),
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
                                  'Tap "Log Expense" below to record spending.',
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
                              expense.currency !=
                              (budgetAsync.asData?.value?.currency ?? 'USD');

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
                              subtitle: Text(
                                '${expense.expenseDate}${expense.notes != null ? ' • ${expense.notes}' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
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
                                      if (isForeign) ...[
                                        Text(
                                          '≈ ${expense.formatAmount(useBaseCurrency: true, baseCurrency: summaryAsync.asData?.value.baseCurrency ?? (authUser?.homeCurrency ?? destinationCurrency))}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 18),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        AddExpenseBottomSheet.show(
                                          context,
                                          tripId: tripId,
                                          initialExpense: expense,
                                          defaultCurrency: destinationCurrency,
                                          homeCurrency: homeCurrency,
                                        );
                                      } else if (val == 'delete') {
                                        ref
                                            .read(
                                              tripExpensesProvider(tripId)
                                                  .notifier,
                                            )
                                            .deleteExpense(expense.id);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.redAccent,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.redAccent,
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
                    child: Text('Error loading balances: $err'),
                  ),
                ),
                data: (groupBalances) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Section 1: Member Balances
                      Text(
                        'Trip Companion Balances',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Net spending balance in ${groupBalances.baseCurrency}. Positive balances will receive funds; negative balances owe companions.',
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
                          badgeColor = Colors.green.withValues(alpha: 0.15);
                          textColor = Colors.green.shade800;
                          badgeText =
                              'gets back ${member.formatBalance(groupBalances.baseCurrency)}';
                        } else if (member.owes) {
                          badgeColor = Colors.red.withValues(alpha: 0.15);
                          textColor = Colors.red.shade800;
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
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                member.name.isNotEmpty
                                    ? member.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: member.email.isNotEmpty
                                ? Text(
                                    member.email,
                                    style: theme.textTheme.bodySmall,
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

                      // Section 2: Suggested Settlement Transfers
                      Text(
                        'Suggested Settlements (Simplified)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Calculated with minimal cash flow transfers so companions settle debts with the fewest payments.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (groupBalances.isAllSettled) ...[
                        Card(
                          elevation: 0,
                          color: Colors.green.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.green,
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'All Settled Up!',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'No outstanding debts among companions.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
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
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        colorScheme.secondaryContainer,
                                    child: Icon(
                                      Icons.payments_outlined,
                                      color: colorScheme.onSecondaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${s.payerName} → ${s.payeeName}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Owes ${s.formatAmount()}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
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

                      const SizedBox(height: 24),

                      // Section 3: Past Settlements History
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
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                              ),
                              title: Text(
                                '${record.payerName} paid ${record.payeeName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: record.notes != null
                                  ? Text(record.notes!)
                                  : null,
                              trailing: Text(
                                record.formatAmount(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add_rounded),
          label: const Text('Log Expense'),
          onPressed: () {
            AddExpenseBottomSheet.show(
              context,
              tripId: tripId,
              defaultCurrency: destinationCurrency,
              homeCurrency: homeCurrency,
            );
          },
        ),
      ),
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
