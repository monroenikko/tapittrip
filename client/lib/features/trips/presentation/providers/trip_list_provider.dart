import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/trip_repository.dart';
import '../../domain/models/planning_mode.dart';
import '../../domain/models/trip.dart';

class TripListNotifier extends AsyncNotifier<List<Trip>> {
  late final TripRepository _repository;

  @override
  Future<List<Trip>> build() async {
    _repository = ref.watch(tripRepositoryProvider);
    return _repository.getTrips();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getTrips());
  }

  Future<Trip?> createTrip({
    required String title,
    String? startDate,
    String? endDate,
    String? primaryTimezone,
    String? originCountry,
    String? destinationCountry,
    String? tripType,
    PlanningMode planningMode = PlanningMode.diy,
  }) async {
    try {
      final trip = await _repository.createTrip(
        title: title,
        startDate: startDate,
        endDate: endDate,
        primaryTimezone: primaryTimezone,
        originCountry: originCountry,
        destinationCountry: destinationCountry,
        tripType: tripType,
        planningMode: planningMode,
      );

      final current = state.value ?? [];
      state = AsyncValue.data([trip, ...current]);
      return trip;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<Trip?> updateTrip(
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
    try {
      final updated = await _repository.updateTrip(
        id,
        title: title,
        startDate: startDate,
        endDate: endDate,
        primaryTimezone: primaryTimezone,
        originCountry: originCountry,
        destinationCountry: destinationCountry,
        tripType: tripType,
        planningMode: planningMode,
        status: status,
      );

      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((t) => t.id == id ? updated : t).toList(),
      );
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteTrip(String id) async {
    try {
      await _repository.deleteTrip(id);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((t) => t.id != id).toList());
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final tripListProvider = AsyncNotifierProvider<TripListNotifier, List<Trip>>(
  TripListNotifier.new,
);
