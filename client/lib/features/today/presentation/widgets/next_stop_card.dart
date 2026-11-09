import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/map_launcher.dart';
import '../../../itinerary/presentation/providers/itinerary_provider.dart';
import '../../../itinerary/presentation/widgets/add_activity_bottom_sheet.dart';
import '../../domain/models/today_dashboard_summary.dart';

class NextStopCard extends ConsumerWidget {
  const NextStopCard({super.key, required this.summary, this.onActivityAdded});

  final TodayDashboardSummary summary;
  final VoidCallback? onActivityAdded;

  IconData _iconForKind(String kind) {
    switch (kind.toLowerCase()) {
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'meal':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'attraction':
      default:
        return Icons.explore_rounded;
    }
  }

  Future<void> _openDirections(BuildContext context, dynamic item) async {
    final place = item.place;
    final success = await MapLauncher.launchDirections(
      latitude: place?.latitude,
      longitude: place?.longitude,
      query: place?.formattedAddress ?? place?.name ?? item.title,
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to launch maps navigation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nextItem = summary.nextUpcomingItem;

    if (nextItem == null) {
      // Empty or completed state
      final hasTodayItems = summary.todayItems.isNotEmpty;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasTodayItems
                        ? Icons.check_circle_outline_rounded
                        : Icons.explore_outlined,
                    color: colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasTodayItems
                            ? 'All caught up for today!'
                            : 'No stops scheduled today',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasTodayItems
                            ? 'You completed all planned activities. Enjoy your free time!'
                            : 'Explore freely or add activities whenever you are ready.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
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
                                .read(
                                  itineraryListProvider(summary.trip.id)
                                      .notifier,
                                )
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
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Activity'),
              ),
            ),
          ],
        ),
      );
    }

    final place = nextItem.place;
    final placeName = place?.name ?? nextItem.title;
    final address = place?.formattedAddress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 12,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.navigation_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'NEXT STOP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (nextItem.startsAtUtc != null)
                Text(
                  nextItem.startsAtUtc!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _iconForKind(nextItem.kind),
                  color: colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextItem.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (placeName != nextItem.title) ...[
                      const SizedBox(height: 2),
                      Text(
                        placeName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (address != null && address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OverflowBar(
            spacing: 12,
            overflowSpacing: 8,
            alignment: MainAxisAlignment.spaceBetween,
            children: [
              FilledButton.icon(
                onPressed: () => _openDirections(context, nextItem),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Directions'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(itineraryListProvider(summary.trip.id).notifier)
                      .toggleVisited(nextItem);
                  onActivityAdded?.call();
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Visited'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
