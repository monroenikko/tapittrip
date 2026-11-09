import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/map_launcher.dart';
import '../../../itinerary/presentation/providers/itinerary_provider.dart';
import '../../../itinerary/presentation/widgets/add_activity_bottom_sheet.dart';
import '../../domain/models/today_dashboard_summary.dart';

class QuickActionsGrid extends ConsumerWidget {
  const QuickActionsGrid({
    super.key,
    required this.summary,
    this.onViewItinerary,
    this.onViewStays,
    this.onActivityAdded,
  });

  final TodayDashboardSummary summary;
  final VoidCallback? onViewItinerary;
  final VoidCallback? onViewStays;
  final VoidCallback? onActivityAdded;

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final actions = <Widget>[
      _buildActionButton(
        context: context,
        icon: Icons.calendar_month_rounded,
        label: 'Itinerary',
        color: colorScheme.primary,
        onTap: () => onViewItinerary?.call(),
      ),
      _buildActionButton(
        context: context,
        icon: Icons.hotel_rounded,
        label: 'Stays',
        color: colorScheme.secondary,
        onTap: () => onViewStays?.call(),
      ),
      _buildActionButton(
        context: context,
        icon: Icons.account_balance_wallet_outlined,
        label: 'Expenses',
        color: Colors.teal.shade700,
        onTap: () => context.push('/trips/${summary.trip.id}/expenses'),
      ),
      _buildActionButton(
        context: context,
        icon: Icons.add_location_alt_rounded,
        label: '+ Stop',
        color: colorScheme.tertiary,
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => AddActivityBottomSheet(
              tripId: summary.trip.id,
              onSubmit:
                  ({
                    required title,
                    required kind,
                    tripDayId,
                    inlinePlace,
                    notes,
                  }) async {
                    await ref
                        .read(itineraryListProvider(summary.trip.id).notifier)
                        .addItem(
                          title: title,
                          kind: kind,
                          tripDayId: tripDayId,
                          inlinePlace: inlinePlace,
                          notes: notes,
                        );
                  },
            ),
          ).then((_) {
            onActivityAdded?.call();
            ref.invalidate(itineraryListProvider(summary.trip.id));
          });
        },
      ),
      _buildActionButton(
        context: context,
        icon: Icons.map_outlined,
        label: 'Directions',
        color: colorScheme.primary,
        onTap: () {
          final dest =
              summary.nextUpcomingItem?.place?.formattedAddress ??
              summary.nextUpcomingItem?.title ??
              summary.currentStay?.address ??
              summary.currentStay?.name ??
              summary.trip.destinationCountry ??
              summary.trip.title;
          MapLauncher.launchDirections(query: dest);
        },
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(14) > 18
            ? 2
            : (constraints.maxWidth >= 350 ? 5 : 3);
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions
              .map((action) => SizedBox(width: width, child: action))
              .toList(),
        );
      },
    );
  }
}
