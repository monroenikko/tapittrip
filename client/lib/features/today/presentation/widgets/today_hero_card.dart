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
    final isDark = theme.brightness == Brightness.dark;

    // Editorial deep-navy hero surface in light mode, rich elevated navy container in dark mode.
    final heroBackground = isDark
        ? colorScheme.primaryContainer
        : colorScheme.primary;
    final heroForeground = isDark
        ? colorScheme.onPrimaryContainer
        : colorScheme.onPrimary;
    final mutedForeground = heroForeground.withValues(alpha: 0.78);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: heroBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: heroForeground.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top metadata rail: status pill + weather pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: summary.isActive
                        ? colorScheme.secondary
                        : heroForeground.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    summary.statusBadgeText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: summary.isActive
                          ? colorScheme.onSecondary
                          : heroForeground,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Spacer(),
                if (summary.weather != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: heroForeground.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: heroForeground.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          summary.weather!.weatherIcon,
                          size: 14,
                          color: heroForeground,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          summary.weather!.tempString,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: heroForeground,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Editorial Trip Headline
            Text(
              trip.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: heroForeground,
              ),
            ),
            if (trip.dateRangeFormatted != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      trip.dateRangeFormatted!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (summary.activeDay?.notes != null &&
                summary.activeDay!.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: heroForeground.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: heroForeground.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                child: Text(
                  summary.activeDay!.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: heroForeground.withValues(alpha: 0.92),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
