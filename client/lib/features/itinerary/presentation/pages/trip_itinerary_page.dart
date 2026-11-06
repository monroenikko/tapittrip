import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/activity_timeline_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/add_activity_bottom_sheet.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/itinerary_filter_tabs.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/route_summary_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/timeline_day_badge.dart';
import 'package:tapittrip/features/stays/presentation/providers/stay_provider.dart';
import 'package:tapittrip/features/stays/presentation/widgets/add_stay_bottom_sheet.dart';
import 'package:tapittrip/features/stays/presentation/widgets/stay_card.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';
import 'package:tapittrip/features/trips/presentation/providers/trip_list_provider.dart';

class TripItineraryPage extends ConsumerStatefulWidget {
  const TripItineraryPage({super.key, required this.tripId, this.initialTrip});

  final String tripId;
  final Trip? initialTrip;

  @override
  ConsumerState<TripItineraryPage> createState() => _TripItineraryPageState();
}

class _TripItineraryPageState extends ConsumerState<TripItineraryPage> {
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
    final days = ref.read(tripDaysProvider(widget.tripId)).asData?.value ?? [];

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
                  .read(itineraryListProvider(widget.tripId).notifier)
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

  Future<void> _onRefresh() async {
    if (_selectedTabIndex == 2) {
      await ref.read(stayListProvider(widget.tripId).notifier).refresh();
    } else {
      await ref.read(itineraryListProvider(widget.tripId).notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trip = _resolveTrip();
    final itemsAsync = ref.watch(itineraryListProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Itinerary'),
        actions: [
          if (_selectedTabIndex == 0)
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
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          if (kDebugMode) {
            debugPrint('Error loading itinerary for ${widget.tripId}: $err');
          }
          return CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
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
                          'Check your connection and try again.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => ref
                              .read(
                                itineraryListProvider(widget.tripId).notifier,
                              )
                              .refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        data: (items) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
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
                        width: 72,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: colorScheme.primaryContainer,
                          image: const DecorationImage(
                            image: AssetImage('assets/images/logo_icon.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Route summary banner
                const RouteSummaryCard(
                  distance: '142 km',
                  estimatedCost: '\$1,240',
                  co2Saved: '18 kg',
                ),
                const SizedBox(height: 16),

                // Filter tabs: [Itinerary, Transport, Stay, Recommendations]
                ItineraryFilterTabs(
                  selectedIndex: _selectedTabIndex,
                  onTabSelected: (index) {
                    setState(() => _selectedTabIndex = index);
                  },
                ),
                const SizedBox(height: 16),

                // Content based on selected tab
                if (_selectedTabIndex == 2)
                  _buildStaysTab(theme, colorScheme)
                else if (_selectedTabIndex == 1)
                  _buildTransportTab(theme, colorScheme, items)
                else if (_selectedTabIndex == 3)
                  _buildRecommendationsTab(theme, colorScheme)
                else
                  _buildItineraryTab(theme, colorScheme, items),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: _selectedTabIndex == 2
                ? () => AddStayBottomSheet.show(context, widget.tripId)
                : _openAddActivitySheet,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              _selectedTabIndex == 2 ? 'Add Accommodation' : 'Add Activity',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaysTab(ThemeData theme, ColorScheme colorScheme) {
    final staysAsync = ref.watch(stayListProvider(widget.tripId));

    return staysAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unable to load accommodations',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Check your connection and try again.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref
                      .read(stayListProvider(widget.tripId).notifier)
                      .refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
      data: (stays) {
        if (stays.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hotel_outlined,
                    size: 48,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No accommodation added yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Add your hotel, hostel, or rental to view check-in details and luggage-aware arrival transport.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        AddStayBottomSheet.show(context, widget.tripId),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Accommodation'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: stays.map((stay) => StayCard(stay: stay)).toList(),
        );
      },
    );
  }

  Widget _buildTransportTab(
    ThemeData theme,
    ColorScheme colorScheme,
    List<dynamic> items,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_transit_filled_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Transit & Arrival Transport',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'View luggage-aware arrival options by visiting the "Stay" tab and selecting "Arrival Transport".',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => setState(() => _selectedTabIndex = 2),
              child: const Text('Go to Stays'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsTab(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 48,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            Text(
              'Recommendations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Personalized destination highlights will appear here as you build your trip.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryTab(
    ThemeData theme,
    ColorScheme colorScheme,
    List<dynamic> items,
  ) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'No activities planned yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap "Add Activity" below to plan your first stop.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isReordering) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        // ignore: deprecated_member_use
        onReorder: (oldIndex, newIndex) {
          ref
              .read(itineraryListProvider(widget.tripId).notifier)
              .reorder(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            key: ValueKey(item.id),
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: colorScheme.primary,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(item.title),
            subtitle: item.place != null ? Text(item.place!.name) : null,
            trailing: const Icon(Icons.drag_handle_rounded),
          );
        },
      );
    }

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TimelineDayBadge(dayNumber: index + 1, isLast: isLast),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActivityTimelineCard(
                    item: item,
                    onToggleVisited: () {
                      ref
                          .read(itineraryListProvider(widget.tripId).notifier)
                          .toggleVisited(item);
                    },
                    onDelete: () {
                      ref
                          .read(itineraryListProvider(widget.tripId).notifier)
                          .deleteItem(item.id);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
