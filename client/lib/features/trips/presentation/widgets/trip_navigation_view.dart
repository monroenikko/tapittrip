import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../flights/presentation/providers/flight_provider.dart';
import '../../../flights/presentation/widgets/add_flight_sheet.dart';
import '../../../stays/presentation/providers/stay_provider.dart';
import '../../domain/models/trip.dart';
import '../localization/navigation_strings.dart';
import '../providers/trip_list_provider.dart';

/// Uses the authorized trip list for both itinerary selection and saved stays.
class TripNavigationView extends ConsumerWidget {
  const TripNavigationView({super.key, required this.bookings});

  final bool bookings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = NavigationStrings(Localizations.localeOf(context));
    final trips = ref.watch(tripListProvider);
    return trips.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.tripError),
            TextButton(
              onPressed: () => ref.read(tripListProvider.notifier).refresh(),
              child: Text(strings.retry),
            ),
          ],
        ),
      ),
      data: (items) => RefreshIndicator(
        onRefresh: () => ref.read(tripListProvider.notifier).refresh(),
        child: ListView(
          key: PageStorageKey(bookings ? 'bookings-list' : 'itinerary-trips'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              bookings ? strings.savedAccommodation : strings.chooseTrip,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(bookings ? strings.bookingsHelp : strings.itineraryHelp),
            const SizedBox(height: 24),
            if (items.isEmpty) ...[
              Text(
                strings.noTrips,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(strings.noTripsHelp),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push('/trips/new'),
                icon: const Icon(Icons.add),
                label: Text(strings.addTrip),
              ),
            ],
            for (final trip in items)
              if (bookings)
                _TripAccommodationSection(key: ValueKey(trip.id), trip: trip)
              else
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: Text(trip.title),
                    subtitle: Text(strings.openItinerary),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/trips/${trip.id}/itinerary',
                      extra: trip,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _TripAccommodationSection extends ConsumerWidget {
  const _TripAccommodationSection({super.key, required this.trip});
  final Trip trip;

  void _open(BuildContext context) {
    context.push('/trips/${trip.id}/itinerary?tab=stays', extra: trip);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = NavigationStrings(Localizations.localeOf(context));
    final stays = ref.watch(stayListProvider(trip.id));
    final flights = ref.watch(flightListProvider(trip.id));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(trip.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text('Flights', style: Theme.of(context).textTheme.titleSmall),
                TextButton.icon(
                  onPressed: () => AddFlightSheet.show(context, trip.id),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add flight'),
                ),
              ],
            ),
            flights.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => TextButton(
                onPressed: () =>
                    ref.read(flightListProvider(trip.id).notifier).refresh(),
                child: const Text('Retry flights'),
              ),
              data: (items) => Column(
                children: [
                  if (items.isEmpty)
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('No flights saved yet.'),
                    ),
                  for (final flight in items)
                    for (final segment in flight.segments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.flight_takeoff_outlined),
                        title: Text(
                          '${segment.originAirport} → ${segment.destinationAirport}',
                        ),
                        subtitle: Text(
                          '${flight.airline ?? 'Flight'} · ${segment.flightNumber}',
                        ),
                        trailing: const Icon(Icons.edit_outlined, size: 18),
                        onTap: () => AddFlightSheet.show(
                          context,
                          trip.id,
                          existingFlight: flight,
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            stays.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.stayError),
                  TextButton(
                    onPressed: () =>
                        ref.read(stayListProvider(trip.id).notifier).refresh(),
                    child: Text(strings.retry),
                  ),
                ],
              ),
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (items.isEmpty) Text(strings.noStays),
                  for (final stay in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(stay.stayTypeIcon),
                      title: Text(stay.name),
                      subtitle: Text(strings.openStays),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(context),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => _open(context),
                icon: const Icon(Icons.hotel_outlined),
                label: Text(strings.manageStays),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
