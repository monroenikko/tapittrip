import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../sync/domain/models/outbox_operation.dart';
import '../../../sync/presentation/providers/sync_provider.dart';
import '../../../sync/services/sync_service.dart';
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
    final existing = state.asData?.value
        .where((s) => s.id == stayId)
        .firstOrNull;
    final baseVersion = existing?.version ?? 1;
    final payload = <String, dynamic>{
      'name': ?name,
      'stay_type': ?stayType,
      'address': ?address,
      if (checkInAt != null) 'check_in_at': checkInAt.toIso8601String(),
      if (checkOutAt != null) 'check_out_at': checkOutAt.toIso8601String(),
      'timezone': ?timezone,
      'notes': ?notes,
      if (luggageProfile != null) 'luggage_profile': luggageProfile.toJson(),
    };

    try {
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
        baseVersion: existing?.version,
      );
      await refresh();
      return updated;
    } on ConflictException catch (e) {
      await _recordOutboxOperation(
        OutboxOperation(
          operationId: SyncService.generateUuid(),
          tripId: tripId,
          entityType: 'stay',
          entityId: stayId,
          operationType: 'update',
          baseVersion: baseVersion,
          payload: payload,
          status: 'conflict',
          conflictDetails: e.details,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      await refresh();
      rethrow;
    } on NetworkException {
      if (existing != null) {
        final localStay = existing.copyWith(
          name: name,
          stayType: stayType,
          address: address,
          latitude: latitude,
          longitude: longitude,
          checkInAt: checkInAt,
          checkOutAt: checkOutAt,
          timezone: timezone,
          notes: notes,
          luggageProfile: luggageProfile,
        );
        final list = [
          for (final s in state.asData?.value ?? const <Stay>[])
            s.id == stayId ? localStay : s,
        ];
        state = AsyncValue.data(list);
        await _repository.cacheStays(tripId, list);
        await _recordOutboxOperation(
          OutboxOperation(
            operationId: SyncService.generateUuid(),
            tripId: tripId,
            entityType: 'stay',
            entityId: stayId,
            operationType: 'update',
            baseVersion: baseVersion,
            payload: payload,
            status: 'pending',
            createdAt: DateTime.now().toUtc(),
          ),
        );
        return localStay;
      }
      rethrow;
    }
  }

  Future<void> _recordOutboxOperation(OutboxOperation operation) async {
    try {
      await ref.read(outboxStorageProvider).saveOperation(operation);
      await ref.read(syncProvider.notifier).refresh();
    } catch (_) {}
  }

  Future<void> deleteStay(String stayId) async {
    final previousStays = state.value ?? [];
    final existing = previousStays.where((s) => s.id == stayId).firstOrNull;
    state = AsyncValue.data(
      previousStays.where((stay) => stay.id != stayId).toList(),
    );

    try {
      await _repository.deleteStay(stayId);
    } on NetworkException {
      final updated = state.value ?? const <Stay>[];
      await _repository.cacheStays(tripId, updated);
      await _recordOutboxOperation(
        OutboxOperation(
          operationId: SyncService.generateUuid(),
          tripId: tripId,
          entityType: 'stay',
          entityId: stayId,
          operationType: 'delete',
          baseVersion: existing?.version ?? 1,
          status: 'pending',
          createdAt: DateTime.now().toUtc(),
        ),
      );
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
