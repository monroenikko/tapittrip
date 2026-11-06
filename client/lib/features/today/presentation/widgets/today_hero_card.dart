import 'package:flutter/material.dart';

import '../../domain/models/today_dashboard_summary.dart';

class TodayHeroCard extends StatelessWidget {
  const TodayHeroCard({super.key, required this.summary});

  final TodayDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trip = summary.trip;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge (Day X of Y / Pre-trip countdown)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: summary.isActive
                            ? colorScheme.primary
                            : (summary.isPreTrip
                                  ? colorScheme.secondaryContainer
                                  : colorScheme.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        summary.statusBadgeText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: summary.isActive
                              ? Colors.white
                              : (summary.isPreTrip
                                    ? colorScheme.onSecondaryContainer
                                    : colorScheme.onSurfaceVariant),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trip.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (trip.dateRangeFormatted != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        trip.dateRangeFormatted!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Brand Icon / Image Container
              Container(
                width: 68,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.primaryContainer.withValues(alpha: 0.8),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/logo_icon.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          if (summary.activeDay?.notes != null &&
              summary.activeDay!.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                summary.activeDay!.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
