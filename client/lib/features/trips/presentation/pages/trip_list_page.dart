import 'package:flutter/material.dart';

import '../localization/navigation_strings.dart';
import '../widgets/trip_navigation_view.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/widgets/app_logo.dart';
import 'package:tapittrip/features/auth/domain/models/auth_state.dart';
import 'package:tapittrip/features/auth/presentation/providers/auth_provider.dart';
import 'package:tapittrip/features/circles/presentation/providers/trip_circle_provider.dart';
import 'package:tapittrip/features/circles/presentation/widgets/join_trip_sheet.dart';
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';
import 'package:tapittrip/features/trips/presentation/providers/trip_list_provider.dart';
import 'package:tapittrip/features/trips/presentation/widgets/edit_trip_bottom_sheet.dart';
import 'package:tapittrip/features/trips/presentation/widgets/quick_actions_row.dart';
import 'package:tapittrip/features/trips/presentation/widgets/search_pill_bar.dart';
import 'package:tapittrip/features/trips/presentation/widgets/trip_card.dart';

class TripListPage extends ConsumerStatefulWidget {
  const TripListPage({super.key});

  @override
  ConsumerState<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends ConsumerState<TripListPage> {
  int _selectedTabIndex = 0;
  int _profileReturnIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PlanningMode? _selectedModeFilter;
  String? _selectedTypeFilter;

  static const _tripTypes = <String>[
    'leisure',
    'business',
    'family',
    'solo',
    'adventure',
  ];

  bool get _hasActiveFilters =>
      _selectedModeFilter != null || _selectedTypeFilter != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Trip> _filterTrips(List<Trip> trips) {
    final query = _searchQuery.trim().toLowerCase();
    return trips.where((trip) {
      if (_selectedModeFilter != null &&
          trip.planningMode != _selectedModeFilter) {
        return false;
      }
      if (_selectedTypeFilter != null &&
          trip.tripType.toLowerCase() != _selectedTypeFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = [
        trip.title,
        trip.destinationCountry ?? '',
        trip.planningMode.title,
        trip.tripType,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _clearSearchAndFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedModeFilter = null;
      _selectedTypeFilter = null;
    });
  }

  Future<void> _openFilterSheet() async {
    PlanningMode? tempMode = _selectedModeFilter;
    String? tempType = _selectedTypeFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
            final colorScheme = theme.colorScheme;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filter Trips', style: theme.textTheme.titleLarge),
                        if (tempMode != null || tempType != null)
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                tempMode = null;
                                tempType = null;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Planning Mode',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: tempMode == null,
                          onSelected: (_) =>
                              setSheetState(() => tempMode = null),
                        ),
                        for (final mode in PlanningMode.values)
                          ChoiceChip(
                            label: Text(mode.title),
                            selected: tempMode == mode,
                            onSelected: (_) =>
                                setSheetState(() => tempMode = mode),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Trip Type',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: tempType == null,
                          onSelected: (_) =>
                              setSheetState(() => tempType = null),
                        ),
                        for (final type in _tripTypes)
                          ChoiceChip(
                            label: Text(
                              type[0].toUpperCase() + type.substring(1),
                            ),
                            selected: tempType == type,
                            onSelected: (_) =>
                                setSheetState(() => tempType = type),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _selectedModeFilter = tempMode;
                            _selectedTypeFilter = tempType;
                          });
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openQuickAction({
    required String title,
    required String subtitle,
    required void Function(Trip trip) onTripSelected,
  }) async {
    final trips = ref.read(tripListProvider).asData?.value ?? const <Trip>[];

    if (trips.isEmpty) {
      if (!mounted) return;
      context.push('/trips/new');
      return;
    }

    if (trips.length == 1) {
      onTripSelected(trips.first);
      return;
    }

    final selected = await showModalBottomSheet<Trip>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: trips.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final trip = trips[index];
                      return Material(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(ctx).pop(trip),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flight_takeoff_rounded,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trip.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      if (trip.destinationCountry != null &&
                                          trip.destinationCountry!.isNotEmpty)
                                        Text(
                                          trip.destinationCountry!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
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
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.push('/trips/new');
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create new trip instead'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      onTripSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentTab = _selectedTabIndex == 3
        ? _profileReturnIndex
        : _selectedTabIndex;
    final strings = NavigationStrings(Localizations.localeOf(context));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final tripsAsync = ref.watch(tripListProvider);

    final userName = authState.user.name;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(
              height: 38,
              width: 38,
              variant: AppLogoVariant.iconOnly,
              borderRadius: 10,
            ),
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.push('/profile'),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TapItTrip',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Hello, $userName',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final pendingCount = ref.watch(pendingInboxCountProvider);
              return IconButton(
                tooltip: 'Circle Inbox',
                onPressed: () => context.push('/invitations/inbox'),
                icon: pendingCount > 0
                    ? Badge.count(
                        count: pendingCount,
                        child: const Icon(Icons.mark_email_unread_outlined),
                      )
                    : const Icon(Icons.inbox_outlined),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Today Dashboard',
            onPressed: () => context.push('/dashboard'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Account menu',
            onSelected: (value) async {
              if (value == 'profile') {
                context.push('/profile');
              } else if (value == 'logout') {
                await ref.read(authProvider.notifier).logout();
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text(
                      'Are you sure you want to delete your account? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final error = await ref
                      .read(authProvider.notifier)
                      .deleteAccount();
                  if (error != null && context.mounted) {
                    await showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cannot Delete Account'),
                        content: Text(error),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) {
              final email = authState.user.email;
              final initial = userName.isNotEmpty
                  ? userName[0].toUpperCase()
                  : 'T';
              return [
                PopupMenuItem(
                  enabled: false,
                  height: 56,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          initial,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 8),
                PopupMenuItem(
                  value: 'profile',
                  height: 44,
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 19,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Profile & Currency',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  height: 44,
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 19,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Log out',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 8),
                PopupMenuItem(
                  value: 'delete',
                  height: 44,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete account',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: contentTab == 1 || contentTab == 2
          ? TripNavigationView(bookings: contentTab == 2)
          : RefreshIndicator(
              onRefresh: () => ref.read(tripListProvider.notifier).refresh(),
              child: ListView(
                key: const PageStorageKey('home-trip-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Journey,\nIntelligently Planned.',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'AI-powered travel planning made effortless.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SearchPillBar(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          onFilterTap: _openFilterSheet,
                          hasActiveFilters: _hasActiveFilters,
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (_selectedModeFilter != null)
                                InputChip(
                                  label: Text(_selectedModeFilter!.title),
                                  onDeleted: () => setState(
                                    () => _selectedModeFilter = null,
                                  ),
                                ),
                              if (_selectedTypeFilter != null)
                                InputChip(
                                  label: Text(
                                    _selectedTypeFilter![0].toUpperCase() +
                                        _selectedTypeFilter!.substring(1),
                                  ),
                                  onDeleted: () => setState(
                                    () => _selectedTypeFilter = null,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          'Quick Actions',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        QuickActionsRow(
                          actions: [
                            QuickActionItem(
                              label: 'AI Itinerary',
                              icon: Icons.auto_awesome,
                              onTap: () => _openQuickAction(
                                title: 'AI Itinerary',
                                subtitle: 'Choose a trip to generate or refine an AI itinerary.',
                                onTripSelected: (trip) {
                                  final route = trip.role == 'viewer'
                                      ? '/trips/${trip.id}/itinerary'
                                      : '/trips/${trip.id}/itinerary?action=ai-plan';
                                  context.push(route, extra: trip);
                                },
                              ),
                            ),
                            QuickActionItem(
                              label: 'Smart Route',
                              icon: Icons.alt_route,
                              onTap: () => _openQuickAction(
                                title: 'Smart Route',
                                subtitle: 'Choose a trip to optimize stop order and compare transit.',
                                onTripSelected: (trip) => context.push(
                                  '/trips/${trip.id}/itinerary?tab=transport',
                                  extra: trip,
                                ),
                              ),
                            ),
                            QuickActionItem(
                              label: 'Budget Plan',
                              icon: Icons.account_balance_wallet_outlined,
                              onTap: () => _openQuickAction(
                                title: 'Budget Plan',
                                subtitle: 'Choose a trip to manage budgets, expenses, and splits.',
                                onTripSelected: (trip) =>
                                    context.push('/trips/${trip.id}/expenses'),
                              ),
                            ),
                            QuickActionItem(
                              label: 'Travel Guide',
                              icon: Icons.menu_book_outlined,
                              onTap: () => _openQuickAction(
                                title: 'Travel Guide',
                                subtitle: 'Choose a trip to explore local sights and food spots.',
                                onTripSelected: (trip) => context.push(
                                  '/trips/${trip.id}/itinerary?tab=recommendations',
                                  extra: trip,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Trips',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  onPressed: () => JoinTripSheet.show(context),
                                  icon: const Icon(
                                    Icons.group_add_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Join Invite'),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/trips/new'),
                                  child: const Text('Add Trip'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  tripsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) {
                      final message = error is ApiException
                          ? error.message
                          : 'Unable to load trips. Please try again.';
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_off_outlined,
                              size: 48,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonal(
                              onPressed: () =>
                                  ref.read(tripListProvider.notifier).refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    },
                    data: (trips) {
                      if (trips.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.luggage_outlined,
                                  size: 48,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No trips yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap below to plan your first journey across any mode.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => context.push('/trips/new'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create your first trip'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => JoinTripSheet.show(context),
                                  icon: const Icon(Icons.group_add_outlined),
                                  label: const Text('Join via Invite Code'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final visibleTrips = _filterTrips(trips);
                      if (visibleTrips.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 40,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No matching trips',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try a different destination or clear your active filters.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    OutlinedButton(
                                      onPressed: _clearSearchAndFilters,
                                      child: const Text('Clear filters'),
                                    ),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          context.push('/trips/new'),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('New Trip'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: visibleTrips.map((trip) {
                          final canEdit = trip.role != 'viewer';
                          final canDelete =
                              trip.role == null || trip.role == 'owner';

                          return LiveWeatherTripCard(
                            trip: trip,
                            onTap: () => context.push(
                              '/trips/${trip.id}/itinerary',
                              extra: trip,
                            ),
                            onEdit: canEdit
                                ? () => EditTripBottomSheet.show(context, trip)
                                : null,
                            onDelete: canDelete
                                ? () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Trip'),
                                        content: Text(
                                          'Delete "${trip.title}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  colorScheme.error,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref
                                          .read(tripListProvider.notifier)
                                          .deleteTrip(trip.id);
                                    }
                                  }
                                : null,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) async {
          if (index == _selectedTabIndex) return;
          if (index == 3) {
            final previous = _selectedTabIndex;
            setState(() {
              _profileReturnIndex = previous;
              _selectedTabIndex = index;
            });
            try {
              await context.push('/profile');
            } finally {
              if (mounted) setState(() => _selectedTabIndex = previous);
            }
          } else {
            setState(() => _selectedTabIndex = index);
          }
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: strings.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: strings.itinerary,
          ),
          NavigationDestination(
            icon: Icon(Icons.airplane_ticket_outlined),
            selectedIcon: Icon(Icons.airplane_ticket),
            label: strings.bookings,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: strings.profile,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/trips/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
