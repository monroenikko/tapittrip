import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/widgets/app_logo.dart';
import 'package:tapittrip/features/auth/domain/models/auth_state.dart';
import 'package:tapittrip/features/auth/presentation/providers/auth_provider.dart';
import 'package:tapittrip/features/trips/presentation/providers/trip_list_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tripsAsync = ref.watch(tripListProvider);
    final authState = ref.watch(authProvider);

    final userName = authState is Authenticated
        ? authState.user.name
        : 'Traveler';

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
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Account menu',
            onSelected: (value) async {
              if (value == 'logout') {
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
                  await ref.read(authProvider.notifier).deleteAccount();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  authState is Authenticated ? authState.user.email : '',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Log out'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete account',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(tripListProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  SearchPillBar(onTap: () => context.push('/trips/new')),
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
                        onTap: () => context.push('/trips/new'),
                      ),
                      QuickActionItem(
                        label: 'Smart Route',
                        icon: Icons.alt_route,
                        onTap: () => context.push('/trips/new'),
                      ),
                      QuickActionItem(
                        label: 'Budget Plan',
                        icon: Icons.account_balance_wallet_outlined,
                        onTap: () => context.push('/trips/new'),
                      ),
                      QuickActionItem(
                        label: 'Travel Guide',
                        icon: Icons.menu_book_outlined,
                        onTap: () => context.push('/trips/new'),
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
                      TextButton(
                        onPressed: () => context.push('/trips/new'),
                        child: const Text('Add Trip'),
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
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.2,
                        ),
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
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: trips.map((trip) {
                    return TripCard(
                      trip: trip,
                      onTap: () => context.push(
                        '/trips/${trip.id}/itinerary',
                        extra: trip,
                      ),
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Trip'),
                            content: Text('Delete "${trip.title}"?'),
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
                          await ref
                              .read(tripListProvider.notifier)
                              .deleteTrip(trip.id);
                        }
                      },
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
        onDestinationSelected: (index) {
          setState(() => _selectedTabIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Itinerary',
          ),
          NavigationDestination(
            icon: Icon(Icons.airplane_ticket_outlined),
            selectedIcon: Icon(Icons.airplane_ticket),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
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
