import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/add_expense_bottom_sheet.dart';
import '../widgets/set_budget_dialog.dart';

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
    final selectedFilter = ref.watch(selectedExpenseCategoryFilterProvider);

    final categories = const [
      'all',
      'dining',
      'transport',
      'accommodation',
      'activities',
      'shopping',
      'other',
    ];

    return Scaffold(
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
                initialCurrency: budget?.currency ?? 'USD',
                initialTotalBudgetMinor: budget?.totalBudgetMinor,
                initialDailyBudgetMinor: budget?.dailyBudgetMinor,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(tripBudgetProvider(tripId));
              ref.invalidate(tripExpensesProvider(tripId));
              ref.invalidate(expenseSummaryProvider(tripId));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tripBudgetProvider(tripId));
          ref.invalidate(tripExpensesProvider(tripId));
          ref.invalidate(expenseSummaryProvider(tripId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                final util = (summary.budgetUtilizationPercent ?? 0.0) / 100.0;
                final isOver = util > 1.0;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
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
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${(summary.totalSpentBaseMinor / 100.0).toStringAsFixed(2)}',
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
                                isOver ? Colors.redAccent : colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Budget: \$${(summary.totalBudgetMinor! / 100.0).toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                isOver
                                    ? 'Over budget by \$${((-summary.remainingBudgetMinor!) / 100.0).toStringAsFixed(2)}'
                                    : 'Remaining: \$${(summary.remainingBudgetMinor! / 100.0).toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall?.copyWith(
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
                                initialCurrency: summary.baseCurrency,
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
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isAll = cat == 'all';
                  final isSelected = isAll
                      ? selectedFilter == null
                      : selectedFilter == cat;

                  return FilterChip(
                    label: Text(isAll ? 'All' : _formatCategoryLabel(cat)),
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(selectedExpenseCategoryFilterProvider.notifier)
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
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isForeign) ...[
                                  Text(
                                    '≈ ${expense.formatAmount(useBaseCurrency: true)}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
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
                                  );
                                } else if (val == 'delete') {
                                  ref
                                      .read(
                                        tripExpensesProvider(tripId).notifier,
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
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Expense'),
        onPressed: () {
          final defaultCur = budgetAsync.asData?.value?.currency ?? 'USD';
          AddExpenseBottomSheet.show(
            context,
            tripId: tripId,
            defaultCurrency: defaultCur,
          );
        },
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
