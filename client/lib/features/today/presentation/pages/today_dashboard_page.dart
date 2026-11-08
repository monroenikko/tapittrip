import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../../trips/domain/models/trip.dart';
import '../../../trips/presentation/providers/trip_list_provider.dart';
import '../providers/today_provider.dart';
import '../widgets/current_stay_banner.dart';
import '../widgets/next_stop_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/today_hero_card.dart';
import '../widgets/trip_progress_card.dart';

import 'package:tapittrip/features/sync/presentation/widgets/sync_status_indicator.dart';

class TodayDashboardPage extends ConsumerStatefulWidget {
  const TodayDashboardPage({super.key, this.initialTripId});

  final String? initialTripId;

  @override
  ConsumerState<TodayDashboardPage> createState() => _TodayDashboardPageState();
}

class _TodayDashboardPageState extends ConsumerState<TodayDashboardPage> {
  @override
  void initState() {
    super.initState();
    if (widget.initialTripId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(activeDashboardTripIdProvider.notifier)
            .selectTrip(widget.initialTripId);
      });
    }
  }

  void _showTripSwitcher(
    BuildContext context,
    List<Trip> trips,
    String currentId,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Select Active Trip',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final isSelected = trip.id == currentId;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? colorScheme.primary
                              : colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.flight_takeoff_rounded,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          trip.title,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          trip.destinationCountry ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          ref
                              .read(activeDashboardTripIdProvider.notifier)
                              .selectTrip(trip.id);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tripsAsync = ref.watch(tripListProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 16,
        leadingWidth: 44,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: AppLogo(
            height: 28,
            width: 28,
            variant: AppLogoVariant.iconOnly,
          ),
        ),
        title: tripsAsync.maybeWhen(
          data: (trips) {
            if (trips.isEmpty) return const Text('TapItTrip');
            final selectedTripId =
                ref.watch(activeDashboardTripIdProvider) ?? trips.first.id;
            final currentTrip = trips.firstWhere(
              (t) => t.id == selectedTripId,
              orElse: () => trips.first,
            );

            return InkWell(
              onTap: trips.length > 1
                  ? () => _showTripSwitcher(context, trips, currentTrip.id)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        currentTrip.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trips.length > 1) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
          orElse: () => const Text('TapItTrip'),
        ),
        actions: [
          const SyncStatusIndicator(),
          IconButton(
            tooltip: 'All Trips',
            icon: const Icon(Icons.luggage_outlined),
            onPressed: () => context.push('/trips'),
          ),
        ],
      ),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load trips',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(tripListProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (trips) {
          if (trips.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.map_rounded,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome to TapItTrip',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your travel companion is one tap away. Plan your first adventure or import your bookings to begin.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.push('/trips/new'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Plan a Trip'),
                    ),
                  ],
                ),
              ),
            );
          }

          final selectedTripId =
              ref.watch(activeDashboardTripIdProvider) ?? trips.first.id;
          final summaryAsync = ref.watch(todaySummaryProvider(selectedTripId));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(todaySummaryProvider(selectedTripId));
              await ref.read(tripListProvider.notifier).refresh();
            },
            child: summaryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 48,
                              color: Colors.orangeAccent,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load today summary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              err.toString(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => ref.invalidate(
                                todaySummaryProvider(selectedTripId),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              data: (summary) {
                final currentTrip = trips.firstWhere(
                  (t) => t.id == selectedTripId,
                  orElse: () => summary.trip,
                );

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    TodayHeroCard(summary: summary),
                    const SizedBox(height: 16),
                    QuickActionsGrid(
                      summary: summary,
                      onViewItinerary: () => context.push(
                        '/trips/${summary.trip.id}/itinerary',
                        extra: currentTrip,
                      ),
                      onViewStays: () => context.push(
                        '/trips/${summary.trip.id}/itinerary',
                        extra: currentTrip,
                      ),
                      onActivityAdded: () {
                        ref.invalidate(todaySummaryProvider(selectedTripId));
                      },
                    ),
                    const SizedBox(height: 16),
                    TripProgressCard(summary: summary),
                    const SizedBox(height: 16),
                    NextStopCard(
                      summary: summary,
                      onActivityAdded: () {
                        ref.invalidate(todaySummaryProvider(selectedTripId));
                      },
                    ),
                    const SizedBox(height: 16),
                    CurrentStayBanner(summary: summary),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/lounges?iata=MNL'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.airline_seat_recline_extra_rounded,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Airport Lounge Finder',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Explore terminal lounges, amenities & gate tips',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
