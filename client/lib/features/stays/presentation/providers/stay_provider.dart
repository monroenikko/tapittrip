import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/stay_repository.dart';
import '../../domain/models/luggage_profile.dart';
import '../../domain/models/stay.dart';
import '../../domain/models/transport_option.dart';

final stayRepositoryProvider = Provider<StayRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StayRepository(apiClient: apiClient);
});

class StayListNotifier extends AsyncNotifier<List<Stay>> {
  StayListNotifier(this.tripId);

  final String tripId;
  late final StayRepository _repository;

  @override
  Future<List<Stay>> build() async {
    _repository = ref.watch(stayRepositoryProvider);
    return _repository.fetchStays(tripId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchStays(tripId));
  }

  Future<Stay> addStay({
    required String name,
    String stayType = 'hotel',
    String? address,
    double? latitude,
    double? longitude,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String timezone = 'UTC',
    String? phone,
    String? bookingReference,
    String? notes,
    LuggageProfile? luggageProfile,
  }) async {
    final newStay = await _repository.createStay(
      tripId,
      name: name,
      stayType: stayType,
      address: address,
      latitude: latitude,
      longitude: longitude,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt,
      timezone: timezone,
      phone: phone,
      bookingReference: bookingReference,
      notes: notes,
      luggageProfile: luggageProfile,
    );
    await refresh();
    return newStay;
  }

  Future<Stay> updateStay(
    String stayId, {
    String? name,
    String? stayType,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? timezone,
    String? phone,
    String? bookingReference,
    String? notes,
    LuggageProfile? luggageProfile,
  }) async {
    final updated = await _repository.updateStay(
      stayId,
      name: name,
      stayType: stayType,
      address: address,
      latitude: latitude,
      longitude: longitude,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt,
      timezone: timezone,
      phone: phone,
      bookingReference: bookingReference,
      notes: notes,
      luggageProfile: luggageProfile,
    );
    await refresh();
    return updated;
  }

  Future<void> deleteStay(String stayId) async {
    final previousStays = state.value ?? [];
    state = AsyncValue.data(
      previousStays.where((stay) => stay.id != stayId).toList(),
    );

    try {
      await _repository.deleteStay(stayId);
    } catch (_) {
      // Revert if network failed
      await refresh();
      rethrow;
    }
  }
}

/// Stays list provider parameterized by tripId.
final stayListProvider =
    AsyncNotifierProvider.family<StayListNotifier, List<Stay>, String>(
      (tripId) => StayListNotifier(tripId),
    );

class TransportQueryParams {
  const TransportQueryParams({
    required this.stayId,
    this.origin,
    this.preset,
    this.partySize,
    this.stroller,
  });

  final String stayId;
  final String? origin;
  final String? preset;
  final int? partySize;
  final bool? stroller;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransportQueryParams &&
          runtimeType == other.runtimeType &&
          stayId == other.stayId &&
          origin == other.origin &&
          preset == other.preset &&
          partySize == other.partySize &&
          stroller == other.stroller;

  @override
  int get hashCode =>
      stayId.hashCode ^
      origin.hashCode ^
      preset.hashCode ^
      partySize.hashCode ^
      stroller.hashCode;
}

/// Transport comparison provider parameterized by stayId and optional luggage/origin.
final transportComparisonProvider =
    FutureProvider.family<TransportComparisonResult, TransportQueryParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(stayRepositoryProvider);
      return repository.compareTransport(
        params.stayId,
        origin: params.origin,
        luggagePreset: params.preset,
        partySize: params.partySize,
        stroller: params.stroller,
      );
    });
