String? _nonEmptyString(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}

class EmergencyNumbers {
  const EmergencyNumbers({
    this.police,
    this.ambulance,
    this.fire,
    this.generalEmergency,
    this.touristHotline,
  });

  final String? police;
  final String? ambulance;
  final String? fire;
  final String? generalEmergency;
  final String? touristHotline;

  bool get hasAnyNumber =>
      (police != null && police!.isNotEmpty) ||
      (ambulance != null && ambulance!.isNotEmpty) ||
      (fire != null && fire!.isNotEmpty) ||
      (generalEmergency != null && generalEmergency!.isNotEmpty) ||
      (touristHotline != null && touristHotline!.isNotEmpty);

  factory EmergencyNumbers.fromJson(Map<String, dynamic> json) {
    return EmergencyNumbers(
      police: _nonEmptyString(json['police']),
      ambulance: _nonEmptyString(json['ambulance']),
      fire: _nonEmptyString(json['fire']),
      generalEmergency: _nonEmptyString(json['general_emergency']),
      touristHotline: _nonEmptyString(json['tourist_hotline']),
    );
  }

  Map<String, dynamic> toJson() => {
    'police': police,
    'ambulance': ambulance,
    'fire': fire,
    'general_emergency': generalEmergency,
    'tourist_hotline': touristHotline,
  };
}

class OfficialSafetyResource {
  const OfficialSafetyResource({
    required this.title,
    required this.publisher,
    required this.category,
    required this.url,
    required this.lastVerifiedAt,
  });

  final String title;
  final String publisher;
  final String category;
  final String url;
  final String lastVerifiedAt;

  factory OfficialSafetyResource.fromJson(Map<String, dynamic> json) {
    return OfficialSafetyResource(
      title: _nonEmptyString(json['title']) ?? '',
      publisher: _nonEmptyString(json['publisher']) ?? '',
      category: _nonEmptyString(json['category']) ?? 'general',
      url: _nonEmptyString(json['url']) ?? '',
      lastVerifiedAt: _nonEmptyString(json['last_verified_at']) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'publisher': publisher,
    'category': category,
    'url': url,
    'last_verified_at': lastVerifiedAt,
  };
}

class EmergencyPhrase {
  const EmergencyPhrase({
    required this.category,
    required this.english,
    required this.localText,
    required this.phonetic,
  });

  final String category;
  final String english;
  final String localText;
  final String phonetic;

  factory EmergencyPhrase.fromJson(Map<String, dynamic> json) {
    return EmergencyPhrase(
      category: _nonEmptyString(json['category']) ?? 'emergency',
      english: _nonEmptyString(json['english']) ?? '',
      localText: _nonEmptyString(json['local_text']) ?? '',
      phonetic: _nonEmptyString(json['phonetic']) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'english': english,
    'local_text': localText,
    'phonetic': phonetic,
  };
}

class DestinationSafetyProfile {
  const DestinationSafetyProfile({
    required this.countryCode,
    required this.countryName,
    required this.flagEmoji,
    required this.isCurated,
    required this.emergencyNumbers,
    required this.officialResources,
    required this.emergencyPhrases,
    required this.lastVerifiedAt,
    required this.disclaimer,
  });

  final String countryCode;
  final String countryName;
  final String flagEmoji;
  final bool isCurated;
  final EmergencyNumbers emergencyNumbers;
  final List<OfficialSafetyResource> officialResources;
  final List<EmergencyPhrase> emergencyPhrases;
  final String lastVerifiedAt;
  final String disclaimer;

  factory DestinationSafetyProfile.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final numbersJson = payload['emergency_numbers'] is Map
        ? Map<String, dynamic>.from(payload['emergency_numbers'] as Map)
        : <String, dynamic>{};
    final rawResources = payload['official_resources'] is List
        ? (payload['official_resources'] as List)
        : const [];
    final rawPhrases = payload['emergency_phrases'] is List
        ? (payload['emergency_phrases'] as List)
        : const [];

    return DestinationSafetyProfile(
      countryCode: _nonEmptyString(payload['country_code']) ?? 'UN',
      countryName:
          _nonEmptyString(payload['country_name']) ?? 'Unknown Destination',
      flagEmoji: _nonEmptyString(payload['flag_emoji']) ?? '🌍',
      isCurated: payload['is_curated'] as bool? ?? false,
      emergencyNumbers: EmergencyNumbers.fromJson(numbersJson),
      officialResources: rawResources
          .whereType<Map>()
          .map(
            (e) =>
                OfficialSafetyResource.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      emergencyPhrases: rawPhrases
          .whereType<Map>()
          .map((e) => EmergencyPhrase.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      lastVerifiedAt:
          _nonEmptyString(payload['last_verified_at']) ?? '2026-11-01',
      disclaimer: _nonEmptyString(payload['disclaimer']) ?? 'Emergency numbers and official government/airline portals are provided for reference only and do not constitute definitive visa, immigration, or medical advice. Verify entry rules directly with official authorities before travel.',
    );
  }

  Map<String, dynamic> toJson() => {
    'country_code': countryCode,
    'country_name': countryName,
    'flag_emoji': flagEmoji,
    'is_curated': isCurated,
    'emergency_numbers': emergencyNumbers.toJson(),
    'official_resources': officialResources.map((e) => e.toJson()).toList(),
    'emergency_phrases': emergencyPhrases.map((e) => e.toJson()).toList(),
    'last_verified_at': lastVerifiedAt,
    'disclaimer': disclaimer,
  };
}
