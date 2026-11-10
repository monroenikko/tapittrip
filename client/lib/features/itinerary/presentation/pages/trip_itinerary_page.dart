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
import 'package:tapittrip/features/itinerary/domain/models/ai_itinerary_plan.dart';
import 'package:tapittrip/features/itinerary/domain/models/itinerary_item.dart';
import 'package:tapittrip/features/itinerary/domain/models/trip_day.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/activity_timeline_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/add_activity_bottom_sheet.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/ai_itinerary_planner_dialog.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/ai_itinerary_preview_sheet.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/ask_tapittrip_sheet.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/itinerary_filter_tabs.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/route_summary_card.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/timeline_day_badge.dart';
import 'package:tapittrip/features/lounges/data/lounge_repository.dart';
import 'package:tapittrip/features/lounges/presentation/providers/lounge_provider.dart';
import 'package:tapittrip/features/stays/presentation/providers/stay_provider.dart';
import 'package:tapittrip/features/stays/presentation/widgets/add_stay_bottom_sheet.dart';
import 'package:tapittrip/features/stays/presentation/widgets/stay_card.dart';
import 'package:tapittrip/features/sync/presentation/widgets/sync_status_indicator.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';
import 'package:tapittrip/features/trips/presentation/providers/trip_list_provider.dart';
import 'package:tapittrip/features/weather/presentation/providers/weather_provider.dart';
import 'package:tapittrip/features/weather/presentation/widgets/trip_weather_view.dart';

class TripItineraryPage extends ConsumerStatefulWidget {
  const TripItineraryPage({super.key, required this.tripId, this.initialTrip});

  final String tripId;
  final Trip? initialTrip;

  @override
  ConsumerState<TripItineraryPage> createState() => _TripItineraryPageState();
}

class _TripItineraryPageState extends ConsumerState<TripItineraryPage> {
  int _selectedTabIndex = 0;
  String? _selectedDayFilterId;
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchLounges();
    });
  }

  void _prefetchLounges() {
    final trip = _resolveTrip();
    final loungeRepo = ref.read(loungeRepositoryProvider);
    final codes = LoungeRepository.detectAirportsForTrip(trip);
    loungeRepo.prefetchAirports(codes);
  }

  Trip? _resolveTrip() {
    if (widget.initialTrip != null) return widget.initialTrip;
    final trips = ref.watch(tripListProvider).asData?.value;
    if (trips == null) return null;
    return trips.cast<Trip?>().firstWhere(
      (t) => t?.id == widget.tripId,
      orElse: () => null,
    );
  }

  void _openAddActivitySheet({String? preselectedDayId}) {
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
        selectedDayId: preselectedDayId ?? _selectedDayFilterId,
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

  Future<void> _openAiPlanner() async {
    final trip = _resolveTrip();
    int initialDays = 3;
    if (trip?.startDate != null && trip?.endDate != null) {
      final start = DateTime.tryParse(trip!.startDate!);
      final end = DateTime.tryParse(trip.endDate!);
      if (start != null && end != null) {
        initialDays = (end.difference(start).inDays + 1).clamp(1, 7);
      }
    }

    final plan = await showDialog<AiItineraryPlan>(
      context: context,
      builder: (ctx) => AiItineraryPlannerDialog(
        tripId: widget.tripId,
        initialDestination: trip?.destinationCountry != null
            ? '${trip!.title}, ${trip.destinationCountry}'
            : trip?.title,
        initialDays: initialDays,
      ),
    );

    if (plan != null && mounted) {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) =>
            AiItineraryPreviewSheet(tripId: widget.tripId, plan: plan),
      );

      if (mounted && saved == true) {
        ref.invalidate(itineraryListProvider(widget.tripId));
        ref.invalidate(tripDaysProvider(widget.tripId));
        await ref.read(itineraryListProvider(widget.tripId).notifier).refresh();
      }
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(tripWeatherProvider(widget.tripId));
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
              } else if (value == 'circle') {
                context.push('/trips/${widget.tripId}/circle');
              } else if (value == 'recap') {
                context.push('/trips/${widget.tripId}/recap');
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
                value: 'circle',
                child: Row(
                  children: [
                    Icon(Icons.group_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Trip Circle & Feed'),
                  ],
                ),
              ),
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
                value: 'recap',
                child: Row(
                  children: [
                    Icon(Icons.collections_bookmark_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Story Album & Recap'),
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
                            Builder(
                              builder: (context) {
                                final flag =
                                    CountryCurrencyHelper.resolveFlag(
                                      trip.destinationCountry,
                                    ) ??
                                    CountryCurrencyHelper.resolveFlag(
                                      trip.title,
                                    );

                                return Row(
                                  children: [
                                    if (flag != null &&
                                        !trip.title.startsWith(flag)) ...[
                                      Text(
                                        flag,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        trip.title,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                  ],
                                );
                              },
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
                            // Compact weather pill in trip header
                            Consumer(
                              builder: (context, ref, _) {
                                final weatherAsync = ref.watch(
                                  tripWeatherProvider(widget.tripId),
                                );
                                return weatherAsync.when(
                                  data: (weather) {
                                    final current = weather.current;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => setState(
                                          () => _selectedTabIndex = 3,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: current.weatherColor
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: current.weatherColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                current.weatherIcon,
                                                size: 14,
                                                color: current.weatherColor,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                '${current.tempString} • ${current.condition}',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          current.weatherColor,
                                                    ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                size: 14,
                                                color: current.weatherColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, _) => const SizedBox.shrink(),
                                );
                              },
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
                    final destCurrency =
                        CountryCurrencyHelper.resolveTripCurrency(
                          explicitCurrency: trip?.destinationCurrency,
                          destinationCountry: trip?.destinationCountry,
                          title: trip?.title,
                          defaultCurrency: 'JPY',
                        );
                    final authState = ref.watch(authProvider);
                    final authUser = authState is Authenticated
                        ? authState.user
                        : null;
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
                    if (homeCurrency.toUpperCase() !=
                        destCurrency.toUpperCase()) {
                      final rateAsync = ref.watch(
                        currencyRateProvider((
                          from: destCurrency,
                          to: homeCurrency,
                        )),
                      );
                      final rate = rateAsync.asData?.value;
                      if (rate != null) {
                        final converted = baseDestCost * rate.rate;
                        costSubtitle =
                            '≈ ${CurrencyFormatter.formatAmount(converted, homeCurrency, isMinor: false)}';
                      }
                    }

                    final weatherAsync = ref.watch(
                      tripWeatherProvider(widget.tripId),
                    );
                    final curWeather = weatherAsync.asData?.value.current;

                    return RouteSummaryCard(
                      distance: '142 km',
                      estimatedCost: formattedDest,
                      estimatedCostSubtitle: costSubtitle,
                      co2Saved: '18 kg',
                      weatherText: curWeather?.tempString,
                      weatherIcon: curWeather?.weatherIcon,
                      weatherColor: curWeather?.weatherColor,
                      onWeatherTap: () => setState(() => _selectedTabIndex = 3),
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
                  TripWeatherView(tripId: widget.tripId)
                else if (_selectedTabIndex == 4)
                  ChecklistsView(tripId: widget.tripId)
                else if (_selectedTabIndex == 5)
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
                ? _openRainyDayActivityPlanner
                : _selectedTabIndex == 4
                ? _openAddChecklistItem
                : _openAddActivitySheet,
            icon: Icon(
              _selectedTabIndex == 3
                  ? Icons.umbrella_rounded
                  : Icons.add_rounded,
            ),
            label: Text(
              _selectedTabIndex == 2
                  ? 'Add Accommodation'
                  : _selectedTabIndex == 3
                  ? 'Rainy Day Alternatives'
                  : _selectedTabIndex == 4
                  ? 'Add Packing Item'
                  : 'Add Activity',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  void _openRainyDayActivityPlanner() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AskTapItTripSheet(
        tripId: widget.tripId,
        initialQuery: 'What should we do if it rains?',
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
    List<ItineraryItem> items,
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

    final days = ref.watch(tripDaysProvider(widget.tripId)).asData?.value ?? [];

    final reorderHintBanner = _isReordering
        ? Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag cards by ⋮⋮ (or tap a number badge) to change order or move between days.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => setState(() => _isReordering = false),
                  child: const Text('Done'),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    if (days.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          reorderHintBanner,
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) =>
                _reorderProxyDecorator(child),
            itemCount: items.length,
            onReorderItem: (oldIndex, newIndex) async {
              final ok = await ref
                  .read(itineraryListProvider(widget.tripId).notifier)
                  .reorder(oldIndex, newIndex);
              if (!ok && mounted) {
                _showReorderErrorSnackBar();
              }
            },
            itemBuilder: (context, index) {
              final item = items[index];
              final isLast = index == items.length - 1;

              return ReorderableDelayedDragStartListener(
                key: ValueKey('item_${item.id}'),
                index: index,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TimelineDayBadge(
                        dayNumber: index + 1,
                        isFirst: index == 0,
                        isLast: isLast,
                        isHighlighted: _isReordering,
                        onTap: () => _openMoveStopPositionSheet(
                          item,
                          allItems: items,
                          days: const [],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTimelineCard(
                            item,
                            dragHandle: _buildCardDragHandle(
                              index,
                              colorScheme,
                            ),
                            highlightDrag: _isReordering,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    // Build flattened interactive timeline rows supporting Day grouping + Drag & Drop
    final visibleDays = _selectedDayFilterId != null
        ? [
            days.firstWhere(
              (d) => d.id == _selectedDayFilterId,
              orElse: () => days.first,
            ),
          ]
        : days;

    final rows = <_TimelineRow>[];
    for (final day in visibleDays) {
      final dayItems = items.where((it) => it.tripDayId == day.id).toList();
      rows.add(_DayHeaderRow(day));
      if (dayItems.isEmpty) {
        rows.add(_EmptyDayRow(day));
      } else {
        for (var idx = 0; idx < dayItems.length; idx++) {
          rows.add(
            _ActivityRow(
              item: dayItems[idx],
              ordinal: idx + 1,
              isFirstInDay: idx == 0,
              isLastInDay: idx == dayItems.length - 1,
              dayId: day.id,
            ),
          );
        }
      }
    }

    if (_selectedDayFilterId == null) {
      final unscheduledItems = items
          .where(
            (it) =>
                it.tripDayId == null || !days.any((d) => d.id == it.tripDayId),
          )
          .toList();
      if (unscheduledItems.isNotEmpty) {
        rows.add(_UnscheduledHeaderRow(unscheduledItems.length));
        for (var idx = 0; idx < unscheduledItems.length; idx++) {
          rows.add(
            _ActivityRow(
              item: unscheduledItems[idx],
              ordinal: idx + 1,
              isFirstInDay: idx == 0,
              isLastInDay: idx == unscheduledItems.length - 1,
              dayId: null,
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Day Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('All Days (${items.length})'),
                  selected: _selectedDayFilterId == null,
                  onSelected: (_) =>
                      setState(() => _selectedDayFilterId = null),
                ),
              ),
              ...days.map((day) {
                final count = items
                    .where((it) => it.tripDayId == day.id)
                    .length;
                final isSelected = _selectedDayFilterId == day.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${day.displayTitle} ($count)'),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedDayFilterId = day.id),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        reorderHintBanner,

        // Unified Day-Grouped Reorderable Timeline
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator: (child, index, animation) =>
              _reorderProxyDecorator(child),
          itemCount: rows.length,
          onReorderItem: (oldIndex, newIndex) =>
              _handleUnifiedReorder(oldIndex, newIndex, rows, days, items),
          itemBuilder: (context, index) {
            final row = rows[index];
            return switch (row) {
              _DayHeaderRow(:final day) => Padding(
                key: ValueKey('day_header_${day.id}'),
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: _buildDayHeader(day, theme, colorScheme),
              ),
              _EmptyDayRow(:final day) => Padding(
                key: ValueKey('day_empty_${day.id}'),
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildEmptyDayPlaceholder(day, theme, colorScheme),
              ),
              _UnscheduledHeaderRow(:final count) => Padding(
                key: const ValueKey('unscheduled_header'),
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: _buildUnscheduledHeader(count, theme, colorScheme),
              ),
              _ActivityRow(
                :final item,
                :final ordinal,
                :final isFirstInDay,
                :final isLastInDay,
              ) =>
                ReorderableDelayedDragStartListener(
                  key: ValueKey('item_${item.id}'),
                  index: index,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TimelineDayBadge(
                          dayNumber: ordinal,
                          isFirst: isFirstInDay,
                          isLast: isLastInDay,
                          isHighlighted: _isReordering,
                          onTap: () => _openMoveStopPositionSheet(
                            item,
                            allItems: items,
                            days: days,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: isLastInDay ? 20 : 12,
                            ),
                            child: _buildTimelineCard(
                              item,
                              dragHandle: _buildCardDragHandle(
                                index,
                                colorScheme,
                              ),
                              highlightDrag: _isReordering,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            };
          },
        ),
      ],
    );
  }

  Widget _reorderProxyDecorator(Widget child) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: child,
    );
  }

  Widget _buildCardDragHandle(int index, ColorScheme colorScheme) {
    return ReorderableDragStartListener(
      index: index,
      child: Semantics(
        label: 'Drag to reorder stop',
        child: Tooltip(
          message: 'Drag to reorder card',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: _isReordering
                ? BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Icon(
              Icons.drag_indicator_rounded,
              size: 20,
              color: _isReordering
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleUnifiedReorder(
    int oldIndex,
    int newIndex,
    List<_TimelineRow> rows,
    List<TripDay> days,
    List<ItineraryItem> allItems,
  ) async {
    if (oldIndex < 0 || oldIndex >= rows.length) return;
    final movedRow = rows[oldIndex];
    if (movedRow is! _ActivityRow) return;

    final mutableRows = List<_TimelineRow>.from(rows);
    // ReorderableList.onReorderItem already adjusts newIndex for removal at oldIndex.
    // Clamp so an item never drops above the very first Day/Unscheduled header (index 0).
    final clampedIndex = newIndex.clamp(1, mutableRows.length - 1);
    mutableRows.removeAt(oldIndex);
    mutableRows.insert(clampedIndex, movedRow);

    String? currentDayId;
    final newVisibleBuckets = <String?, List<ItineraryItem>>{};
    final dayAssignments = <String, String?>{};

    for (final row in mutableRows) {
      switch (row) {
        case _DayHeaderRow(:final day):
          currentDayId = day.id;
          newVisibleBuckets.putIfAbsent(currentDayId, () => []);
        case _UnscheduledHeaderRow():
          currentDayId = null;
          newVisibleBuckets.putIfAbsent(null, () => []);
        case _EmptyDayRow():
          break;
        case _ActivityRow(:final item):
          TripDay? targetDay;
          if (currentDayId != null) {
            for (final d in days) {
              if (d.id == currentDayId) {
                targetDay = d;
                break;
              }
            }
          }
          final updatedItem = item.copyWith(
            tripDayId: currentDayId,
            clearTripDay: currentDayId == null,
            day: targetDay,
          );
          if (updatedItem.tripDayId != item.tripDayId) {
            dayAssignments[updatedItem.id] = updatedItem.tripDayId;
          }
          newVisibleBuckets
              .putIfAbsent(currentDayId, () => [])
              .add(updatedItem);
      }
    }

    final finalCompleteItems = <ItineraryItem>[
      for (final d in days)
        if (newVisibleBuckets.containsKey(d.id))
          ...newVisibleBuckets[d.id]!
        else
          ...allItems.where((it) => it.tripDayId == d.id),
      if (newVisibleBuckets.containsKey(null))
        ...newVisibleBuckets[null]!
      else if (_selectedDayFilterId != null)
        ...allItems.where(
          (it) =>
              it.tripDayId == null || !days.any((d) => d.id == it.tripDayId),
        ),
    ];

    final ok = await ref
        .read(itineraryListProvider(widget.tripId).notifier)
        .applyReorderedItems(
          finalCompleteItems,
          dayAssignments: dayAssignments.isNotEmpty ? dayAssignments : null,
        );

    if (!ok && mounted) {
      _showReorderErrorSnackBar();
    }
  }

  void _showReorderErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to save new stop order. Reverted changes.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openMoveStopPositionSheet(
    ItineraryItem item, {
    required List<ItineraryItem> allItems,
    required List<TripDay> days,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MoveStopPositionSheet(
        item: item,
        allItems: allItems,
        days: days,
        onConfirm: (targetDayId, targetOrdinalIndex) async {
          final ok = await ref
              .read(itineraryListProvider(widget.tripId).notifier)
              .moveItemToOrdinal(
                item: item,
                targetDayId: targetDayId,
                targetOrdinalIndex: targetOrdinalIndex,
                knownDays: days,
              );
          if (!ok && mounted) {
            _showReorderErrorSnackBar();
          }
        },
      ),
    );
  }

  Widget _buildDayHeader(
    TripDay day,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.displayHeader,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (day.notes != null &&
                    day.notes!.isNotEmpty &&
                    !day.notes!.startsWith('Day '))
                  Text(
                    day.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Stop', style: TextStyle(fontSize: 12)),
            onPressed: () => _openAddActivitySheet(preselectedDayId: day.id),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayPlaceholder(
    TripDay day,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_location_alt_outlined,
            size: 20,
            color: colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No activities planned for ${day.displayTitle} yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: () => _openAddActivitySheet(preselectedDayId: day.id),
            child: const Text('Add Stop'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnscheduledHeader(
    int count,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 16, color: colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unscheduled / Flexible Activities ($count)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(
    ItineraryItem item, {
    Widget? dragHandle,
    bool highlightDrag = false,
  }) {
    return LiveWeatherActivityTimelineCard(
      tripId: widget.tripId,
      item: item,
      dragHandle: dragHandle,
      highlightDrag: highlightDrag,
      onWeatherTap: () => setState(() => _selectedTabIndex = 3),
      onToggleVisited: () {
        ref
            .read(itineraryListProvider(widget.tripId).notifier)
            .toggleVisited(item);
      },
      onEdit: () {
        final days =
            ref.read(tripDaysProvider(widget.tripId)).asData?.value ?? [];
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
                      .read(itineraryListProvider(widget.tripId).notifier)
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
    );
  }
}

sealed class _TimelineRow {
  const _TimelineRow();
}

final class _DayHeaderRow extends _TimelineRow {
  const _DayHeaderRow(this.day);
  final TripDay day;
}

final class _EmptyDayRow extends _TimelineRow {
  const _EmptyDayRow(this.day);
  final TripDay day;
}

final class _UnscheduledHeaderRow extends _TimelineRow {
  const _UnscheduledHeaderRow(this.count);
  final int count;
}

final class _ActivityRow extends _TimelineRow {
  const _ActivityRow({
    required this.item,
    required this.ordinal,
    required this.isFirstInDay,
    required this.isLastInDay,
    required this.dayId,
  });

  final ItineraryItem item;
  final int ordinal;
  final bool isFirstInDay;
  final bool isLastInDay;
  final String? dayId;
}

class _MoveStopPositionSheet extends StatefulWidget {
  const _MoveStopPositionSheet({
    required this.item,
    required this.allItems,
    required this.days,
    required this.onConfirm,
  });

  final ItineraryItem item;
  final List<ItineraryItem> allItems;
  final List<TripDay> days;
  final Future<void> Function(String? targetDayId, int targetOrdinalIndex)
  onConfirm;

  @override
  State<_MoveStopPositionSheet> createState() => _MoveStopPositionSheetState();
}

class _MoveStopPositionSheetState extends State<_MoveStopPositionSheet> {
  late String? _selectedDayId;
  late int _selectedPositionIndex; // 0-based
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDayId = widget.item.tripDayId;
    if (widget.days.isNotEmpty &&
        _selectedDayId != null &&
        !widget.days.any((d) => d.id == _selectedDayId)) {
      _selectedDayId = null;
    }
    _selectedPositionIndex = _currentIndexInDay(_selectedDayId);
  }

  List<ItineraryItem> _itemsInDay(String? dayId) {
    if (widget.days.isEmpty) {
      return widget.allItems;
    }
    if (dayId == null) {
      return widget.allItems
          .where(
            (it) =>
                it.tripDayId == null ||
                !widget.days.any((d) => d.id == it.tripDayId),
          )
          .toList();
    }
    return widget.allItems.where((it) => it.tripDayId == dayId).toList();
  }

  int _currentIndexInDay(String? dayId) {
    final dayItems = _itemsInDay(dayId);
    final idx = dayItems.indexWhere((it) => it.id == widget.item.id);
    return idx >= 0 ? idx : dayItems.length;
  }

  int _maxPositionCount(String? dayId) {
    final withoutItem = _itemsInDay(dayId)
        .where((it) => it.id != widget.item.id)
        .length;
    return withoutItem + 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final positionCount = _maxPositionCount(_selectedDayId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Change Stop Order',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.item.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.days.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Day',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...widget.days.map((day) {
                      final selected = _selectedDayId == day.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(day.displayTitle),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedDayId = day.id;
                              _selectedPositionIndex = _currentIndexInDay(
                                day.id,
                              ).clamp(0, _maxPositionCount(day.id) - 1);
                            });
                          },
                        ),
                      );
                    }),
                    ChoiceChip(
                      label: const Text('Flexible'),
                      selected: _selectedDayId == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedDayId = null;
                          _selectedPositionIndex = _currentIndexInDay(null)
                              .clamp(0, _maxPositionCount(null) - 1);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Stop Position (Ordinal)',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(positionCount, (idx) {
                final selected = _selectedPositionIndex == idx;
                return ChoiceChip(
                  label: Text('#${idx + 1}'),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedPositionIndex = idx),
                );
              }),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      setState(() => _isSaving = true);
                      await widget.onConfirm(
                        _selectedDayId,
                        _selectedPositionIndex,
                      );
                      if (mounted) {
                        navigator.pop();
                      }
                    },
              child: Text(
                _isSaving
                    ? 'Saving...'
                    : 'Move to Stop #${_selectedPositionIndex + 1}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
