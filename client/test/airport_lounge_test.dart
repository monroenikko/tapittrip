import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/features/lounges/data/lounge_repository.dart';
import 'package:tapittrip/features/lounges/domain/models/airport.dart';
import 'package:tapittrip/features/lounges/domain/models/airport_lounge.dart';
import 'package:tapittrip/features/lounges/domain/models/airport_terminal.dart';
import 'package:tapittrip/features/lounges/presentation/pages/airport_lounge_finder_page.dart';
import 'package:tapittrip/features/lounges/presentation/providers/lounge_provider.dart';
import 'package:tapittrip/features/lounges/presentation/widgets/lounge_card.dart';

class FakeLoungeApiClient extends ApiClient {
  FakeLoungeApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic getResponse;
  bool shouldThrow = false;
  Map<String, dynamic>? lastQueryParams;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastQueryParams = queryParameters;
    if (shouldThrow) {
      throw const NetworkException();
    }
    return getResponse ??
        {
          'data': {
            'airport': {
              'id': 'airport-mnl',
              'iata_code': 'MNL',
              'name': 'Ninoy Aquino International Airport',
              'city': 'Manila',
              'country': 'Philippines',
              'timezone': 'Asia/Manila',
              'terminals': [
                {
                  'id': 't-3',
                  'airport_id': 'airport-mnl',
                  'name': 'Terminal 3',
                  'code': 'T3',
                },
                {
                  'id': 't-1',
                  'airport_id': 'airport-mnl',
                  'name': 'Terminal 1',
                  'code': 'T1',
                },
              ],
            },
            'lounges': [
              {
                'id': 'lounge-1',
                'airport_id': 'airport-mnl',
                'terminal_id': 't-3',
                'name': 'PAGSS Premium Lounge',
                'operator': 'PAGSS',
                'location_description': 'Level 4, near Gate 115',
                'is_airside': true,
                'opening_hours': {
                  'open': '05:00',
                  'close': '00:00',
                  'is_24h': false,
                },
                'amenities': ['buffet', 'bar', 'showers', 'wifi'],
                'access_methods': [
                  'priority_pass',
                  'lounge_key',
                  'business_class',
                ],
                'estimated_price': {'amount_cents': 2800, 'currency': 'PHP'},
                'booking_url': 'https://example.com/booking',
                'transit_warning': 'Terminal 3 passengers only.',
                'terminal': {
                  'id': 't-3',
                  'airport_id': 'airport-mnl',
                  'name': 'Terminal 3',
                  'code': 'T3',
                },
              },
              {
                'id': 'lounge-2',
                'airport_id': 'airport-mnl',
                'terminal_id': 't-1',
                'name': 'Club Manila Lounge',
                'operator': 'Club Manila',
                'location_description': 'Gate 7, East Concourse',
                'is_airside': true,
                'amenities': ['wifi', 'drinks'],
                'access_methods': ['priority_pass'],
                'terminal': {
                  'id': 't-1',
                  'airport_id': 'airport-mnl',
                  'name': 'Terminal 1',
                  'code': 'T1',
                },
              },
            ],
          },
        };
  }
}

void main() {
  group('Airport & Lounge Models', () {
    test('Airport & Terminal deserialize correctly', () {
      final json = {
        'id': 'apt-1',
        'iata_code': 'SIN',
        'name': 'Singapore Changi Airport',
        'city': 'Singapore',
        'country': 'Singapore',
        'timezone': 'Asia/Singapore',
        'terminals': [
          {
            'id': 'term-3',
            'airport_id': 'apt-1',
            'name': 'Terminal 3',
            'code': 'T3',
          },
        ],
      };

      final airport = Airport.fromJson(json);
      expect(airport.iataCode, 'SIN');
      expect(airport.terminals.length, 1);
      expect(airport.terminals.first.code, 'T3');
    });

    test(
      'AirportLounge deserializes amenities, access methods, and pricing',
      () {
        final json = {
          'id': 'lg-1',
          'airport_id': 'apt-1',
          'terminal_id': 'term-3',
          'name': 'SilverKris Lounge',
          'operator': 'Singapore Airlines',
          'location_description': 'Level 3, Mezzanine',
          'is_airside': true,
          'amenities': ['buffet', 'showers', 'wifi'],
          'access_methods': ['business_class', 'star_alliance_gold'],
          'estimated_price': {'amount_cents': 4500, 'currency': 'SGD'},
          'transit_warning': 'Airside access required.',
        };

        final lounge = AirportLounge.fromJson(json);
        expect(lounge.name, 'SilverKris Lounge');
        expect(lounge.isAirside, true);
        expect(lounge.amenities.contains('showers'), true);
        expect(lounge.accessMethods.contains('star_alliance_gold'), true);
        expect(lounge.transitWarning, 'Airside access required.');
      },
    );
  });

  group('LoungeRepository', () {
    setUp(() {
      LoungeRepository.clearMemoryCache();
    });

    test('searchLounges fetches and caches to local secure storage', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      final client = FakeLoungeApiClient();
      final repo = LoungeRepository(apiClient: client, storage: storage);

      final result = await repo.searchLounges('MNL');
      expect(result.airport.iataCode, 'MNL');
      expect(result.lounges.length, 2);
      expect(result.isFromCache, false);

      final cachedRaw = await storage.read(key: 'cached_lounges_MNL');
      expect(cachedRaw, isNotNull);
      final cachedJson = jsonDecode(cachedRaw!);
      expect(cachedJson['airport']['iata_code'], 'MNL');
    });

    test(
      'searchLounges falls back to offline cache on network error',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'cached_lounges_MNL': jsonEncode({
            'airport': {
              'id': 'cached-apt',
              'iata_code': 'MNL',
              'name': 'Cached Manila Airport',
              'city': 'Manila',
              'country': 'Philippines',
              'timezone': 'Asia/Manila',
              'terminals': [
                {
                  'id': 't-3',
                  'airport_id': 'cached-apt',
                  'name': 'Terminal 3',
                  'code': 'T3',
                },
              ],
            },
            'lounges': [
              {
                'id': 'cached-lg-1',
                'airport_id': 'cached-apt',
                'terminal_id': 't-3',
                'name': 'Offline Cached Lounge',
                'operator': 'Local Ops',
                'location_description': 'Level 4',
                'is_airside': true,
                'amenities': ['wifi'],
                'access_methods': ['priority_pass'],
                'terminal': {
                  'id': 't-3',
                  'airport_id': 'cached-apt',
                  'name': 'Terminal 3',
                  'code': 'T3',
                },
              },
            ],
          }),
        });

        const storage = FlutterSecureStorage();
        final client = FakeLoungeApiClient()..shouldThrow = true;
        final repo = LoungeRepository(apiClient: client, storage: storage);

        final result = await repo.searchLounges('MNL');
        expect(result.isFromCache, true);
        expect(result.airport.name, 'Cached Manila Airport');
        expect(result.lounges.first.name, 'Offline Cached Lounge');
      },
    );

    test('searchLounges returns immediately from memory cache on repeat lookup', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      final client = FakeLoungeApiClient();
      final repo = LoungeRepository(apiClient: client, storage: storage);

      // First call hits network
      final first = await repo.searchLounges('MNL');
      expect(first.isFromCache, false);

      // Second call returns from memory cache instantly
      final second = await repo.searchLounges('MNL');
      expect(second.isFromCache, true);
      expect(second.airport.iataCode, 'MNL');
    });

    test('prefetchAirports pulls and caches multiple airports in parallel', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      final client = FakeLoungeApiClient();
      final repo = LoungeRepository(apiClient: client, storage: storage);

      await repo.prefetchAirports(['MNL', 'HND']);

      // Subsequent searches for prefetched airports are instant cache hits
      final mnl = await repo.searchLounges('MNL');
      expect(mnl.isFromCache, true);
    });

    test('detectAirportsForTrip resolves relevant hub IATA codes', () {
      final japanCodes = LoungeRepository.detectAirportsForTrip(
        null,
        additionalTexts: ['Tokyo Haneda Airport (HND)', 'Shinjuku Stay'],
      );
      expect(japanCodes.contains('HND'), true);
      expect(japanCodes.contains('MNL'), true);
    });

    test('getGlobalAirports fetches and caches global airports list', () async {
      final client = FakeLoungeApiClient();
      client.getResponse = {
        'data': [
          {
            'iata_code': 'LHR',
            'name': 'London Heathrow Airport',
            'city': 'London',
            'country': 'United Kingdom',
            'timezone': 'Europe/London',
            'terminals': [
              {'code': 'T2', 'name': 'Terminal 2'},
              {'code': 'T5', 'name': 'Terminal 5'},
            ],
          },
        ],
      };
      final repo = LoungeRepository(apiClient: client);

      final airports = await repo.getGlobalAirports(query: 'London');
      expect(airports.length, 1);
      expect(airports.first.iataCode, 'LHR');
      expect(airports.first.terminals.length, 2);
    });
  });

  group('Presentation Widgets', () {
    testWidgets(
      'LoungeCard renders name, terminal, operator and opens detail sheet',
      (tester) async {
        final lounge = AirportLounge(
          id: 'card-lounge-1',
          airportId: 'mnl',
          terminalId: 't3',
          name: 'Marhaba Lounge T3',
          operatorName: 'dnata',
          locationDescription: 'Near Gate 116, Level 4',
          isAirside: true,
          amenities: ['buffet', 'showers', 'wifi'],
          accessMethods: ['priority_pass', 'dragon_pass'],
          terminal: const AirportTerminal(
            id: 't3',
            airportId: 'mnl',
            name: 'Terminal 3',
            code: 'T3',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: LoungeCard(lounge: lounge)),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Marhaba Lounge T3'), findsOneWidget);
        expect(find.text('dnata'), findsOneWidget);
        expect(find.text('T3'), findsOneWidget);
        expect(find.text('Priority Pass'), findsOneWidget);

        // Tap card to open detail sheet
        await tester.tap(find.byType(LoungeCard));
        await tester.pumpAndSettle();

        expect(find.text('Location & Directions'), findsOneWidget);
        expect(find.text('Lounge Amenities'), findsOneWidget);
        expect(find.text('Access Programs & Eligibility'), findsOneWidget);
        expect(find.text('Near Gate 116, Level 4'), findsOneWidget);
        expect(find.textContaining('Boarding Reminder'), findsOneWidget);
      },
    );

    testWidgets(
      'AirportLoungeFinderPage renders search, terminal filter chips and lounges',
      (tester) async {
        final fakeClient = FakeLoungeApiClient();
        FlutterSecureStorage.setMockInitialValues({});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              loungeRepositoryProvider.overrideWithValue(
                LoungeRepository(apiClient: fakeClient),
              ),
            ],
            child: const MaterialApp(
              home: AirportLoungeFinderPage(initialIata: 'MNL'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify app bar and search
        expect(find.text('Airport Lounges'), findsOneWidget);
        expect(find.text('PAGSS Premium Lounge'), findsOneWidget);
        expect(find.text('Club Manila Lounge'), findsOneWidget);

        // Verify terminal filter chips
        expect(find.text('All Terminals'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'T3'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'T1'), findsOneWidget);
      },
    );
  });
}
