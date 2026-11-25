import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/translation/data/translation_repository.dart';
import 'package:tapittrip/features/translation/presentation/pages/translator_phrasebook_page.dart';
import 'package:tapittrip/features/translation/presentation/providers/translation_provider.dart';

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

  group('TranslationRepository', () {
    test('matches offline phrasebook without cloud consent and requires cloud consent for custom phrases', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final repo = TranslationRepository(
        apiClient: _FakeApiClient(
          onPost: (path, {data}) async => {
            'source_text': 'No peanuts please',
            'translated_text': 'ピーナッツは入れないでください。',
            'phonetic': 'Piinattsu wa irenaide kudasai.',
            'source_language': 'en',
            'target_language': 'ja',
            'provider': 'deterministic_test_adapter',
            'is_offline_match': false,
            'disclaimer': TranslationRepository.defaultDisclaimer,
          },
        ),
      );

      final offlineMatch = await repo.translateText(
        text: 'I have a food allergy',
        targetLanguage: 'Japan',
        consentCloud: false,
      );
      expect(offlineMatch.isOfflineMatch, isTrue);
      expect(offlineMatch.translatedText, '食物アレルギーがあります。');

      await expectLater(
        repo.translateText(
          text: 'No peanuts please',
          targetLanguage: 'ja',
          consentCloud: false,
        ),
        throwsA(isA<ApiException>()),
      );

      final cloudResult = await repo.translateText(
        text: 'No peanuts please',
        targetLanguage: 'ja',
        consentCloud: true,
      );
      expect(cloudResult.isOfflineMatch, isFalse);
      expect(cloudResult.translatedText, 'ピーナッツは入れないでください。');
    });

    test(
      'purges cached trip phrasebook when 403 forbidden is returned',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'cached_phrasebook_trip_trip-77': '{"language_code":"ja","language_name":"Japanese","native_name":"日本語","flag_emoji":"🇯🇵","country_code":"JP","categories":[],"phrases":[],"disclaimer":"Ref"}',
        });
        const storage = FlutterSecureStorage();
        final repo = TranslationRepository(
          apiClient: _FakeApiClient(
            onGet: (path, {queryParameters}) async {
              throw const ApiException(
                code: 'forbidden',
                message: 'Forbidden',
                statusCode: 403,
              );
            },
          ),
          storage: storage,
        );

        await expectLater(
          repo.getTripPhrasebook('trip-77'),
          throwsA(isA<ApiException>()),
        );
        expect(
          await storage.read(key: 'cached_phrasebook_trip_trip-77'),
          isNull,
        );
      },
    );
  });

  group('TranslatorPhrasebookPage Widget', () {
    testWidgets(
      'renders offline phrasebook, translates offline match, and switches language',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        final fakeRepo = TranslationRepository(apiClient: _FakeApiClient());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              translationRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TranslatorPhrasebookPage(
                initialLanguageOrCountry: 'Japan',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Translator & Phrasebook'), findsOneWidget);
        expect(find.text('Translate to Japanese (日本語)'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'I have a food allergy');
        await tester.tap(find.text('Translate'));
        await tester.pumpAndSettle();

        expect(find.text('Offline Phrasebook Match'), findsOneWidget);
        expect(find.text('食物アレルギーがあります。'), findsWidgets);

        // Switch to Filipino (Tagalog)
        await tester.tap(find.text('🇵🇭 Filipino (Tagalog)'));
        await tester.pumpAndSettle();

        expect(
          find.text('Translate to Filipino (Tagalog) (Wikang Filipino)'),
          findsOneWidget,
        );
      },
    );
  });
}
