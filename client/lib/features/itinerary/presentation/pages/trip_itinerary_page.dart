import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tapittrip/core/constants/countries.dart';
import 'package:tapittrip/core/utils/currency_formatter.dart';
import 'package:tapittrip/features/auth/domain/models/auth_state.dart';
import 'package:tapittrip/features/auth/presentation/providers/auth_provider.dart';
import 'package:tapittrip/features/checklists/presentation/providers/checklist_provider.dart';
import 'package:tapittrip/features/checklists/presentation/widgets/add_checklist_item_bottom_sheet.dart';
import 'package:tapittrip/features/checklists/presentation/widgets/checklist_template_dialog.dart';
import 'package:tapittrip/features/checklists/presentation/widgets/checklists_view.dart';
import 'package:tapittrip/features/expenses/data/currency_repository.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/activity_timeline_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/add_activity_bottom_sheet.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/ai_itinerary_planner_dialog.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/ask_tapittrip_sheet.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/itinerary_filter_tabs.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/route_summary_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/timeline_day_badge.dart';
import 'package:tapittrip/features/stays/presentation/providers/stay_provider.dart';
import 'package:tapittrip/features/stays/presentation/widgets/add_stay_bottom_sheet.dart';
import 'package:tapittrip/features/stays/presentation/widgets/stay_card.dart';
import 'package:tapittrip/features/sync/presentation/widgets/sync_status_indicator.dart';
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

  void _openAiPlanner() {
    final trip = _resolveTrip();
    int initialDays = 3;
    if (trip?.startDate != null && trip?.endDate != null) {
      final start = DateTime.tryParse(trip!.startDate!);
      final end = DateTime.tryParse(trip.endDate!);
      if (start != null && end != null) {
        initialDays = (end.difference(start).inDays + 1).clamp(1, 7);
      }
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AiItineraryPlannerDialog(
        tripId: widget.tripId,
        initialDestination: trip?.destinationCountry != null
            ? '${trip!.title}, ${trip.destinationCountry}'
            : trip?.title,
        initialDays: initialDays,
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
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Plan with AI',
            onPressed: _openAiPlanner,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Ask TapItTrip',
            onPressed: () =>
                AskTapItTripSheet.show(context, tripId: widget.tripId),
          ),
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
          SyncStatusIndicator(tripId: widget.tripId),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'notifications') {
                context.push('/notifications/preferences');
              } else if (value == 'expenses') {
                context.push('/trips/${widget.tripId}/expenses');
              } else if (value == 'journal') {
                context.push('/trips/${widget.tripId}/journal');
              } else if (value == 'favorite') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Itinerary saved to favorites.'),
                  ),
                );
              } else if (value == 'refresh') {
                _onRefresh();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'notifications',
                child: Row(
                  children: [
                    Icon(Icons.notifications_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Notifications'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'expenses',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Expenses & Budget'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'journal',
                child: Row(
                  children: [
                    Icon(Icons.auto_stories_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Memories & Journal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'favorite',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_border_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Save to favorites'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
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
                Builder(
                  builder: (context) {
                    final destCurrency = (trip?.destinationCurrency != null &&
                            trip!.destinationCurrency!.isNotEmpty)
                        ? trip.destinationCurrency!
                        : CountryCurrencyHelper.resolveCurrency(
                            trip?.destinationCountry ?? trip?.title,
                            defaultCurrency: 'JPY',
                          );
                    final authState = ref.watch(authProvider);
                    final authUser = authState is Authenticated ? authState.user : null;
                    final homeCurrency = authUser?.homeCurrency ?? 'PHP';

                    final num baseDestCost = destCurrency == 'JPY'
                        ? 18500
                        : (destCurrency == 'PHP'
                            ? 6800
                            : (destCurrency == 'EUR'
                                ? 115
                                : (destCurrency == 'GBP' ? 95 : 120)));

                    final formattedDest = CurrencyFormatter.formatAmount(
                      baseDestCost,
                      destCurrency,
                      isMinor: false,
                    );

                    String? costSubtitle;
                    if (homeCurrency.toUpperCase() != destCurrency.toUpperCase()) {
                      final rateAsync = ref.watch(
                        currencyRateProvider((from: destCurrency, to: homeCurrency)),
                      );
                      final rate = rateAsync.asData?.value;
                      if (rate != null) {
                        final converted = baseDestCost * rate.rate;
                        costSubtitle = '≈ ${CurrencyFormatter.formatAmount(converted, homeCurrency, isMinor: false)}';
                      }
                    }

                    return RouteSummaryCard(
                      distance: '142 km',
                      estimatedCost: formattedDest,
                      estimatedCostSubtitle: costSubtitle,
                      co2Saved: '18 kg',
                    );
                  },
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
                  ChecklistsView(tripId: widget.tripId)
                else if (_selectedTabIndex == 4)
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
                : _selectedTabIndex == 3
                ? _openAddChecklistItem
                : _openAddActivitySheet,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              _selectedTabIndex == 2
                  ? 'Add Accommodation'
                  : _selectedTabIndex == 3
                  ? 'Add Packing Item'
                  : 'Add Activity',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  void _openAddChecklistItem() {
    final checklists =
        ref.read(checklistListProvider(widget.tripId)).asData?.value ?? [];
    if (checklists.isEmpty) {
      ChecklistTemplateDialog.show(
        context,
        onSelectTemplate: (templateKey) async {
          await ref
              .read(checklistListProvider(widget.tripId).notifier)
              .applyTemplate(templateKey);
        },
      );
    } else {
      final activeChecklist = checklists.first;
      AddChecklistItemBottomSheet.show(
        context,
        checklistId: activeChecklist.id,
        onSubmit:
            ({
              required String title,
              required String category,
              required int quantity,
              String? notes,
              String? photoUrl,
            }) async {
              await ref
                  .read(checklistListProvider(widget.tripId).notifier)
                  .addItem(
                    checklistId: activeChecklist.id,
                    title: title,
                    category: category,
                    quantity: quantity,
                    notes: notes,
                    photoUrl: photoUrl,
                  );
            },
      );
    }
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
                'Tap "Add Activity" below to plan your first stop, or let AI propose a curated route.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Plan with AI'),
                onPressed: _openAiPlanner,
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
                    onEdit: () {
                      final days =
                          ref
                              .read(tripDaysProvider(widget.tripId))
                              .asData
                              ?.value ??
                          [];
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => AddActivityBottomSheet(
                          tripId: widget.tripId,
                          days: days,
                          initialItem: item,
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
                                      itineraryListProvider(widget.tripId)
                                          .notifier,
                                    )
                                    .updateItem(
                                      item.id,
                                      title: title,
                                      kind: kind,
                                      tripDayId: tripDayId,
                                      inlinePlace: inlinePlace,
                                      notes: notes,
                                    );
                              },
                        ),
                      );
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
