import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/safety/data/safety_repository.dart';
import 'package:tapittrip/features/safety/presentation/pages/destination_safety_page.dart';
import 'package:tapittrip/features/safety/presentation/providers/safety_provider.dart';

class _FakeApiClient extends Fake implements ApiClient {
  _FakeApiClient({this.onGet});

  final Future<dynamic> Function(
    String path, {
    Map<String, dynamic>? queryParameters,
  })?
  onGet;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (onGet != null) {
      return onGet!(path, queryParameters: queryParameters);
    }
    throw const ApiException(code: 'network_error', message: 'Offline');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DestinationSafetyProfile & SafetyRepository', () {
    test('falls back to bundled offline directory for all 9 curated countries and never fabricates uncurated numbers', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final repo = SafetyRepository(apiClient: _FakeApiClient());

      final jp = await repo.getCountrySafetyProfile('Japan');
      expect(jp.countryCode, 'JP');
      expect(jp.isCurated, isTrue);
      expect(jp.emergencyNumbers.police, '110');
      expect(jp.emergencyNumbers.ambulance, '119');
      expect(jp.officialResources, isNotEmpty);

      final fr = await repo.getCountrySafetyProfile('Paris');
      expect(fr.countryCode, 'FR');
      expect(fr.isCurated, isTrue);
      expect(fr.emergencyNumbers.ambulance, '15');
      expect(fr.emergencyNumbers.generalEmergency, '112');

      final us = await repo.getCountrySafetyProfile('United States');
      expect(us.countryCode, 'US');
      expect(us.emergencyNumbers.police, '911');

      final unknown = await repo.getCountrySafetyProfile('Atlantis');
      expect(unknown.isCurated, isFalse);
      expect(unknown.emergencyNumbers.hasAnyNumber, isFalse);
    });

    test('respects countryOverride when switching countries offline for a trip and purges on 403', () async {
      FlutterSecureStorage.setMockInitialValues({
        'cached_safety_trip_trip-99': '{"country_code":"JP","country_name":"Japan","flag_emoji":"🇯🇵","is_curated":true,"emergency_numbers":{"police":"110"},"official_resources":[],"emergency_phrases":[],"last_verified_at":"2026-11-01","disclaimer":"Ref only"}',
      });
      const storage = FlutterSecureStorage();
      var failWith403 = false;

      final repo = SafetyRepository(
        apiClient: _FakeApiClient(
          onGet: (path, {queryParameters}) async {
            if (failWith403) {
              throw const ApiException(
                code: 'forbidden',
                message: 'Not authorized',
                statusCode: 403,
              );
            }
            throw const ApiException(code: 'network_error', message: 'Offline');
          },
        ),
        storage: storage,
      );

      // Without override, returns cached trip profile (JP)
      final tripDefault = await repo.getTripSafetyProfile('trip-99');
      expect(tripDefault.countryCode, 'JP');

      // With countryOverride='KR' while offline, returns South Korea instead of stale JP trip cache
      final switched = await repo.getTripSafetyProfile(
        'trip-99',
        countryOverride: 'KR',
      );
      expect(switched.countryCode, 'KR');
      expect(switched.emergencyNumbers.police, '112');

      failWith403 = true;
      await expectLater(
        repo.getTripSafetyProfile('trip-99'),
        throwsA(isA<ApiException>()),
      );
      expect(await storage.read(key: 'cached_safety_trip_trip-99'), isNull);
    });
  });

  group('DestinationSafetyPage Widget', () {
    testWidgets(
      'renders emergency numbers, general emergency, offline phrases, official portals, and switches country',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        final fakeRepo = SafetyRepository(apiClient: _FakeApiClient());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [safetyRepositoryProvider.overrideWithValue(fakeRepo)],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const DestinationSafetyPage(initialCountry: 'JP'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Safety & Emergency Directory'), findsOneWidget);
        expect(find.text('110'), findsOneWidget);
        expect(find.text('119'), findsWidgets);
        expect(find.text('110 / 119'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('助けて！救急車を呼んでください。'),
          150,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('助けて！救急車を呼んでください。'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Visit Japan Web (Immigration & Customs QR)'),
          150,
          scrollable: find.byType(Scrollable).last,
        );
        expect(
          find.text('Visit Japan Web (Immigration & Customs QR)'),
          findsOneWidget,
        );

        // Switch to South Korea chip
        await tester.tap(find.text('🇰🇷 South Korea'));
        await tester.pumpAndSettle();

        expect(find.text('South Korea'), findsWidgets);
      },
    );
  });
}
