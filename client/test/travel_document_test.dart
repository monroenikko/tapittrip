import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/documents/data/travel_document_repository.dart';
import 'package:tapittrip/features/documents/presentation/pages/trip_documents_vault_page.dart';
import 'package:tapittrip/features/documents/presentation/providers/travel_document_provider.dart';

class _FakeApiClient extends Fake implements ApiClient {
  _FakeApiClient({this.onGet, this.onPost});

  final Future<dynamic> Function(
    String path, {
    Map<String, dynamic>? queryParameters,
  })?
  onGet;

  final Future<dynamic> Function(String path, {dynamic data})? onPost;

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

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (onPost != null) {
      return onPost!(path, data: data);
    }
    throw const ApiException(code: 'network_error', message: 'Offline');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TravelDocumentRepository', () {
    test('caches documents in secure storage, falls back offline, and purges on 403', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      var shouldFailWith403 = false;
      var shouldFailOffline = false;

      final repo = TravelDocumentRepository(
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
              'data': [
                {
                  'id': 'doc-1',
                  'trip_id': 'trip-99',
                  'owner_id': 'user-1',
                  'is_owner': true,
                  'document_type': 'travel_insurance',
                  'display_name': 'Tokyo Travel Insurance',
                  'issuer': 'Allianz',
                  'reference_number': 'POL-998877',
                  'expires_on': '2027-06-15',
                  'access_policy': 'circle_members',
                  'notes_private': 'Emergency hotline +81 3 1234 5678',
                  'version': 1,
                },
              ],
            };
          },
        ),
        storage: storage,
      );

      final docs = await repo.listDocuments('trip-99');
      expect(docs.length, 1);
      expect(docs.first.displayName, 'Tokyo Travel Insurance');
      expect(docs.first.referenceNumber, 'POL-998877');
      expect(await storage.read(key: 'cached_documents_trip-99'), isNotNull);

      shouldFailOffline = true;
      final cachedDocs = await repo.listDocuments('trip-99');
      expect(cachedDocs.length, 1);
      expect(cachedDocs.first.displayName, 'Tokyo Travel Insurance');

      shouldFailWith403 = true;
      await expectLater(
        repo.listDocuments('trip-99'),
        throwsA(isA<ApiException>()),
      );
      expect(await storage.read(key: 'cached_documents_trip-99'), isNull);
    });
  });

  group('TripDocumentsVaultPage Widget', () {
    testWidgets(
      'renders private and circle-shared documents and adds a new document',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        final items = <Map<String, dynamic>>[
          {
            'id': 'doc-1',
            'trip_id': 'trip-99',
            'owner_id': 'user-1',
            'is_owner': true,
            'document_type': 'visa_reference',
            'display_name': 'Japan eVisa Approval',
            'issuer': 'MOFA Japan',
            'reference_number': 'JP-VISA-4455',
            'expires_on': '2028-10-01',
            'access_policy': 'owner_only',
            'notes_private': 'Keep screenshot ready at immigration',
            'version': 1,
          },
        ];

        final repo = TravelDocumentRepository(
          apiClient: _FakeApiClient(
            onGet: (path, {queryParameters}) async => {'data': items},
            onPost: (path, {data}) async {
              final map = Map<String, dynamic>.from(data as Map);
              final created = {
                'id': 'doc-2',
                'trip_id': 'trip-99',
                'owner_id': 'user-1',
                'is_owner': true,
                'document_type': map['document_type'],
                'display_name': map['display_name'],
                'issuer': map['issuer'],
                'reference_number': map['reference_number'],
                'expires_on': map['expires_on'],
                'access_policy': map['access_policy'],
                'notes_private': map['notes_private'],
                'version': 1,
              };
              items.add(created);
              return {'data': created};
            },
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              travelDocumentRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TripDocumentsVaultPage(tripId: 'trip-99'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Travel Documents Vault'), findsOneWidget);
        expect(find.text('Japan eVisa Approval'), findsOneWidget);
        expect(find.text('Private (Only You)'), findsOneWidget);
        expect(find.text('Ref: JP-VISA-4455'), findsOneWidget);

        await tester.tap(find.text('Add Document'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Document Title *'),
          'JR Pass Exchange Order',
        );
        await tester.ensureVisible(
          find.text('Share summary with Trip Circle members'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Share summary with Trip Circle members'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Save Document'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Document'));
        await tester.pumpAndSettle();

        expect(find.text('JR Pass Exchange Order'), findsOneWidget);
        expect(find.text('Shared with Circle'), findsOneWidget);
      },
    );
  });
}
