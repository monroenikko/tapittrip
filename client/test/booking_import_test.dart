import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/imports/data/booking_import_repository.dart';
import 'package:tapittrip/features/imports/domain/models/booking_import.dart';
import 'package:tapittrip/features/imports/presentation/pages/trip_inbox_page.dart';
import 'package:tapittrip/features/imports/presentation/providers/booking_import_provider.dart';

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

  final sampleImportJson = {
    'id': 'import-uuid-1',
    'trip_id': 'trip-uuid-1',
    'user_id': 'user-uuid-1',
    'source': 'paste_text',
    'booking_type': 'flight',
    'raw_text': 'Philippine Airlines Flight PR 101',
    'extraction_status': 'extracted',
    'extracted_data': {
      'booking_type': 'flight',
      'confidence': 0.95,
      'summary': 'Philippine Airlines PR 101 (MNL → NRT)',
      'flight': {
        'airline': 'Philippine Airlines',
        'booking_reference': 'PR-123456',
        'segments': [
          {
            'flight_number': 'PR 101',
            'origin_airport': 'MNL',
            'destination_airport': 'NRT',
            'scheduled_departure_utc': '2027-04-10T08:00:00Z',
            'scheduled_arrival_utc': '2027-04-10T13:30:00Z',
            'origin_timezone': 'Asia/Manila',
            'destination_timezone': 'Asia/Tokyo',
          },
        ],
      },
    },
    'confidence_score': 0.95,
    'confirmed_entity_type': null,
    'confirmed_entity_id': null,
    'reviewed_at': null,
    'error_message': null,
    'version': 1,
    'created_at': '2026-11-20T01:00:00Z',
    'updated_at': '2026-11-20T01:00:00Z',
  };

  group('BookingImport Model', () {
    test('parses fromJson and handles getters', () {
      final model = BookingImport.fromJson(sampleImportJson);
      expect(model.id, 'import-uuid-1');
      expect(model.tripId, 'trip-uuid-1');
      expect(model.bookingType, 'flight');
      expect(model.isExtracted, isTrue);
      expect(model.isConfirmed, isFalse);
      expect(model.confidencePercentText, '95%');
      expect(model.typeLabel, 'Flight');
      expect(model.summary, 'Philippine Airlines PR 101 (MNL → NRT)');
      expect(model.extractedFlight, isNotNull);
      expect(model.extractedFlight!['airline'], 'Philippine Airlines');

      final json = model.toJson();
      expect(json['id'], 'import-uuid-1');
      expect(json['booking_type'], 'flight');
    });
  });

  group('BookingImportRepository', () {
    test(
      'caches imports in secure storage, falls back offline, and purges on 403',
      () async {
        FlutterSecureStorage.setMockInitialValues({});
        const storage = FlutterSecureStorage();
        var shouldFailWith403 = false;
        var shouldFailOffline = false;

        final repo = BookingImportRepository(
          storage: storage,
          apiClient: _FakeApiClient(
            onGet: (path, {queryParameters}) async {
              if (shouldFailWith403) {
                throw const ApiException(
                  code: 'forbidden',
                  message: 'Forbidden',
                  statusCode: 403,
                );
              }
              if (shouldFailOffline) {
                throw const ApiException(
                  code: 'network_error',
                  message: 'Offline',
                );
              }
              return {
                'data': [sampleImportJson],
              };
            },
          ),
        );

        // 1. Initial fetch from API and caches
        final initial = await repo.listImports('trip-uuid-1');
        expect(initial, hasLength(1));
        expect(initial.first.id, 'import-uuid-1');
        expect(
          await storage.read(key: 'cached_booking_imports_trip-uuid-1'),
          isNotNull,
        );

        // 2. Offline fallback
        shouldFailOffline = true;
        final cached = await repo.listImports('trip-uuid-1');
        expect(cached, hasLength(1));
        expect(cached.first.summary, contains('Philippine Airlines'));

        // 3. 403 revocation purge
        shouldFailOffline = false;
        shouldFailWith403 = true;
        await expectLater(
          repo.listImports('trip-uuid-1'),
          throwsA(isA<ApiException>()),
        );
        expect(
          await storage.read(key: 'cached_booking_imports_trip-uuid-1'),
          isNull,
        );
      },
    );
  });

  group('TripInboxPage Widget', () {
    testWidgets('renders empty state when there are no imports', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripBookingImportsProvider('trip-uuid-1')
                .overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TripInboxPage(tripId: 'trip-uuid-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your Trip Inbox is Empty'), findsOneWidget);
      expect(find.text('Paste Booking Text'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets(
      'renders pending imports with confidence chip and review action',
      (tester) async {
        final sample = BookingImport.fromJson(sampleImportJson);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tripBookingImportsProvider('trip-uuid-1')
                  .overrideWith((ref) async => [sample]),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TripInboxPage(tripId: 'trip-uuid-1'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Ready to Review (1)'), findsOneWidget);
        expect(
          find.text('Philippine Airlines PR 101 (MNL → NRT)'),
          findsOneWidget,
        );
        expect(find.text('95% confidence'), findsOneWidget);
        expect(find.text('Review & Add'), findsOneWidget);
      },
    );
  });
}
