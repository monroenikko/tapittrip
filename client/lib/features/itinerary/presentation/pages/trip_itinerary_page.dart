import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/activity_timeline_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/add_activity_bottom_sheet.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/itinerary_filter_tabs.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/route_summary_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/timeline_day_badge.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';
import 'package:tapittrip/features/trips/presentation/providers/trip_list_provider.dart';

class TripItineraryPage extends StatelessWidget {
  const TripItineraryPage({super.key, required this.tripId, this.initialTrip});

  final String tripId;
  final Trip? initialTrip;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [currentTripIdProvider.overrideWithValue(tripId)],
      child: _TripItineraryView(tripId: tripId, initialTrip: initialTrip),
    );
  }
}

class _TripItineraryView extends ConsumerStatefulWidget {
  const _TripItineraryView({required this.tripId, this.initialTrip});

  final String tripId;
  final Trip? initialTrip;

  @override
  ConsumerState<_TripItineraryView> createState() => _TripItineraryViewState();
}

class _TripItineraryViewState extends ConsumerState<_TripItineraryView> {
  int _selectedTabIndex = 0;
  bool _isReordering = false;

  Trip? _resolveTrip() {
    if (widget.initialTrip != null) return widget.initialTrip;
    final trips = ref.watch(tripListProvider).asData?.value;
    if (trips == null) return null;
    return trips.cast<Trip?>().firstWhere(
      (t) => t?.id == widget.tripId,
      orElse: () => null,
    );
  }

  void _openAddActivitySheet() {
    final days = ref.read(tripDaysProvider).asData?.value ?? [];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddActivityBottomSheet(
        tripId: widget.tripId,
        days: days,
        onSubmit:
            ({
              required String title,
              required String kind,
              String? tripDayId,
              Map<String, dynamic>? inlinePlace,
              String? notes,
            }) async {
              await ref
                  .read(itineraryListProvider.notifier)
                  .addItem(
                    title: title,
                    kind: kind,
                    tripDayId: tripDayId,
                    inlinePlace: inlinePlace,
                    notes: notes,
                  );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trip = _resolveTrip();
    final itemsAsync = ref.watch(itineraryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Itinerary'),
        actions: [
          IconButton(
            icon: Icon(
              _isReordering ? Icons.done_rounded : Icons.swap_vert_rounded,
            ),
            tooltip: _isReordering ? 'Done reordering' : 'Reorder activities',
            onPressed: () {
              setState(() => _isReordering = !_isReordering);
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            tooltip: 'Save itinerary',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Itinerary saved to favorites.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(itineraryListProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Error loading itinerary',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.read(itineraryListProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          return RefreshIndicator(
            onRefresh: () => ref.read(itineraryListProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 100,
              ),
              children: [
                // Destination Header
                if (trip != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              trip.dateRangeFormatted != null
                                  ? '${trip.dateRangeFormatted!} • ${trip.planningMode.title}'
                                  : trip.planningMode.title,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          trip.destinationCountry ?? 'TRIP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Route summary card from mockup
                const RouteSummaryCard(),
                const SizedBox(height: 16),

                // Pill filter tabs
                ItineraryFilterTabs(
                  selectedIndex: _selectedTabIndex,
                  onTabSelected: (idx) =>
                      setState(() => _selectedTabIndex = idx),
                ),
                const SizedBox(height: 20),

                // Timeline activities
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.alt_route_rounded,
                          size: 48,
                          color: colorScheme.primary.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No stops scheduled yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap the button below to add your first attraction, food stop, or transport activity.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _openAddActivitySheet,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add First Stop'),
                        ),
                      ],
                    ),
                  )
                else if (_isReordering)
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    // ignore: deprecated_member_use
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(itineraryListProvider.notifier)
                          .reorder(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        key: ValueKey(item.id),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          tileColor: colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary,
                            radius: 14,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(item.place?.name ?? item.kind),
                          trailing: const Icon(Icons.drag_handle_rounded),
                        ),
                      );
                    },
                  )
                else
                  Column(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isFirst = index == 0;
                      final isLast = index == items.length - 1;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Timeline day circle badge and connector
                            TimelineDayBadge(
                              dayNumber: index + 1,
                              isFirst: isFirst,
                              isLast: isLast,
                            ),
                            const SizedBox(width: 14),
                            // Activity Card
                            Expanded(
                              child: ActivityTimelineCard(
                                item: item,
                                onToggleVisited: () {
                                  ref
                                      .read(itineraryListProvider.notifier)
                                      .toggleVisited(item);
                                },
                                onDelete: () {
                                  ref
                                      .read(itineraryListProvider.notifier)
                                      .deleteItem(item.id);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),

                if (items.isNotEmpty && !_isReordering) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _openAddActivitySheet,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Activity'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      // Bottom Stadium CTA matching mockup ("✨ Optimize with AI" / "Add Activity")
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: _openAddActivitySheet,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text(
              'Add Activity',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
