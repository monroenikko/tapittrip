import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../domain/models/destination_safety_profile.dart';

class SafetyRepository {
  SafetyRepository({required this.apiClient, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient apiClient;
  final FlutterSecureStorage _storage;

  static const String defaultDisclaimer =
      'Emergency numbers and official government/airline portals are provided for reference only and do not constitute definitive visa, immigration, or medical advice. Verify entry rules directly with official authorities before travel.';

  String _tripCacheKey(String tripId) => 'cached_safety_trip_$tripId';
  String _countryCacheKey(String country) =>
      'cached_safety_country_${country.trim().toUpperCase()}';

  Map<String, dynamic>? _extractMap(dynamic response) {
    if (response is Map && response['data'] is Map) {
      return Map<String, dynamic>.from(response['data'] as Map);
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  List<dynamic>? _extractList(dynamic response) {
    if (response is List) {
      return response;
    }
    if (response is Map && response['data'] is List) {
      return response['data'] as List<dynamic>;
    }
    return null;
  }

  bool _matchesCountry(DestinationSafetyProfile profile, String country) {
    final norm = country.trim().toLowerCase();
    if (norm.isEmpty) return true;
    final resolved = resolveOfflineProfile(country);
    return profile.countryCode.toLowerCase() == norm ||
        profile.countryName.toLowerCase() == norm ||
        (resolved.isCurated &&
            profile.countryCode.toLowerCase() ==
                resolved.countryCode.toLowerCase());
  }

  Future<DestinationSafetyProfile> getTripSafetyProfile(
    String tripId, {
    String? countryOverride,
  }) async {
    final trimmedOverride = countryOverride?.trim();
    final hasOverride = trimmedOverride != null && trimmedOverride.isNotEmpty;

    try {
      final response = await apiClient.get(
        '/trips/$tripId/safety',
        queryParameters: hasOverride ? {'country': trimmedOverride} : null,
      );
      final map = _extractMap(response);
      if (map != null) {
        final profile = DestinationSafetyProfile.fromJson(map);
        await _storage.write(
          key: _tripCacheKey(tripId),
          value: jsonEncode(profile.toJson()),
        );
        await _storage.write(
          key: _countryCacheKey(profile.countryCode),
          value: jsonEncode(profile.toJson()),
        );
        return profile;
      }
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        await _storage.delete(key: _tripCacheKey(tripId));
        rethrow;
      }
    } catch (_) {
      // Fall through to offline cache or bundled offline directory
    }

    final cached = await _storage.read(key: _tripCacheKey(tripId));
    if (cached != null && cached.isNotEmpty) {
      final cachedProfile = DestinationSafetyProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(cached) as Map),
      );
      if (!hasOverride || _matchesCountry(cachedProfile, trimmedOverride)) {
        return cachedProfile;
      }
    }

    if (hasOverride) {
      final cachedByCountry = await _storage.read(
        key: _countryCacheKey(trimmedOverride),
      );
      if (cachedByCountry != null && cachedByCountry.isNotEmpty) {
        return DestinationSafetyProfile.fromJson(
          Map<String, dynamic>.from(jsonDecode(cachedByCountry) as Map),
        );
      }
      return resolveOfflineProfile(trimmedOverride);
    }

    return resolveOfflineProfile('JP');
  }

  Future<DestinationSafetyProfile> getCountrySafetyProfile(
    String country,
  ) async {
    final normalized = country.trim().isEmpty ? 'JP' : country.trim();
    try {
      final response = await apiClient.get(
        '/safety/countries/${Uri.encodeComponent(normalized)}',
      );
      final map = _extractMap(response);
      if (map != null) {
        final profile = DestinationSafetyProfile.fromJson(map);
        await _storage.write(
          key: _countryCacheKey(profile.countryCode),
          value: jsonEncode(profile.toJson()),
        );
        return profile;
      }
    } catch (_) {
      // Fall through to offline cache or bundled directory
    }

    final resolved = resolveOfflineProfile(normalized);
    final cached =
        await _storage.read(key: _countryCacheKey(normalized)) ??
        await _storage.read(key: _countryCacheKey(resolved.countryCode));
    if (cached != null && cached.isNotEmpty) {
      return DestinationSafetyProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(cached) as Map),
      );
    }

    return resolved;
  }

  Future<List<DestinationSafetyProfile>> listCuratedProfiles({
    String? query,
  }) async {
    try {
      final response = await apiClient.get(
        '/safety/countries',
        queryParameters: query != null && query.trim().isNotEmpty
            ? {'q': query.trim()}
            : null,
      );
      final list = _extractList(response);
      if (list != null) {
        return list
            .whereType<Map>()
            .map(
              (item) => DestinationSafetyProfile.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
    } catch (_) {
      // Offline fallback to bundled profiles
    }

    final all = bundledOfflineProfiles;
    if (query == null || query.trim().isEmpty) {
      return all;
    }
    final q = query.trim().toLowerCase();
    return all
        .where(
          (p) =>
              p.countryName.toLowerCase().contains(q) ||
              p.countryCode.toLowerCase().contains(q),
        )
        .toList();
  }

  static DestinationSafetyProfile resolveOfflineProfile(String country) {
    final norm = country.trim().toLowerCase();
    for (final profile in bundledOfflineProfiles) {
      if (profile.countryCode.toLowerCase() == norm ||
          profile.countryName.toLowerCase() == norm) {
        return profile;
      }
    }
    if (norm.contains('japan') ||
        norm.contains('nippon') ||
        norm.contains('tokyo') ||
        norm.contains('osaka') ||
        norm.contains('kyoto')) {
      return bundledOfflineProfiles.firstWhere((p) => p.countryCode == 'JP');
    }
    if (norm.contains('philippine') ||
        norm.contains('manila') ||
        norm.contains('cebu') ||
        norm.contains('palawan')) {
      return bundledOfflineProfiles.firstWhere((p) => p.countryCode == 'PH');
    }
    if (norm.contains('korea') ||
        norm.contains('seoul') ||
        norm.contains('busan')) {
      return bundledOfflineProfiles.firstWhere((p) => p.countryCode == 'KR');
    }
    if (norm.contains('singapore')) {
      return bundledOfflineProfiles.firstWhere((p) => p.countryCode == 'SG');
    }
    if (norm.contains('thailand') ||
        norm.contains('bangkok') ||
        norm.contains('phuket') ||
        norm.contains('chiang mai')) {
      return bundledOfflineProfiles.firstWhere((p) => p.countryCode == 'TH');
    }
    if (norm == 'usa' ||
        norm.contains('united states') ||
        norm.contains('america')) {
      return bundledOfflineProfiles.firstWhere((p) => p.countryCode == 'US');
    }
    if (norm == 'uk' ||
        norm.contains('united kingdom') ||
        norm.contains('great britain') ||
        norm.contains('england') ||
        norm.contains('london')) {
      return bundledOfflineProfiles.firstWhere((p) => p.countryCode == 'GB');
    }
    if (norm.contains('france') || norm.contains('paris')) {
      return bundledOfflineProfiles.firstWhere((p) => p.countryCode == 'FR');
    }
    if (norm.contains('australia') ||
        norm.contains('sydney') ||
        norm.contains('melbourne')) {
      return bundledOfflineProfiles.firstWhere((p) => p.countryCode == 'AU');
    }

    return DestinationSafetyProfile(
      countryCode: country.trim().length == 2
          ? country.trim().toUpperCase()
          : 'UN',
      countryName: country.trim().isEmpty
          ? 'Unknown Destination'
          : country.trim(),
      flagEmoji: '🌍',
      isCurated: false,
      emergencyNumbers: const EmergencyNumbers(),
      officialResources: const [],
      emergencyPhrases: const [
        EmergencyPhrase(
          category: 'medical',
          english: 'I need a doctor / hospital.',
          localText: 'I need a doctor / hospital.',
          phonetic: 'I need a doctor / hospital.',
        ),
        EmergencyPhrase(
          category: 'emergency',
          english: 'Please call the police.',
          localText: 'Please call the police.',
          phonetic: 'Please call the police.',
        ),
      ],
      lastVerifiedAt: '2026-11-01',
      disclaimer: defaultDisclaimer,
    );
  }

  static const List<DestinationSafetyProfile> bundledOfflineProfiles = [
    DestinationSafetyProfile(
      countryCode: 'JP',
      countryName: 'Japan',
      flagEmoji: '🇯🇵',
      isCurated: true,
      emergencyNumbers: EmergencyNumbers(
        police: '110',
        ambulance: '119',
        fire: '119',
        generalEmergency: '110 / 119',
        touristHotline: '050-3816-2787 (JNTO 24h)',
      ),
      officialResources: [
        OfficialSafetyResource(
          title: 'Visit Japan Web (Immigration & Customs QR)',
          publisher: 'Digital Agency, Government of Japan',
          category: 'entry_requirements',
          url: 'https://services.digital.go.jp/en/visit-japan-web/',
          lastVerifiedAt: '2026-11-01',
        ),
        OfficialSafetyResource(
          title: 'JNTO Safety Tips for Travelers in Japan',
          publisher: 'Japan National Tourism Organization',
          category: 'safety_advisory',
          url: 'https://www.jnto.go.jp/safety-tips/eng/index.html',
          lastVerifiedAt: '2026-11-01',
        ),
      ],
      emergencyPhrases: [
        EmergencyPhrase(
          category: 'emergency',
          english: 'Help! Please call an ambulance.',
          localText: '助けて！救急車を呼んでください。',
          phonetic: 'Tasukete! Kyuukyuusha o yonde kudasai.',
        ),
        EmergencyPhrase(
          category: 'emergency',
          english: 'Please call the police.',
          localText: '警察を呼んでください。',
          phonetic: 'Keisatsu o yonde kudasai.',
        ),
        EmergencyPhrase(
          category: 'medical',
          english: 'Where is the nearest hospital?',
          localText: '一番近い病院はどこですか？',
          phonetic: 'Ichiban chikai byouin wa doko desu ka?',
        ),
        EmergencyPhrase(
          category: 'consular',
          english: 'I lost my passport.',
          localText: 'パスポートをなくしました。',
          phonetic: 'Pasupooto o nakushimashita.',
        ),
      ],
      lastVerifiedAt: '2026-11-01',
      disclaimer: defaultDisclaimer,
    ),
    DestinationSafetyProfile(
      countryCode: 'PH',
      countryName: 'Philippines',
      flagEmoji: '🇵🇭',
      isCurated: true,
      emergencyNumbers: EmergencyNumbers(
        police: '911',
        ambulance: '911',
        fire: '911',
        generalEmergency: '911',
        touristHotline: '+63 2 1383 (DOT Tourist Assistance)',
      ),
      officialResources: [
        OfficialSafetyResource(
          title: 'Philippine eTravel Portal',
          publisher: 'Republic of the Philippines',
          category: 'entry_requirements',
          url: 'https://etravel.gov.ph/',
          lastVerifiedAt: '2026-11-01',
        ),
        OfficialSafetyResource(
          title: 'Bureau of Immigration Advisory',
          publisher: 'Bureau of Immigration Philippines',
          category: 'immigration',
          url: 'https://immigration.gov.ph/',
          lastVerifiedAt: '2026-11-01',
        ),
      ],
      emergencyPhrases: [
        EmergencyPhrase(
          category: 'emergency',
          english: 'Help! We need an ambulance.',
          localText: 'Tulong! Kailangan namin ng ambulansya.',
          phonetic:
              'Too-long! Kah-ee-lahng-ahn nah-min nahng ahm-boo-lahn-syah.',
        ),
        EmergencyPhrase(
          category: 'emergency',
          english: 'Please call the police.',
          localText: 'Pakitawag po ang pulis.',
          phonetic: 'Pah-kee-tah-wahg poh ahng poo-lees.',
        ),
        EmergencyPhrase(
          category: 'medical',
          english: 'Where is the nearest hospital?',
          localText: 'Saan po ang pinakamalapit na ospital?',
          phonetic:
              'Sah-ahn poh ahng pee-nah-kah-mah-lah-peet nah os-pee-tahl?',
        ),
      ],
      lastVerifiedAt: '2026-11-01',
      disclaimer: defaultDisclaimer,
    ),
    DestinationSafetyProfile(
      countryCode: 'KR',
      countryName: 'South Korea',
      flagEmoji: '🇰🇷',
      isCurated: true,
      emergencyNumbers: EmergencyNumbers(
        police: '112',
        ambulance: '119',
        fire: '119',
        generalEmergency: '112 / 119',
        touristHotline: '1330 (KTO Travel Helpline)',
      ),
      officialResources: [
        OfficialSafetyResource(
          title: 'K-ETA & Korea Entry Guidance',
          publisher: 'Ministry of Justice, Republic of Korea',
          category: 'entry_requirements',
          url: 'https://www.k-eta.go.kr/',
          lastVerifiedAt: '2026-11-01',
        ),
        OfficialSafetyResource(
          title: 'Q-CODE Quarantine Information System',
          publisher: 'KDCA Republic of Korea',
          category: 'health_declaration',
          url: 'https://qcode.kdca.go.kr/',
          lastVerifiedAt: '2026-11-01',
        ),
      ],
      emergencyPhrases: [
        EmergencyPhrase(
          category: 'emergency',
          english: 'Help! Please call 119.',
          localText: '도와주세요! 119를 불러 주세요.',
          phonetic: 'Dowajuseyo! Il-il-gu-reul bulleo juseyo.',
        ),
        EmergencyPhrase(
          category: 'medical',
          english: 'Where is the nearest hospital?',
          localText: '가장 가까운 병원이 어디예요?',
          phonetic: 'Gajang gakkaun byeongwon-i eodiyeyo?',
        ),
        EmergencyPhrase(
          category: 'consular',
          english: 'I lost my passport.',
          localText: '여권을 잃어버렸어요.',
          phonetic: 'Yeogwon-eul ilheobeoryeosseoyo.',
        ),
      ],
      lastVerifiedAt: '2026-11-01',
      disclaimer: defaultDisclaimer,
    ),
    DestinationSafetyProfile(
      countryCode: 'SG',
      countryName: 'Singapore',
      flagEmoji: '🇸🇬',
      isCurated: true,
      emergencyNumbers: EmergencyNumbers(
        police: '999',
        ambulance: '995',
        fire: '995',
        generalEmergency: '999 / 995',
        touristHotline: '1800-736-2000 (STB Tourist Line)',
      ),
      officialResources: [
        OfficialSafetyResource(
          title: 'SG Arrival Card (SGAC)',
          publisher: 'Immigration & Checkpoints Authority (ICA)',
          category: 'entry_requirements',
          url: 'https://eservices.ica.gov.sg/sgarrivalcard/',
          lastVerifiedAt: '2026-11-01',
        ),
      ],
      emergencyPhrases: [
        EmergencyPhrase(
          category: 'emergency',
          english: 'Please call an ambulance (995).',
          localText: 'Please call an ambulance (995).',
          phonetic: 'Please call an ambulance (995).',
        ),
        EmergencyPhrase(
          category: 'medical',
          english: 'Where is the nearest 24-hour clinic?',
          localText: 'Where is the nearest 24-hour clinic?',
          phonetic: 'Where is the nearest 24-hour clinic?',
        ),
      ],
      lastVerifiedAt: '2026-11-01',
      disclaimer: defaultDisclaimer,
    ),
    DestinationSafetyProfile(
      countryCode: 'TH',
      countryName: 'Thailand',
      flagEmoji: '🇹🇭',
      isCurated: true,
      emergencyNumbers: EmergencyNumbers(
        police: '191',
        ambulance: '1669',
        fire: '199',
        generalEmergency: '191 / 1669',
        touristHotline: '1155 (Tourist Police)',
      ),
      officialResources: [
        OfficialSafetyResource(
          title: 'Thai Official e-Visa Portal',
          publisher: 'Ministry of Foreign Affairs, Kingdom of Thailand',
          category: 'entry_requirements',
          url: 'https://www.thaievisa.go.th/',
          lastVerifiedAt: '2026-11-01',
        ),
      ],
      emergencyPhrases: [
        EmergencyPhrase(
          category: 'emergency',
          english: 'Help! Please call an ambulance.',
          localText: 'ช่วยด้วย! กรุณาเรียกรถพยาบาล',
          phonetic: 'Chuay duay! Karuna riak rot phayaban.',
        ),
        EmergencyPhrase(
          category: 'medical',
          english: 'I need to go to the hospital.',
          localText: 'ฉันต้องไปโรงพยาบาล',
          phonetic: 'Chan tong pai rong phayaban.',
        ),
      ],
      lastVerifiedAt: '2026-11-01',
      disclaimer: defaultDisclaimer,
    ),
    DestinationSafetyProfile(
      countryCode: 'US',
      countryName: 'United States',
      flagEmoji: '🇺🇸',
      isCurated: true,
      emergencyNumbers: EmergencyNumbers(
        police: '911',
        ambulance: '911',
        fire: '911',
        generalEmergency: '911',
      ),
      officialResources: [
        OfficialSafetyResource(
          title: 'Official ESTA Application Portal',
          publisher: 'U.S. Customs and Border Protection',
          category: 'entry_requirements',
          url: 'https://esta.cbp.dhs.gov/',
          lastVerifiedAt: '2026-11-01',
        ),
      ],
      emergencyPhrases: [
        EmergencyPhrase(
          category: 'emergency',
          english: 'Please call 911 immediately.',
          localText: 'Please call 911 immediately.',
          phonetic: 'Please call 911 immediately.',
        ),
      ],
      lastVerifiedAt: '2026-11-01',
      disclaimer: defaultDisclaimer,
    ),
    DestinationSafetyProfile(
      countryCode: 'GB',
      countryName: 'United Kingdom',
      flagEmoji: '🇬🇧',
      isCurated: true,
      emergencyNumbers: EmergencyNumbers(
        police: '999',
        ambulance: '999',
        fire: '999',
        generalEmergency: '999 / 112',
        touristHotline: '111 (NHS Non-Emergency Medical)',
      ),
      officialResources: [
        OfficialSafetyResource(
          title: 'UK Electronic Travel Authorisation (ETA)',
          publisher: 'GOV.UK',
          category: 'entry_requirements',
          url: 'https://www.gov.uk/guidance/apply-for-an-electronic-travel-authorisation-eta',
          lastVerifiedAt: '2026-11-01',
        ),
      ],
      emergencyPhrases: [
        EmergencyPhrase(
          category: 'emergency',
          english: 'Please call 999 for an ambulance.',
          localText: 'Please call 999 for an ambulance.',
          phonetic: 'Please call 999 for an ambulance.',
        ),
      ],
      lastVerifiedAt: '2026-11-01',
      disclaimer: defaultDisclaimer,
    ),
    DestinationSafetyProfile(
      countryCode: 'FR',
      countryName: 'France',
      flagEmoji: '🇫🇷',
      isCurated: true,
      emergencyNumbers: EmergencyNumbers(
        police: '17',
        ambulance: '15',
        fire: '18',
        generalEmergency: '112',
      ),
      officialResources: [
        OfficialSafetyResource(
          title: 'France-Visas Official Portal',
          publisher: 'French Government',
          category: 'entry_requirements',
          url: 'https://france-visas.gouv.fr/',
          lastVerifiedAt: '2026-11-01',
        ),
      ],
      emergencyPhrases: [
        EmergencyPhrase(
          category: 'emergency',
          english: 'Help! Call an ambulance!',
          localText: 'Au secours ! Appelez une ambulance !',
          phonetic: 'Oh suh-koor! Ah-play oon ahm-boo-lahns!',
        ),
        EmergencyPhrase(
          category: 'medical',
          english: 'Where is the nearest pharmacy?',
          localText: 'Où est la pharmacie la plus proche ?',
          phonetic: 'Oo eh lah far-mah-see lah ploo prosh?',
        ),
      ],
      lastVerifiedAt: '2026-11-01',
      disclaimer: defaultDisclaimer,
    ),
    DestinationSafetyProfile(
      countryCode: 'AU',
      countryName: 'Australia',
      flagEmoji: '🇦🇺',
      isCurated: true,
      emergencyNumbers: EmergencyNumbers(
        police: '000',
        ambulance: '000',
        fire: '000',
        generalEmergency: '000 / 112',
        touristHotline: '131 444 (Police Non-Emergency)',
      ),
      officialResources: [
        OfficialSafetyResource(
          title: 'Australian Department of Home Affairs Immigration',
          publisher: 'Australian Government',
          category: 'entry_requirements',
          url: 'https://immi.homeaffairs.gov.au/',
          lastVerifiedAt: '2026-11-01',
        ),
      ],
      emergencyPhrases: [
        EmergencyPhrase(
          category: 'emergency',
          english: 'Please dial 000 for emergency assistance.',
          localText: 'Please dial 000 for emergency assistance.',
          phonetic: 'Please dial 000 for emergency assistance.',
        ),
      ],
      lastVerifiedAt: '2026-11-01',
      disclaimer: defaultDisclaimer,
    ),
  ];
}
