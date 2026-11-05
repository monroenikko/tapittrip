import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/features/trips/data/trip_repository.dart';
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';
import 'package:tapittrip/features/trips/presentation/providers/trip_list_provider.dart';

class FakeTripRepository implements TripRepository {
  final List<Trip> trips = [];

  @override
  Future<List<Trip>> getTrips() async => List.unmodifiable(trips);

  @override
  Future<Trip> getTrip(String id) async => trips.firstWhere((t) => t.id == id);

  @override
  Future<Trip> createTrip({
    required String title,
    String? startDate,
    String? endDate,
    String? primaryTimezone,
    String? originCountry,
    String? destinationCountry,
    String? tripType,
    PlanningMode planningMode = PlanningMode.diy,
  }) async {
    final trip = Trip(
      id: 'trip-${trips.length + 1}',
      ownerId: 'user-1',
      title: title,
      startDate: startDate,
      endDate: endDate,
      primaryTimezone: primaryTimezone ?? 'UTC',
      originCountry: originCountry,
      destinationCountry: destinationCountry,
      tripType: tripType ?? 'leisure',
      planningMode: planningMode,
    );
    trips.add(trip);
    return trip;
  }

  @override
  Future<Trip> updateTrip(
    String id, {
    String? title,
    String? startDate,
    String? endDate,
    String? primaryTimezone,
    String? originCountry,
    String? destinationCountry,
    String? tripType,
    PlanningMode? planningMode,
    String? status,
  }) async {
    final index = trips.indexWhere((t) => t.id == id);
    final existing = trips[index];
    final updated = Trip(
      id: existing.id,
      ownerId: existing.ownerId,
      title: title ?? existing.title,
      startDate: startDate ?? existing.startDate,
      endDate: endDate ?? existing.endDate,
      primaryTimezone: primaryTimezone ?? existing.primaryTimezone,
      originCountry: originCountry ?? existing.originCountry,
      destinationCountry: destinationCountry ?? existing.destinationCountry,
      tripType: tripType ?? existing.tripType,
      planningMode: planningMode ?? existing.planningMode,
      status: status ?? existing.status,
    );
    trips[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTrip(String id) async {
    trips.removeWhere((t) => t.id == id);
  }
}

void main() {
  group('TripListNotifier and CRUD operations across all 4 modes', () {
    test('fetches empty list initially', () async {
      final fakeRepo = FakeTripRepository();
      final container = ProviderContainer(
        overrides: [tripRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final state = await container.read(tripListProvider.future);
      expect(state, isEmpty);
    });

    test('creates and lists trips in all 4 planning modes (v1.4)', () async {
      final fakeRepo = FakeTripRepository();
      final container = ProviderContainer(
        overrides: [tripRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripListProvider.notifier);

      // Mode 1: DIY
      final diyTrip = await notifier.createTrip(
        title: 'Backpacking Southeast Asia',
        planningMode: PlanningMode.diy,
      );
      expect(diyTrip, isNotNull);
      expect(diyTrip!.planningMode, PlanningMode.diy);

      // Mode 2: Already-Booked
      final bookedTrip = await notifier.createTrip(
        title: 'Tokyo Hotel & Flight Confirmation',
        planningMode: PlanningMode.existing,
      );
      expect(bookedTrip, isNotNull);
      expect(bookedTrip!.planningMode, PlanningMode.existing);

      // Mode 3: Guided Tour
      final guidedTrip = await notifier.createTrip(
        title: 'Swiss Alps Group Trek',
        planningMode: PlanningMode.guided,
      );
      expect(guidedTrip, isNotNull);
      expect(guidedTrip!.planningMode, PlanningMode.guided);

      // Mode 4: Simple / Essentials
      final simpleTrip = await notifier.createTrip(
        title: 'Weekend Getaway',
        planningMode: PlanningMode.simple,
      );
      expect(simpleTrip, isNotNull);
      expect(simpleTrip!.planningMode, PlanningMode.simple);

      final allTrips = container.read(tripListProvider).value!;
      expect(allTrips.length, 4);

      // Delete one trip
      final deleted = await notifier.deleteTrip(diyTrip.id);
      expect(deleted, isTrue);

      final remainingTrips = container.read(tripListProvider).value!;
      expect(remainingTrips.length, 3);
      expect(remainingTrips.any((t) => t.id == diyTrip.id), isFalse);
    });
  });
}
