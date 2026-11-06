import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/itinerary/domain/models/itinerary_item.dart';
import 'package:tapittrip/features/itinerary/presentation/pages/trip_itinerary_page.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/stays/data/stay_repository.dart';
import 'package:tapittrip/features/stays/domain/models/luggage_profile.dart';
import 'package:tapittrip/features/stays/domain/models/stay.dart';
import 'package:tapittrip/features/stays/domain/models/transport_option.dart';
import 'package:tapittrip/features/stays/domain/services/booking_confirmation_parser.dart';
import 'package:tapittrip/features/stays/presentation/providers/stay_provider.dart';
import 'package:tapittrip/features/stays/presentation/widgets/luggage_preset_selector.dart';
import 'package:tapittrip/features/stays/presentation/widgets/stay_card.dart';
import 'package:tapittrip/features/stays/presentation/widgets/transport_comparison_sheet.dart';
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(tokenStorage: InMemoryTokenStorage());

  dynamic getResponse;
  dynamic postResponse;
  bool shouldThrow = false;
  ApiException? exceptionToThrow;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const NetworkException();
    }
    return getResponse;
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const NetworkException();
    }
    return postResponse;
  }
}

class FakeSecureStorage extends FlutterSecureStorage {
  FakeSecureStorage([Map<String, String>? initial])
    : _data = initial != null ? Map.from(initial) : {};

  final Map<String, String> _data;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];

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
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }
}

final sampleStay = Stay(
  id: 'stay-1',
  tripId: 'trip-1',
  name: 'Hotel Kayon Resort Ubud',
  stayType: 'hotel',
  address: 'Banjar Bresela, Payangan, Ubud, Bali',
  latitude: -8.4552,
  longitude: 115.2678,
  checkInAt: DateTime.parse('2026-05-12T15:00:00Z'),
  checkOutAt: DateTime.parse('2026-05-18T11:00:00Z'),
  timezone: 'Asia/Makassar',
  phone: '+62 361 479 2553',
  bookingReference: 'KAYON-9921',
  luggageProfile: LuggageProfile.fromPreset('heavy'),
  googleMapsUrl: 'https://maps.google.com/?q=-8.4552,115.2678',
  googleMapsDirectionsUrl:
      'https://www.google.com/maps/dir/?api=1&destination=-8.4552,115.2678',
);

final sampleTransportOptions = [
  const TransportOption(
    id: 'opt-1',
    mode: 'private_transfer',
    title: 'Airport Taxi / Private Transfer',
    provider: 'DPS Airport Taxi Dispatch',
    estimatedDurationMinutes: 65,
    estimatedCostMinor: 3500,
    currency: 'USD',
    transfers: 0,
    walkingMeters: 50,
    luggageCapacity: 'Up to 3 large suitcases + stroller',
    accessibilityNotes: 'Step-free trunk loading',
    convenienceScore: 95,
    isMostConvenient: true,
    isFastest: true,
    isCheapest: false,
    explanation: 'Door-to-door direct ride; ideal for heavy luggage.',
  ),
  const TransportOption(
    id: 'opt-2',
    mode: 'public_transit',
    title: 'Public Airport Shuttle Bus',
    provider: 'Trans Sarbagita',
    estimatedDurationMinutes: 110,
    estimatedCostMinor: 800,
    currency: 'USD',
    transfers: 1,
    walkingMeters: 450,
    luggageCapacity: 'Limited rack space for 1 suitcase',
    accessibilityNotes: 'Stairs at transfer stop',
    convenienceScore: 40,
    isMostConvenient: false,
    isFastest: false,
    isCheapest: true,
    explanation: 'Budget option but requires transfer with stairs.',
  ),
];

final sampleComparisonResult = TransportComparisonResult(
  verified: true,
  status: 'verified',
  message: 'Found 2 transport options',
  origin: 'Ngurah Rai International Airport (DPS)',
  destination: 'Hotel Kayon Resort Ubud',
  googleMapsDirectionsUrl:
      'https://www.google.com/maps/dir/?api=1&destination=-8.4552,115.2678',
  luggagePreset: 'heavy',
  partySize: 2,
  options: sampleTransportOptions,
  providerAttribution: 'TapItTrip Transit Adapter (static test feed)',
  lastRefreshedAt: DateTime.parse('2026-11-06T10:00:00Z'),
);

const sampleTripForStay = Trip(
  id: 'trip-1',
  ownerId: 'user-1',
  title: 'Bali Getaway',
  startDate: '2026-05-12',
  endDate: '2026-05-18',
  destinationCountry: 'ID',
  tripType: 'leisure',
  planningMode: PlanningMode.existing,
);

void main() {
  group('Stay & Luggage Models', () {
    test('LuggageProfile presets configure correct baggage counts', () {
      final empty = LuggageProfile.empty();
      expect(empty.backpacks, 0);
      expect(empty.carryOns, 0);
      expect(empty.checkedBags, 0);
      expect(empty.stroller, isFalse);
      expect(empty.selectedCategories, isEmpty);

      final light = LuggageProfile.fromPreset('light');
      expect(light.preset, 'light');
      expect(light.backpacks, 1);
      expect(light.carryOns, 0);
      expect(light.stroller, false);

      final standard = LuggageProfile.fromPreset('standard');
      expect(standard.preset, 'standard');
      expect(standard.carryOns, 1);
      expect(standard.checkedBags, 1);

      final heavy = LuggageProfile.fromPreset('heavy');
      expect(heavy.preset, 'heavy');
      expect(heavy.checkedBags, 3);
      expect(heavy.stroller, true);
    });

    test('Stay serializes and deserializes properly', () {
      final json = sampleStay.toJson();
      final fromJson = Stay.fromJson(json);

      expect(fromJson.id, 'stay-1');
      expect(fromJson.name, 'Hotel Kayon Resort Ubud');
      expect(fromJson.stayTypeTitle, 'Hotel');
      expect(fromJson.durationNights, 6);
      expect(fromJson.stayDurationSummary, '6 Nights');
      expect(fromJson.bookingReference, 'KAYON-9921');
      expect(fromJson.luggageProfile?.stroller, true);
    });

    test('TransportOption cost and duration formatting', () {
      final option = sampleTransportOptions[0];
      expect(option.formattedCost, '\$35');
      expect(option.formattedDuration, '1 hr 5 min');
      expect(option.isMostConvenient, isTrue);

      final bus = sampleTransportOptions[1];
      expect(bus.formattedCost, '\$8');
      expect(bus.isCheapest, isTrue);
    });

    test('BookingConfirmationParser extracts hotel, dates, and reference', () {
      const emailText = '''
Booking Confirmation #KAYON-9921
Property: Hotel Kayon Resort Ubud
Address: Banjar Bresela, Payangan, Ubud, Bali
Check-in: May 12, 2026
Check-out: May 18, 2026
Phone: +62 361 479 2553
''';
      const parser = BookingConfirmationParser();
      final extracted = parser.parse(emailText);

      expect(extracted.hasContent, isTrue);
      expect(extracted.name, 'Hotel Kayon Resort Ubud');
      expect(extracted.bookingReference, 'KAYON-9921');
      expect(extracted.address, 'Banjar Bresela, Payangan, Ubud, Bali');
      expect(extracted.phone, '+62 361 479 2553');
      expect(extracted.checkInAt?.month, 5);
      expect(extracted.checkInAt?.day, 12);
      expect(extracted.checkOutAt?.month, 5);
      expect(extracted.checkOutAt?.day, 18);
    });
  });

  group('StayRepository', () {
    late FakeApiClient fakeApiClient;
    late FakeSecureStorage fakeStorage;
    late StayRepository repository;

    setUp(() {
      fakeApiClient = FakeApiClient();
      fakeStorage = FakeSecureStorage();
      repository = StayRepository(
        apiClient: fakeApiClient,
        storage: fakeStorage,
      );
    });

    test('fetchStays caches list to secure storage', () async {
      fakeApiClient.getResponse = [sampleStay.toJson()];

      final stays = await repository.fetchStays('trip-1');
      expect(stays.length, 1);
      expect(stays.first.name, 'Hotel Kayon Resort Ubud');

      final cached = await fakeStorage.read(key: 'cached_stays_trip-1');
      expect(cached, isNotNull);
      expect(cached, contains('Hotel Kayon Resort Ubud'));
    });

    test('fetchStays falls back to offline cache on network error', () async {
      fakeApiClient.shouldThrow = true;
      fakeApiClient.exceptionToThrow = const NetworkException();
      await fakeStorage.write(
        key: 'cached_stays_trip-1',
        value: jsonEncode([sampleStay.toJson()]),
      );

      final stays = await repository.fetchStays('trip-1');
      expect(stays.length, 1);
      expect(stays.first.id, 'stay-1');
      expect(stays.first.bookingReference, 'KAYON-9921');
    });

    test('compareTransport queries options endpoint', () async {
      fakeApiClient.postResponse = sampleComparisonResult.toJson();

      final result = await repository.compareTransport(
        'stay-1',
        luggagePreset: 'heavy',
      );
      expect(result.verified, isTrue);
      expect(result.options.length, 2);
      expect(result.options.first.isMostConvenient, isTrue);
    });
  });

  group('Stay Widgets', () {
    testWidgets('LuggagePresetSelector multi-select and others input', (
      tester,
    ) async {
      LuggageProfile profile = LuggageProfile.fromPreset('standard');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LuggagePresetSelector(
                  profile: profile,
                  onProfileChanged: (newProfile) {
                    setState(() => profile = newProfile);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Backpack / Daypack'), findsOneWidget);
      expect(find.text('Carry-on Suitcase'), findsOneWidget);
      expect(find.text('Checked Bag'), findsOneWidget);
      expect(find.text('Stroller / Baby Gear'), findsOneWidget);
      expect(find.text('Others'), findsOneWidget);

      // Tap Stroller to add it to multi-selection
      await tester.tap(find.text('Stroller / Baby Gear'));
      await tester.pumpAndSettle();

      expect(profile.stroller, isTrue);
      expect(profile.preset, 'heavy');

      // Tap Others to reveal custom input
      await tester.tap(find.text('Others'));
      await tester.pumpAndSettle();

      expect(find.text('Specify Other Luggage'), findsOneWidget);
    });

    testWidgets('StayCard renders stay details and action buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: StayCard(stay: sampleStay)),
        ),
      );

      expect(find.text('Hotel Kayon Resort Ubud'), findsOneWidget);
      expect(find.text('Hotel'), findsOneWidget);
      expect(find.textContaining('Banjar Bresela'), findsOneWidget);
      expect(find.text('Booking Ref: KAYON-9921'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
      expect(find.text('Arrival Transport'), findsOneWidget);
    });

    testWidgets(
      'TransportComparisonSheet renders ranked options and attribution',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              transportComparisonProvider(
                const TransportQueryParams(stayId: 'stay-1', preset: 'heavy'),
              ).overrideWith((ref) => Future.value(sampleComparisonResult)),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () =>
                        TransportComparisonSheet.show(context, sampleStay),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Arrival Transport'), findsOneWidget);
        expect(find.text('Airport Taxi / Private Transfer'), findsOneWidget);
        expect(find.text('Most Convenient'), findsOneWidget);
        expect(find.text('Fastest'), findsOneWidget);
        expect(find.text('Best Value'), findsOneWidget);
        expect(
          find.textContaining('TapItTrip Transit Adapter'),
          findsOneWidget,
        );
      },
    );

    testWidgets('TransportComparisonSheet renders fallback when unverified', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final unverifiedResult = TransportComparisonResult(
        verified: false,
        status: 'unverified',
        message: 'No fixed transit presets for this location. We do not fabricate schedules or fares.',
        origin: null,
        destination: 'Hotel Kayon Resort Ubud',
        googleMapsDirectionsUrl: 'https://www.google.com/maps/dir/?api=1&destination=-8.4552,115.2678',
        luggagePreset: 'standard',
        options: const [],
        providerAttribution: 'None',
        lastRefreshedAt: DateTime.parse('2026-11-06T10:00:00Z'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transportComparisonProvider(
              const TransportQueryParams(stayId: 'stay-1', preset: 'standard'),
            ).overrideWith((ref) => Future.value(unverifiedResult)),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => TransportComparisonSheet.show(
                    context,
                    sampleStay.copyWith(
                      luggageProfile: LuggageProfile.fromPreset('standard'),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Direct Route Navigation'), findsOneWidget);
      expect(
        find.textContaining('We do not fabricate schedules or fares'),
        findsOneWidget,
      );
      expect(find.text('Get Live Directions'), findsOneWidget);
    });
  });

  group('TripItineraryPage Stay Tab Integration', () {
    testWidgets('switching to Stay tab renders StayCard and Add button', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itineraryListProvider('trip-1')
                .overrideWith(() => _FakeItineraryNotifier('trip-1')),
            stayListProvider('trip-1')
                .overrideWith(() => _FakeStayNotifier('trip-1')),
            tripDaysProvider('trip-1').overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TripItineraryPage(
              tripId: 'trip-1',
              initialTrip: sampleTripForStay,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check initial Itinerary tab
      expect(find.text('Your Itinerary'), findsOneWidget);
      expect(find.text('Stay'), findsOneWidget);

      // Tap "Stay" tab
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();

      // Should render the StayCard
      expect(find.text('Hotel Kayon Resort Ubud'), findsOneWidget);
      expect(find.text('Booking Ref: KAYON-9921'), findsOneWidget);
      expect(find.text('Add Accommodation'), findsOneWidget);
    });
  });
}

class _FakeItineraryNotifier extends ItineraryListNotifier {
  _FakeItineraryNotifier(super.tripId);

  @override
  Future<List<ItineraryItem>> build() async {
    return [];
  }
}

class _FakeStayNotifier extends StayListNotifier {
  _FakeStayNotifier(super.tripId);

  @override
  Future<List<Stay>> build() async {
    return [sampleStay];
  }
}
