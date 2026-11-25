import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../domain/models/translation_models.dart';

class TranslationRepository {
  TranslationRepository({
    required this.apiClient,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  static const String defaultDisclaimer =
      'Phrasebook entries and machine translations are provided for travel assistance only. For medical allergies or legal declarations, verify accuracy with a qualified professional.';

  static const List<String> defaultCategories = [
    'essentials',
    'dining',
    'transit',
    'hotel',
    'shopping',
    'emergency',
  ];

  String _tripCacheKey(String tripId) => 'cached_phrasebook_trip_$tripId';
  String _langCacheKey(String lang) =>
      'cached_phrasebook_lang_${lang.trim().toLowerCase()}';

  Map<String, dynamic>? _extractMap(dynamic response) {
    if (response is Map && response['data'] is Map) {
      return Map<String, dynamic>.from(response['data'] as Map);
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  Future<PhrasebookBundle> getTripPhrasebook(
    String tripId, {
    String? languageOverride,
  }) async {
    final trimmedOverride = languageOverride?.trim();
    final hasOverride = trimmedOverride != null && trimmedOverride.isNotEmpty;

    try {
      final response = await apiClient.get(
        '/trips/$tripId/phrasebook',
        queryParameters: hasOverride ? {'language': trimmedOverride} : null,
      );
      final map = _extractMap(response);
      if (map != null) {
        final bundle = PhrasebookBundle.fromJson(map);
        await _storage.write(
          key: _tripCacheKey(tripId),
          value: jsonEncode(bundle.toJson()),
        );
        await _storage.write(
          key: _langCacheKey(bundle.languageCode),
          value: jsonEncode(bundle.toJson()),
        );
        return bundle;
      }
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        await _storage.delete(key: _tripCacheKey(tripId));
        rethrow;
      }
    } catch (_) {
      // Fall through to cached or bundled phrasebook
    }

    final cached = await _storage.read(key: _tripCacheKey(tripId));
    if (cached != null && cached.isNotEmpty) {
      final cachedBundle = PhrasebookBundle.fromJson(
        Map<String, dynamic>.from(jsonDecode(cached) as Map),
      );
      final targetLang = hasOverride
          ? resolveOfflinePhrasebook(trimmedOverride).languageCode
          : null;
      if (targetLang == null ||
          cachedBundle.languageCode.toLowerCase() == targetLang.toLowerCase()) {
        return cachedBundle;
      }
    }

    return resolveOfflinePhrasebook(trimmedOverride ?? 'ja');
  }

  Future<PhrasebookBundle> getPhrasebook(String languageOrCountry) async {
    final normalized = languageOrCountry.trim().isEmpty
        ? 'ja'
        : languageOrCountry.trim();
    try {
      final response = await apiClient.get(
        '/translation/phrasebook/${Uri.encodeComponent(normalized)}',
      );
      final map = _extractMap(response);
      if (map != null) {
        final bundle = PhrasebookBundle.fromJson(map);
        await _storage.write(
          key: _langCacheKey(bundle.languageCode),
          value: jsonEncode(bundle.toJson()),
        );
        return bundle;
      }
    } catch (_) {
      // Fall through to offline cache or bundled phrasebook
    }

    final resolved = resolveOfflinePhrasebook(normalized);
    final cached = await _storage.read(
      key: _langCacheKey(resolved.languageCode),
    );
    if (cached != null && cached.isNotEmpty) {
      return PhrasebookBundle.fromJson(
        Map<String, dynamic>.from(jsonDecode(cached) as Map),
      );
    }

    return resolved;
  }

  /// Translate text using local offline phrasebook first, then server endpoint when consented.
  Future<TranslationResult> translateText({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'en',
    required bool consentCloud,
  }) async {
    final trimmed = text.trim();
    final offlineBundle = resolveOfflinePhrasebook(targetLanguage);
    final needle = trimmed.toLowerCase().replaceAll(RegExp(r'[.!?]+$'), '');

    for (final entry in offlineBundle.phrases) {
      final candidate = entry.english.toLowerCase().replaceAll(
        RegExp(r'[.!?]+$'),
        '',
      );
      if (candidate == needle ||
          entry.english.toLowerCase() == trimmed.toLowerCase()) {
        return TranslationResult(
          sourceText: trimmed,
          translatedText: entry.localText,
          phonetic: entry.phonetic,
          sourceLanguage: sourceLanguage,
          targetLanguage: offlineBundle.languageCode,
          provider: 'offline_phrasebook',
          isOfflineMatch: true,
          disclaimer: defaultDisclaimer,
        );
      }
    }

    if (!consentCloud) {
      throw const ApiException(
        code: 'cloud_consent_required',
        message: 'Phrase not found in offline phrasebook. Enable cloud translation consent to translate custom text.',
        statusCode: 422,
      );
    }

    final response = await apiClient.post(
      '/translation/translate',
      data: {
        'text': trimmed,
        'source_language': sourceLanguage,
        'target_language': offlineBundle.languageCode,
        'consent_cloud': consentCloud,
      },
    );

    final map = _extractMap(response);
    if (map != null) {
      return TranslationResult.fromJson(map);
    }

    throw const ApiException(
      code: 'translation_unavailable',
      message: 'Unable to translate phrase at this time.',
      statusCode: 503,
    );
  }

  static PhrasebookBundle resolveOfflinePhrasebook(String languageOrCountry) {
    final norm = languageOrCountry.trim().toLowerCase();
    for (final pack in bundledOfflinePhrasebooks) {
      if (pack.languageCode.toLowerCase() == norm ||
          pack.countryCode.toLowerCase() == norm ||
          pack.languageName.toLowerCase() == norm) {
        return pack;
      }
    }
    if (norm.contains('philippine') ||
        norm.contains('tagalog') ||
        norm.contains('filipino') ||
        norm.contains('manila')) {
      return bundledOfflinePhrasebooks.firstWhere(
        (p) => p.languageCode == 'tl',
      );
    }
    if (norm.contains('korea') || norm.contains('seoul')) {
      return bundledOfflinePhrasebooks.firstWhere(
        (p) => p.languageCode == 'ko',
      );
    }
    if (norm.contains('thai') || norm.contains('bangkok')) {
      return bundledOfflinePhrasebooks.firstWhere(
        (p) => p.languageCode == 'th',
      );
    }
    if (norm.contains('france') ||
        norm.contains('french') ||
        norm.contains('paris')) {
      return bundledOfflinePhrasebooks.firstWhere(
        (p) => p.languageCode == 'fr',
      );
    }
    return bundledOfflinePhrasebooks.first;
  }

  static const List<PhrasebookBundle> bundledOfflinePhrasebooks = [
    PhrasebookBundle(
      languageCode: 'ja',
      languageName: 'Japanese',
      nativeName: '日本語',
      flagEmoji: '🇯🇵',
      countryCode: 'JP',
      categories: defaultCategories,
      phrases: [
        PhrasebookEntry(
          id: 'ja-ess-1',
          category: 'essentials',
          english: 'Excuse me / Thank you.',
          localText: 'すみません / ありがとうございます。',
          phonetic: 'Sumimasen / Arigatou gozaimasu.',
          contextNote: 'Polite everyday greeting and attention-getter.',
        ),
        PhrasebookEntry(
          id: 'ja-ess-2',
          category: 'essentials',
          english: 'Do you speak English?',
          localText: '英語を話せますか？',
          phonetic: 'Eigo o hanasemasu ka?',
        ),
        PhrasebookEntry(
          id: 'ja-din-1',
          category: 'dining',
          english: 'I have a food allergy.',
          localText: '食物アレルギーがあります。',
          phonetic: 'Shokumotsu arerugii ga arimasu.',
          contextNote: 'Show to restaurant staff before ordering.',
        ),
        PhrasebookEntry(
          id: 'ja-din-2',
          category: 'dining',
          english: 'Check, please.',
          localText: 'お会計をお願いします。',
          phonetic: 'O-kaikei o onegaishimasu.',
        ),
        PhrasebookEntry(
          id: 'ja-trn-1',
          category: 'transit',
          english: 'Does this train go to the airport?',
          localText: 'この電車は空港に行きますか？',
          phonetic: 'Kono densha wa kuukou ni ikimasu ka?',
        ),
        PhrasebookEntry(
          id: 'ja-htl-1',
          category: 'hotel',
          english: 'Can you store my luggage before check-in?',
          localText: 'チェックイン前に荷物を預かってもらえますか？',
          phonetic: 'Chekku-in mae ni nimotsu o azukatte moraemasu ka?',
        ),
        PhrasebookEntry(
          id: 'ja-shp-1',
          category: 'shopping',
          english: 'Is this tax-free?',
          localText: 'これは免税になりますか？',
          phonetic: 'Kore wa menzei ni narimasu ka?',
        ),
        PhrasebookEntry(
          id: 'ja-emg-1',
          category: 'emergency',
          english: 'Help! Please call an ambulance.',
          localText: '助けて！救急車を呼んでください。',
          phonetic: 'Tasukete! Kyuukyuusha o yonde kudasai.',
          contextNote: 'Emergency medical number in Japan is 119.',
        ),
      ],
      disclaimer: defaultDisclaimer,
    ),
    PhrasebookBundle(
      languageCode: 'tl',
      languageName: 'Filipino (Tagalog)',
      nativeName: 'Wikang Filipino',
      flagEmoji: '🇵🇭',
      countryCode: 'PH',
      categories: defaultCategories,
      phrases: [
        PhrasebookEntry(
          id: 'tl-ess-1',
          category: 'essentials',
          english: 'Thank you very much.',
          localText: 'Maraming salamat po.',
          phonetic: 'Mah-rah-ming sah-lah-maht poh.',
          contextNote: '"Po" adds polite respect.',
        ),
        PhrasebookEntry(
          id: 'tl-din-1',
          category: 'dining',
          english: 'I have a food allergy.',
          localText: 'May allergy po ako sa pagkain.',
          phonetic: 'May ah-ler-jee poh ah-koh sah pahg-kah-in.',
        ),
        PhrasebookEntry(
          id: 'tl-trn-1',
          category: 'transit',
          english: 'Please drop me off at the terminal.',
          localText: 'Pakibaba na lang po ako sa terminal.',
          phonetic: 'Pah-kee-bah-bah nah lahng poh ah-koh sah ter-mee-nahl.',
        ),
        PhrasebookEntry(
          id: 'tl-htl-1',
          category: 'hotel',
          english: 'I have a reservation.',
          localText: 'May booking po ako.',
          phonetic: 'May boo-king poh ah-koh.',
        ),
        PhrasebookEntry(
          id: 'tl-shp-1',
          category: 'shopping',
          english: 'How much is this?',
          localText: 'Magkano po ito?',
          phonetic: 'Mahg-kah-noh poh ee-toh?',
        ),
        PhrasebookEntry(
          id: 'tl-emg-1',
          category: 'emergency',
          english: 'Help! We need an ambulance.',
          localText: 'Tulong! Kailangan namin ng ambulansya.',
          phonetic:
              'Too-long! Kah-ee-lahng-ahn nah-min nahng ahm-boo-lahn-syah.',
        ),
      ],
      disclaimer: defaultDisclaimer,
    ),
    PhrasebookBundle(
      languageCode: 'ko',
      languageName: 'Korean',
      nativeName: '한국어',
      flagEmoji: '🇰🇷',
      countryCode: 'KR',
      categories: defaultCategories,
      phrases: [
        PhrasebookEntry(
          id: 'ko-ess-1',
          category: 'essentials',
          english: 'Hello / Thank you.',
          localText: '안녕하세요 / 감사합니다.',
          phonetic: 'Annyeonghaseyo / Kamsahamnida.',
        ),
        PhrasebookEntry(
          id: 'ko-din-1',
          category: 'dining',
          english: 'Not spicy, please.',
          localText: '안 맵게 해 주세요.',
          phonetic: 'An maepge hae juseyo.',
        ),
        PhrasebookEntry(
          id: 'ko-trn-1',
          category: 'transit',
          english: 'Where is the subway station?',
          localText: '지하철역이 어디예요?',
          phonetic: 'Jihacheol-yeog-i eodiyeyo?',
        ),
        PhrasebookEntry(
          id: 'ko-emg-1',
          category: 'emergency',
          english: 'Help! Please call 119.',
          localText: '도와주세요! 119를 불러 주세요.',
          phonetic: 'Dowajuseyo! Il-il-gu-reul bulleo juseyo.',
        ),
      ],
      disclaimer: defaultDisclaimer,
    ),
    PhrasebookBundle(
      languageCode: 'th',
      languageName: 'Thai',
      nativeName: 'ภาษาไทย',
      flagEmoji: '🇹🇭',
      countryCode: 'TH',
      categories: defaultCategories,
      phrases: [
        PhrasebookEntry(
          id: 'th-ess-1',
          category: 'essentials',
          english: 'Hello / Thank you.',
          localText: 'สวัสดี / ขอบคุณ',
          phonetic: 'Sawatdee / Khop khun (khrap/kha).',
        ),
        PhrasebookEntry(
          id: 'th-din-1',
          category: 'dining',
          english: 'Not spicy, please.',
          localText: 'ไม่เผ็ดนะครับ/คะ',
          phonetic: 'Mai phet na khrap/kha.',
        ),
        PhrasebookEntry(
          id: 'th-emg-1',
          category: 'emergency',
          english: 'Help! Please call an ambulance.',
          localText: 'ช่วยด้วย! กรุณาเรียกรถพยาบาล',
          phonetic: 'Chuay duay! Karuna riak rot phayaban.',
        ),
      ],
      disclaimer: defaultDisclaimer,
    ),
    PhrasebookBundle(
      languageCode: 'fr',
      languageName: 'French',
      nativeName: 'Français',
      flagEmoji: '🇫🇷',
      countryCode: 'FR',
      categories: defaultCategories,
      phrases: [
        PhrasebookEntry(
          id: 'fr-ess-1',
          category: 'essentials',
          english: 'Hello, excuse me.',
          localText: 'Bonjour, excusez-moi.',
          phonetic: 'Bon-zhoor, ex-koo-zay mwah.',
        ),
        PhrasebookEntry(
          id: 'fr-din-1',
          category: 'dining',
          english: 'I have a severe food allergy.',
          localText: 'J’ai une allergie alimentaire grave.',
          phonetic: 'Zhay oon ah-lair-zhee ah-lee-mahn-tair grahv.',
        ),
        PhrasebookEntry(
          id: 'fr-emg-1',
          category: 'emergency',
          english: 'Help! Call an ambulance!',
          localText: 'Au secours ! Appelez une ambulance !',
          phonetic: 'Oh suh-koor! Ah-play oon ahm-boo-lahns!',
        ),
      ],
      disclaimer: defaultDisclaimer,
    ),
  ];
}
