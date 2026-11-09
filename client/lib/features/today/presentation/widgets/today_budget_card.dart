import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/countries.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/widgets/add_expense_bottom_sheet.dart';
import '../../../expenses/presentation/widgets/set_budget_dialog.dart';
import '../../domain/models/today_dashboard_summary.dart';
import '../providers/today_provider.dart';

class TodayBudgetCard extends ConsumerWidget {
  const TodayBudgetCard({super.key, required this.summary});

  final TodayDashboardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pacing = summary.budgetPacing;

    final authState = ref.watch(authProvider);
    final authUser = authState is Authenticated ? authState.user : null;
    final homeCurrency = authUser?.homeCurrency ?? 'PHP';

    final destCurrency =
        summary.trip.destinationCurrency ??
        CountryCurrencyHelper.resolveCurrency(
          summary.trip.destinationCountry ?? summary.trip.title,
          defaultCurrency: 'USD',
        );

    final displayCurrency = pacing?.currency ?? homeCurrency;

    // 1. Unconfigured / No Budget Set State
    if (pacing == null ||
        (pacing.totalBudgetMinor == 0 && pacing.totalSpentMinor == 0)) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Trip Budget & Expenses',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayCurrency,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'No budget set yet',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set a spending target to stay on budget, track daily costs, and manage group expenses effortlessly.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await SetBudgetDialog.show(
                      context,
                      tripId: summary.trip.id,
                      initialCurrency: displayCurrency,
                    );
                    ref.invalidate(todaySummaryProvider(summary.trip.id));
                  },
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Set Budget'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await AddExpenseBottomSheet.show(
                      context,
                      tripId: summary.trip.id,
                      defaultCurrency: destCurrency,
                      homeCurrency: homeCurrency,
                    );
                    ref.invalidate(todaySummaryProvider(summary.trip.id));
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Log Expense'),
                ),
                TextButton.icon(
                  onPressed: () =>
                      context.push('/trips/${summary.trip.id}/expenses'),
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: const Text('All Expenses'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. Budget or Spending Configured State
    final formattedSpent = CurrencyFormatter.formatAmount(
      pacing.spentTodayMinor,
      pacing.currency,
      isMinor: true,
    );
    final hasDailyBudget =
        pacing.dailyBudgetMinor != null && pacing.dailyBudgetMinor! > 0;
    final formattedTarget = hasDailyBudget
        ? CurrencyFormatter.formatAmount(
            pacing.dailyBudgetMinor!,
            pacing.currency,
            isMinor: true,
          )
        : '';

    final dailyUtil = hasDailyBudget
        ? (pacing.spentTodayMinor / pacing.dailyBudgetMinor!)
        : 0.0;
    final isDailyOver = hasDailyBudget && dailyUtil > 1.0;
    final hasTotalBudget = pacing.totalBudgetMinor > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Today\'s Spending & Budget',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pacing.currency,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Edit Budget',
                icon: Icon(
                  Icons.edit_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () async {
                  await SetBudgetDialog.show(
                    context,
                    tripId: summary.trip.id,
                    initialCurrency: pacing.currency,
                    initialTotalBudgetMinor: pacing.totalBudgetMinor > 0
                        ? pacing.totalBudgetMinor
                        : null,
                    initialDailyBudgetMinor: pacing.dailyBudgetMinor,
                  );
                  ref.invalidate(todaySummaryProvider(summary.trip.id));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Today's Spent vs Daily Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formattedSpent,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (hasDailyBudget) ...[
                Text(
                  'Target: $formattedTarget',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else if (hasTotalBudget) ...[
                Text(
                  'Budget: ${CurrencyFormatter.formatAmount(pacing.totalBudgetMinor, pacing.currency, isMinor: true)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Daily progress bar
          if (hasDailyBudget) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: dailyUtil.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDailyOver ? Colors.redAccent : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(dailyUtil * 100).toStringAsFixed(0)}% daily limit used',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDailyOver
                        ? Colors.redAccent
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isDailyOver
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                Text(
                  isDailyOver
                      ? 'Over by ${CurrencyFormatter.formatAmount((pacing.spentTodayMinor - pacing.dailyBudgetMinor!).abs(), pacing.currency, isMinor: true)}'
                      : 'Remaining: ${CurrencyFormatter.formatAmount(pacing.dailyBudgetMinor! - pacing.spentTodayMinor, pacing.currency, isMinor: true)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDailyOver ? Colors.redAccent : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ] else if (hasTotalBudget) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Spent: ${CurrencyFormatter.formatAmount(pacing.totalSpentMinor, pacing.currency, isMinor: true)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Remaining: ${CurrencyFormatter.formatAmount(pacing.remainingBudgetMinor, pacing.currency, isMinor: true)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: pacing.remainingBudgetMinor < 0
                        ? Colors.redAccent
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Trip Total Spent: ${CurrencyFormatter.formatAmount(pacing.totalSpentMinor, pacing.currency, isMinor: true)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Quick actions row
          Row(
            children: [
              TextButton.icon(
                onPressed: () =>
                    context.push('/trips/${summary.trip.id}/expenses'),
                icon: const Icon(Icons.bar_chart_rounded, size: 18),
                label: const Text('All Expenses'),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await AddExpenseBottomSheet.show(
                    context,
                    tripId: summary.trip.id,
                    defaultCurrency: destCurrency,
                    homeCurrency: displayCurrency,
                  );
                  ref.invalidate(todaySummaryProvider(summary.trip.id));
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Log Expense'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
