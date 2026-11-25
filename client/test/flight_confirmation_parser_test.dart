import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/features/flights/data/flight_repository.dart';
import 'package:tapittrip/features/flights/domain/models/flight.dart';
import 'package:tapittrip/features/flights/domain/services/flight_confirmation_parser.dart';
import 'package:tapittrip/features/flights/presentation/providers/flight_provider.dart';
import 'package:tapittrip/features/flights/presentation/widgets/add_flight_sheet.dart';
import 'package:tapittrip/features/sync/data/outbox_storage.dart';
import 'package:tapittrip/features/sync/presentation/providers/sync_provider.dart';
import 'package:tapittrip/features/sync/services/sync_service.dart';

class _InMemorySecureStorage extends FlutterSecureStorage {
  _InMemorySecureStorage([Map<String, String>? seed])
    : _store = seed != null ? Map<String, String>.from(seed) : {};

  final Map<String, String> _store;

  String? rawValue(String key) => _store[key];

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.onGet, this.onPost, this.onPatch, this.onDelete})
    : super(
        tokenStorage: const SecureTokenStorage(),
        baseUrl: 'https://test.invalid/api/v1',
      );

  final Future<dynamic> Function(String path, Map<String, dynamic>? query)?
  onGet;
  final Future<dynamic> Function(String path, dynamic data)? onPost;
  final Future<dynamic> Function(String path, dynamic data)? onPatch;
  final Future<dynamic> Function(String path)? onDelete;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (onGet != null) return onGet!(path, queryParameters);
    throw const NetworkException('offline');
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (onPost != null) return onPost!(path, data);
    throw const NetworkException('offline');
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (onPatch != null) return onPatch!(path, data);
    throw const NetworkException('offline');
  }

  @override
  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (onDelete != null) return onDelete!(path);
    throw const NetworkException('offline');
  }
}

void main() {
  const parser = FlightConfirmationParser();

  test('extracts explicit reviewed booking fields from confirmation text', () {
    final details = parser.parse('''
      Airline: TapIt Air
      Booking reference: tt-9z12
      Flight TT 101
      MNL → NRT
    ''');

    expect(details.airline, 'TapIt Air');
    expect(details.bookingReference, 'TT-9Z12');
    expect(details.flightNumber, 'TT101');
    expect(details.originAirport, 'MNL');
    expect(details.destinationAirport, 'NRT');
  });

  test(
    'does not invent details when confirmation text has no recognized fields',
    () {
      final details = parser.parse('Thank you for travelling with us.');

      expect(details.hasContent, isFalse);
      expect(details.flightNumber, isNull);
    },
  );

  test('applies pulled flight sync create/update/delete operations and purges on 403', () async {
    final storage = _InMemorySecureStorage();
    var shouldForbid = false;
    final apiClient = _FakeApiClient(
      onGet: (path, query) async {
        if (path == '/sync/pull') {
          return {
            'data': {
              'cursor': 4,
              'has_more': false,
              'operations': [
                {
                  'id': 'op-1',
                  'operation_id': 'op-1',
                  'trip_id': 'trip-1',
                  'entity_type': 'flight',
                  'entity_id': 'flight-1',
                  'operation_type': 'create',
                  'base_version': 1,
                  'server_sequence': 1,
                  'payload': {
                    'airline': 'ANA',
                    'segments': [
                      {
                        'flight_number': 'NH820',
                        'origin_airport': 'MNL',
                        'destination_airport': 'NRT',
                        'scheduled_departure_utc': '2026-12-01T01:30:00Z',
                        'scheduled_arrival_utc': '2026-12-01T06:00:00Z',
                        'origin_timezone': 'Asia/Manila',
                        'destination_timezone': 'Asia/Tokyo',
                        'terminal': 'T3',
                      },
                    ],
                  },
                },
                {
                  'id': 'op-2',
                  'operation_id': 'op-2',
                  'trip_id': 'trip-1',
                  'entity_type': 'flight',
                  'entity_id': 'flight-2',
                  'operation_type': 'create',
                  'base_version': 1,
                  'server_sequence': 2,
                  'payload': {
                    'airline': 'PAL',
                    'segments': [
                      {
                        'flight_number': 'PR428',
                        'origin_airport': 'MNL',
                        'destination_airport': 'NRT',
                        'scheduled_departure_utc': '2026-12-02T01:30:00Z',
                        'scheduled_arrival_utc': '2026-12-02T06:00:00Z',
                        'origin_timezone': 'Asia/Manila',
                        'destination_timezone': 'Asia/Tokyo',
                      },
                    ],
                  },
                },
                {
                  'id': 'op-3',
                  'operation_id': 'op-3',
                  'trip_id': 'trip-1',
                  'entity_type': 'flight',
                  'entity_id': 'flight-1',
                  'operation_type': 'update',
                  'base_version': 1,
                  'server_sequence': 3,
                  'payload': {
                    'airline': 'All Nippon Airways',
                    'segments': [
                      {
                        'flight_number': 'NH820',
                        'origin_airport': 'MNL',
                        'destination_airport': 'HND',
                        'scheduled_departure_utc': '2026-12-01T01:30:00Z',
                        'scheduled_arrival_utc': '2026-12-01T06:00:00Z',
                        'origin_timezone': 'Asia/Manila',
                        'destination_timezone': 'Asia/Tokyo',
                        'terminal': 'T3',
                        'gate': '114',
                      },
                    ],
                  },
                },
                {
                  'id': 'op-4',
                  'operation_id': 'op-4',
                  'trip_id': 'trip-1',
                  'entity_type': 'flight',
                  'entity_id': 'flight-2',
                  'operation_type': 'delete',
                  'base_version': 1,
                  'server_sequence': 4,
                  'payload': null,
                },
              ],
            },
          };
        }
        if (shouldForbid) {
          throw const ApiException(
            code: 'forbidden',
            message: 'Forbidden',
            statusCode: 403,
          );
        }
        throw const NetworkException('offline');
      },
    );

    final repo = FlightRepository(apiClient: apiClient, storage: storage);
    final syncService = SyncService(
      apiClient: apiClient,
      outboxStorage: SecureOutboxStorage(storage),
      flightRepository: repo,
    );

    await syncService.pullLatest(tripId: 'trip-1');

    // Fetch while offline returns updated cache from pulled operations
    final cachedFlights = await repo.fetch('trip-1');
    expect(cachedFlights, hasLength(1));
    expect(cachedFlights.single.id, 'flight-1');
    expect(cachedFlights.single.airline, 'All Nippon Airways');
    expect(cachedFlights.single.version, 2);
    expect(cachedFlights.single.segments.single.destinationAirport, 'HND');
    expect(cachedFlights.single.segments.single.gate, '114');

    // 403 purges cached_flights_trip-1
    shouldForbid = true;
    await expectLater(repo.fetch('trip-1'), throwsA(isA<ApiException>()));
    expect(storage.rawValue('cached_flights_trip-1'), isNull);
  });

  testWidgets(
    'AddFlightSheet imports confirmation text and saves multi-leg flight',
    (tester) async {
      Map<String, dynamic>? postedPayload;
      final storage = _InMemorySecureStorage();
      final apiClient = _FakeApiClient(
        onGet: (path, query) async => {'data': <dynamic>[]},
        onPost: (path, data) async {
          postedPayload = Map<String, dynamic>.from(data as Map);
          return {
            'data': {
              'id': 'flight-created',
              'trip_id': 'trip-1',
              'airline': postedPayload!['airline'],
              'booking_reference': postedPayload!['booking_reference'],
              'version': 1,
              'segments': postedPayload!['segments'],
            },
          };
        },
      );

      final repo = FlightRepository(apiClient: apiClient, storage: storage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            flightRepositoryProvider.overrideWithValue(repo),
            outboxStorageProvider.overrideWithValue(
              SecureOutboxStorage(storage),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AddFlightSheet(tripId: 'trip-1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open confirmation paste dialog
      await tester.tap(find.text('Paste confirmation to fill details'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('flight_confirmation_input')),
        'Airline: ANA\nBooking reference: ab12cd\nFlight NH 820\nMNL → NRT',
      );
      await tester.tap(find.text('Review details'));
      await tester.pumpAndSettle();

      expect(find.text('ANA'), findsOneWidget);
      expect(find.text('AB12CD'), findsOneWidget);
      expect(find.text('NH820'), findsOneWidget);
      expect(find.text('MNL'), findsOneWidget);
      expect(find.text('NRT'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('segment_0_departure')),
        '2026-12-01T01:30:00Z',
      );
      await tester.enterText(
        find.byKey(const ValueKey('segment_0_arrival')),
        '2026-12-01T06:00:00Z',
      );
      await tester.enterText(
        find.byKey(const ValueKey('segment_0_destination_zone')),
        'Asia/Tokyo',
      );

      // Add connecting segment
      await tester.ensureVisible(find.text('Add connecting segment'));
      await tester.tap(find.text('Add connecting segment'));
      await tester.pumpAndSettle();

      // Segment 2 origin defaults to NRT and Asia/Tokyo
      await tester.enterText(
        find.byKey(const ValueKey('segment_1_flight_number')),
        'NH6',
      );
      await tester.enterText(
        find.byKey(const ValueKey('segment_1_destination')),
        'LAX',
      );
      await tester.enterText(
        find.byKey(const ValueKey('segment_1_departure')),
        '2026-12-01T08:00:00Z',
      );
      await tester.enterText(
        find.byKey(const ValueKey('segment_1_arrival')),
        '2026-12-01T18:00:00Z',
      );
      await tester.enterText(
        find.byKey(const ValueKey('segment_1_destination_zone')),
        'America/Los_Angeles',
      );

      await tester.ensureVisible(find.text('Save flight'));
      await tester.tap(find.text('Save flight'));
      await tester.pumpAndSettle();

      expect(postedPayload, isNotNull);
      expect(postedPayload!['airline'], 'ANA');
      expect(postedPayload!['booking_reference'], 'AB12CD');
      final segments = postedPayload!['segments'] as List<dynamic>;
      expect(segments, hasLength(2));
      expect((segments[0] as Map)['origin_airport'], 'MNL');
      expect((segments[0] as Map)['destination_airport'], 'NRT');
      expect((segments[1] as Map)['origin_airport'], 'NRT');
      expect((segments[1] as Map)['destination_airport'], 'LAX');
    },
  );

  testWidgets('AddFlightSheet edits and deletes existing multi-leg flight', (
    tester,
  ) async {
    Map<String, dynamic>? patchedPayload;
    String? deletedFlightId;
    final existingFlight = Flight(
      id: 'flight-existing',
      tripId: 'trip-1',
      airline: 'JAL',
      bookingReference: 'JL9999',
      version: 2,
      segments: [
        FlightSegment(
          id: 'seg-1',
          flightNumber: 'JL746',
          originAirport: 'MNL',
          destinationAirport: 'NRT',
          scheduledDepartureUtc: DateTime.parse('2026-12-05T02:00:00Z'),
          scheduledArrivalUtc: DateTime.parse('2026-12-05T06:30:00Z'),
          originTimezone: 'Asia/Manila',
          destinationTimezone: 'Asia/Tokyo',
        ),
      ],
    );

    final storage = _InMemorySecureStorage();
    final apiClient = _FakeApiClient(
      onGet: (path, query) async => {
        'data': [existingFlight.toJson()],
      },
      onPatch: (path, data) async {
        patchedPayload = Map<String, dynamic>.from(data as Map);
        return {
          'data': {
            ...existingFlight.toJson(),
            'airline': patchedPayload!['airline'],
            'version': 3,
            'segments': patchedPayload!['segments'],
          },
        };
      },
      onDelete: (path) async {
        deletedFlightId = path;
        return null;
      },
    );

    final repo = FlightRepository(apiClient: apiClient, storage: storage);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flightRepositoryProvider.overrideWithValue(repo),
          outboxStorageProvider.overrideWithValue(SecureOutboxStorage(storage)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AddFlightSheet(
              tripId: 'trip-1',
              existingFlight: existingFlight,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review or edit scheduled flight'), findsOneWidget);
    expect(find.text('Update flight'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('segment_0_gate')), '62');
    await tester.ensureVisible(find.text('Update flight'));
    await tester.tap(find.text('Update flight'));
    await tester.pumpAndSettle();

    expect(patchedPayload, isNotNull);
    expect(patchedPayload!['base_version'], 2);
    expect(((patchedPayload!['segments'] as List).single as Map)['gate'], '62');

    // Re-pump sheet to test delete button
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flightRepositoryProvider.overrideWithValue(repo),
          outboxStorageProvider.overrideWithValue(SecureOutboxStorage(storage)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AddFlightSheet(
              tripId: 'trip-1',
              existingFlight: existingFlight,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Delete flight'));
    await tester.tap(find.byTooltip('Delete flight'));
    await tester.pumpAndSettle();
    expect(deletedFlightId, '/flights/flight-existing');
  });
}
