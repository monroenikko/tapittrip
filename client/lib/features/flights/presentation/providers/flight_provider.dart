import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../sync/domain/models/outbox_operation.dart';
import '../../../sync/presentation/providers/sync_provider.dart';
import '../../../sync/services/sync_service.dart';
import '../../data/flight_repository.dart';
import '../../domain/models/flight.dart';

final flightRepositoryProvider = Provider<FlightRepository>(
  (ref) => FlightRepository(apiClient: ref.watch(apiClientProvider)),
);

final flightListProvider =
    AsyncNotifierProvider.family<FlightListNotifier, List<Flight>, String>(
      FlightListNotifier.new,
    );

class FlightListNotifier extends AsyncNotifier<List<Flight>> {
  FlightListNotifier(this.tripId);
  final String tripId;
  late final FlightRepository _repository;

  @override
  Future<List<Flight>> build() async {
    _repository = ref.watch(flightRepositoryProvider);
    return _repository.fetch(tripId);
  }

  Future<void> refresh() async {
    final existing = state.asData?.value;
    try {
      state = AsyncData(await _repository.fetch(tripId));
    } catch (error, stack) {
      state = existing == null ? AsyncError(error, stack) : AsyncData(existing);
      rethrow;
    }
  }

  Future<Flight> save(Map<String, dynamic> payload, {Flight? existing}) async {
    final operationId = SyncService.generateUuid();
    final request = {
      ...payload,
      if (existing == null) 'client_operation_id': operationId,
    };
    try {
      final flight = existing == null
          ? await _repository.create(tripId, request)
          : await _repository.update(existing.id, {
              ...request,
              'base_version': existing.version,
            });
      final current = state.asData?.value ?? const <Flight>[];
      final updated = existing == null
          ? [flight, ...current]
          : [
              for (final item in current)
                if (item.id == flight.id) flight else item,
            ];
      state = AsyncData(updated);
      await _repository.cache(tripId, updated);
      return flight;
    } on NetworkException {
      final rawSegments = (request['segments'] as List? ?? const []);
      final optimistic = Flight(
        id: existing?.id ?? operationId,
        tripId: tripId,
        airline: request.containsKey('airline')
            ? request['airline'] as String?
            : existing?.airline,
        bookingReference: request.containsKey('booking_reference')
            ? request['booking_reference'] as String?
            : existing?.bookingReference,
        segments: rawSegments.isNotEmpty
            ? rawSegments
                  .map(
                    (s) => FlightSegment.fromJson(
                      Map<String, dynamic>.from(s as Map),
                    ),
                  )
                  .toList()
            : (existing?.segments ?? const <FlightSegment>[]),
        version: existing?.version ?? 1,
        updatedAt: DateTime.now().toUtc(),
      );
      final current = state.asData?.value ?? const <Flight>[];
      final updated = existing == null
          ? [optimistic, ...current]
          : [
              for (final item in current)
                if (item.id == optimistic.id) optimistic else item,
            ];
      state = AsyncData(updated);
      await _repository.cache(tripId, updated);
      await _queue(
        operationId,
        existing == null ? 'create' : 'update',
        optimistic.id,
        request,
        existing?.version ?? 1,
      );
      return optimistic;
    }
  }

  Future<Flight> add(Map<String, dynamic> payload) => save(payload);

  Future<void> remove(Flight flight) async {
    final old = state.asData?.value ?? const <Flight>[];
    final updated = old.where((item) => item.id != flight.id).toList();
    state = AsyncData(updated);
    try {
      await _repository.delete(flight.id);
      await _repository.cache(tripId, updated);
    } on NetworkException {
      await _repository.cache(tripId, updated);
      await _queue(
        SyncService.generateUuid(),
        'delete',
        flight.id,
        null,
        flight.version,
      );
    } catch (_) {
      state = AsyncData(old);
      rethrow;
    }
  }

  Future<void> _queue(
    String operationId,
    String type,
    String id,
    Map<String, dynamic>? payload, [
    int version = 1,
  ]) async {
    await SyncService.saveWithChainedVersion(
      ref.read(outboxStorageProvider),
      OutboxOperation(
        operationId: operationId,
        tripId: tripId,
        entityType: 'flight',
        entityId: id,
        operationType: type,
        payload: payload,
        baseVersion: version,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await ref.read(syncProvider.notifier).refresh();
  }
}
