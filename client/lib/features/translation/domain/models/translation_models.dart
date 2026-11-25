class PhrasebookEntry {
  const PhrasebookEntry({
    required this.id,
    required this.category,
    required this.english,
    required this.localText,
    required this.phonetic,
    this.contextNote,
  });

  final String id;
  final String category;
  final String english;
  final String localText;
  final String phonetic;
  final String? contextNote;

  factory PhrasebookEntry.fromJson(Map<String, dynamic> json) {
    return PhrasebookEntry(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'essentials',
      english: json['english'] as String? ?? '',
      localText: json['local_text'] as String? ?? '',
      phonetic: json['phonetic'] as String? ?? '',
      contextNote: json['context_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'english': english,
    'local_text': localText,
    'phonetic': phonetic,
    'context_note': contextNote,
  };
}

class PhrasebookBundle {
  const PhrasebookBundle({
    required this.languageCode,
    required this.languageName,
    required this.nativeName,
    required this.flagEmoji,
    required this.countryCode,
    required this.categories,
    required this.phrases,
    required this.disclaimer,
  });

  final String languageCode;
  final String languageName;
  final String nativeName;
  final String flagEmoji;
  final String countryCode;
  final List<String> categories;
  final List<PhrasebookEntry> phrases;
  final String disclaimer;

  factory PhrasebookBundle.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'] is List
        ? (json['categories'] as List)
        : const [];
    final rawPhrases = json['phrases'] is List
        ? (json['phrases'] as List)
        : const [];

    return PhrasebookBundle(
      languageCode: json['language_code'] as String? ?? 'ja',
      languageName: json['language_name'] as String? ?? 'Japanese',
      nativeName: json['native_name'] as String? ?? '日本語',
      flagEmoji: json['flag_emoji'] as String? ?? '🇯🇵',
      countryCode: json['country_code'] as String? ?? 'JP',
      categories: rawCategories.map((e) => e.toString()).toList(),
      phrases: rawPhrases
          .whereType<Map>()
          .map((e) => PhrasebookEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      disclaimer: json['disclaimer'] as String? ?? 'Phrasebook entries and machine translations are provided for travel assistance only.',
    );
  }

  Map<String, dynamic> toJson() => {
    'language_code': languageCode,
    'language_name': languageName,
    'native_name': nativeName,
    'flag_emoji': flagEmoji,
    'country_code': countryCode,
    'categories': categories,
    'phrases': phrases.map((e) => e.toJson()).toList(),
    'disclaimer': disclaimer,
  };
}

class TranslationResult {
  const TranslationResult({
    required this.sourceText,
    required this.translatedText,
    required this.phonetic,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.provider,
    required this.isOfflineMatch,
    required this.disclaimer,
  });

  final String sourceText;
  final String translatedText;
  final String phonetic;
  final String sourceLanguage;
  final String targetLanguage;
  final String provider;
  final bool isOfflineMatch;
  final String disclaimer;

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      sourceText: json['source_text'] as String? ?? '',
      translatedText: json['translated_text'] as String? ?? '',
      phonetic: json['phonetic'] as String? ?? '',
      sourceLanguage: json['source_language'] as String? ?? 'en',
      targetLanguage: json['target_language'] as String? ?? 'ja',
      provider: json['provider'] as String? ?? 'offline_phrasebook',
      isOfflineMatch: json['is_offline_match'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? 'Phrasebook entries and machine translations are provided for travel assistance only.',
    );
  }

  Map<String, dynamic> toJson() => {
    'source_text': sourceText,
    'translated_text': translatedText,
    'phonetic': phonetic,
    'source_language': sourceLanguage,
    'target_language': targetLanguage,
    'provider': provider,
    'is_offline_match': isOfflineMatch,
    'disclaimer': disclaimer,
  };
}
