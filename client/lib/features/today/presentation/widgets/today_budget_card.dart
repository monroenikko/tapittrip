import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/countries.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/today_dashboard_summary.dart';
import '../../../expenses/presentation/widgets/add_expense_bottom_sheet.dart';

class TodayBudgetCard extends StatelessWidget {
  const TodayBudgetCard({super.key, required this.summary});

  final TodayDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final pacing = summary.budgetPacing;
    if (pacing == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final formattedSpent = CurrencyFormatter.formatAmount(
      pacing.spentTodayMinor,
      pacing.currency,
      isMinor: true,
    );
    final formattedTarget = pacing.dailyBudgetMinor != null
        ? CurrencyFormatter.formatAmount(
            pacing.dailyBudgetMinor!,
            pacing.currency,
            isMinor: true,
          )
        : '';

    final hasDailyBudget =
        pacing.dailyBudgetMinor != null && pacing.dailyBudgetMinor! > 0;
    final dailyUtil = hasDailyBudget
        ? (pacing.spentTodayMinor / pacing.dailyBudgetMinor!)
        : 0.0;
    final isDailyOver = hasDailyBudget && dailyUtil > 1.0;

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
                onPressed: () {
                  final destCurrency =
                      summary.trip.destinationCurrency ??
                      CountryCurrencyHelper.resolveCurrency(
                        summary.trip.destinationCountry ?? summary.trip.title,
                        defaultCurrency: pacing.currency,
                      );

                  AddExpenseBottomSheet.show(
                    context,
                    tripId: summary.trip.id,
                    defaultCurrency: destCurrency,
                    homeCurrency: pacing.currency,
                  );
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
