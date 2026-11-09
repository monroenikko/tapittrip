class CountryItem {
  const CountryItem({
    required this.name,
    required this.code,
    required this.currency,
    required this.flag,
  });

  final String name;
  final String code;
  final String currency;
  final String flag;
}

class CountryCurrencyHelper {
  static const List<CountryItem> supportedCountries = [
    CountryItem(name: 'Philippines', code: 'PH', currency: 'PHP', flag: '🇵🇭'),
    CountryItem(name: 'Japan', code: 'JP', currency: 'JPY', flag: '🇯🇵'),
    CountryItem(
      name: 'United States',
      code: 'US',
      currency: 'USD',
      flag: '🇺🇸',
    ),
    CountryItem(name: 'Singapore', code: 'SG', currency: 'SGD', flag: '🇸🇬'),
    CountryItem(
      name: 'United Kingdom',
      code: 'GB',
      currency: 'GBP',
      flag: '🇬🇧',
    ),
    CountryItem(name: 'Australia', code: 'AU', currency: 'AUD', flag: '🇦🇺'),
    CountryItem(name: 'France', code: 'FR', currency: 'EUR', flag: '🇫🇷'),
    CountryItem(name: 'Germany', code: 'DE', currency: 'EUR', flag: '🇩🇪'),
    CountryItem(name: 'Italy', code: 'IT', currency: 'EUR', flag: '🇮🇹'),
    CountryItem(name: 'Spain', code: 'ES', currency: 'EUR', flag: '🇪🇸'),
    CountryItem(name: 'Thailand', code: 'TH', currency: 'THB', flag: '🇹🇭'),
    CountryItem(name: 'South Korea', code: 'KR', currency: 'KRW', flag: '🇰🇷'),
    CountryItem(name: 'Canada', code: 'CA', currency: 'CAD', flag: '🇨🇦'),
    CountryItem(name: 'Hong Kong', code: 'HK', currency: 'HKD', flag: '🇭🇰'),
    CountryItem(name: 'Taiwan', code: 'TW', currency: 'TWD', flag: '🇹🇼'),
    CountryItem(name: 'Indonesia', code: 'ID', currency: 'IDR', flag: '🇮🇩'),
    CountryItem(name: 'Malaysia', code: 'MY', currency: 'MYR', flag: '🇲🇾'),
    CountryItem(
      name: 'United Arab Emirates',
      code: 'AE',
      currency: 'AED',
      flag: '🇦🇪',
    ),
    CountryItem(name: 'Vietnam', code: 'VN', currency: 'VND', flag: '🇻🇳'),
    CountryItem(name: 'Switzerland', code: 'CH', currency: 'CHF', flag: '🇨🇭'),
  ];

  static String resolveCurrency(
    String? input, {
    String defaultCurrency = 'USD',
  }) {
    if (input == null || input.trim().isEmpty) return defaultCurrency;
    final trimmed = input.trim();
    final upper = trimmed.toUpperCase();

    // 1. Check exact 2-letter ISO code
    for (final c in supportedCountries) {
      if (c.code == upper) return c.currency;
    }

    // 2. If it's already a 3-letter currency code
    if (upper.length == 3) {
      for (final c in supportedCountries) {
        if (c.currency == upper) return upper;
      }
    }

    // 3. Check full country name match
    final lower = trimmed.toLowerCase();
    for (final c in supportedCountries) {
      if (lower.contains(c.name.toLowerCase())) {
        return c.currency;
      }
    }

    // 4. Common city, district, and destination keywords
    // South Korea
    if (lower.contains('korea') ||
        lower.contains('seoul') ||
        lower.contains('busan') ||
        lower.contains('incheon') ||
        lower.contains('jeju') ||
        lower.contains('myeongdong') ||
        lower.contains('gangnam') ||
        lower.contains('hongdae') ||
        lower.contains('itaewon')) {
      return 'KRW';
    }

    // Japan
    if (lower.contains('japan') ||
        lower.contains('tokyo') ||
        lower.contains('osaka') ||
        lower.contains('kyoto') ||
        lower.contains('hokkaido') ||
        lower.contains('sapporo') ||
        lower.contains('fukuoka') ||
        lower.contains('hakone') ||
        lower.contains('okinawa') ||
        lower.contains('shibuya') ||
        lower.contains('shinjuku') ||
        lower.contains('asakusa')) {
      return 'JPY';
    }

    // Hong Kong
    if (lower.contains('hong kong') ||
        lower.contains('hongkong') ||
        lower.contains('kowloon') ||
        lower.contains('tsim sha tsui') ||
        lower.contains('disneyland') ||
        lower.contains('disney') ||
        lower.contains('迪士尼') ||
        lower.contains('mong kok')) {
      return 'HKD';
    }

    // Philippines
    if (lower.contains('philippines') ||
        lower.contains('manila') ||
        lower.contains('taguig') ||
        lower.contains('bgc') ||
        lower.contains('bonifacio') ||
        lower.contains('makati') ||
        lower.contains('cebu') ||
        lower.contains('boracay') ||
        lower.contains('palawan') ||
        lower.contains('el nido') ||
        lower.contains('coron') ||
        lower.contains('davao') ||
        lower.contains('siargao') ||
        lower.contains('bohol') ||
        lower.contains('panglao') ||
        lower.contains('baguio') ||
        lower.contains('pasig') ||
        lower.contains('quezon city')) {
      return 'PHP';
    }

    // Singapore
    if (lower.contains('singapore') ||
        lower.contains('changi') ||
        lower.contains('sentosa') ||
        lower.contains('marina bay')) {
      return 'SGD';
    }

    // Taiwan
    if (lower.contains('taiwan') ||
        lower.contains('taipei') ||
        lower.contains('kaohsiung') ||
        lower.contains('taichung')) {
      return 'TWD';
    }

    // Thailand
    if (lower.contains('thailand') ||
        lower.contains('bangkok') ||
        lower.contains('phuket') ||
        lower.contains('chiang mai') ||
        lower.contains('pattaya') ||
        lower.contains('krabi')) {
      return 'THB';
    }

    // Indonesia
    if (lower.contains('indonesia') ||
        lower.contains('bali') ||
        lower.contains('jakarta') ||
        lower.contains('ubud') ||
        lower.contains('seminyak') ||
        lower.contains('canggu')) {
      return 'IDR';
    }

    // Malaysia
    if (lower.contains('malaysia') ||
        lower.contains('kuala lumpur') ||
        lower.contains('penang')) {
      return 'MYR';
    }

    // United States
    if (lower.contains('united states') ||
        lower.contains('usa') ||
        lower.contains('new york') ||
        lower.contains('los angeles') ||
        lower.contains('san francisco') ||
        lower.contains('hawaii') ||
        lower.contains('california') ||
        lower.contains('las vegas') ||
        lower.contains('orlando')) {
      return 'USD';
    }

    // United Kingdom
    if (lower.contains('united kingdom') ||
        lower.contains('great britain') ||
        lower.contains('england') ||
        lower.contains('london') ||
        lower.contains('scotland') ||
        lower.contains('edinburgh') ||
        lower.contains('manchester')) {
      return 'GBP';
    }

    // Australia
    if (lower.contains('australia') ||
        lower.contains('sydney') ||
        lower.contains('melbourne') ||
        lower.contains('brisbane') ||
        lower.contains('perth')) {
      return 'AUD';
    }

    // UAE
    if (lower.contains('united arab emirates') ||
        lower.contains('uae') ||
        lower.contains('dubai') ||
        lower.contains('abu dhabi')) {
      return 'AED';
    }

    // Vietnam
    if (lower.contains('vietnam') ||
        lower.contains('hanoi') ||
        lower.contains('ho chi minh') ||
        lower.contains('saigon') ||
        lower.contains('da nang')) {
      return 'VND';
    }

    // Europe
    if (lower.contains('france') ||
        lower.contains('paris') ||
        lower.contains('nice') ||
        lower.contains('germany') ||
        lower.contains('berlin') ||
        lower.contains('munich') ||
        lower.contains('frankfurt') ||
        lower.contains('italy') ||
        lower.contains('rome') ||
        lower.contains('milan') ||
        lower.contains('florence') ||
        lower.contains('venice') ||
        lower.contains('spain') ||
        lower.contains('madrid') ||
        lower.contains('barcelona') ||
        lower.contains('netherlands') ||
        lower.contains('amsterdam') ||
        lower.contains('europe') ||
        lower.contains('austria') ||
        lower.contains('vienna')) {
      return 'EUR';
    }

    // Switzerland
    if (lower.contains('switzerland') ||
        lower.contains('zurich') ||
        lower.contains('geneva')) {
      return 'CHF';
    }

    // Canada
    if (lower.contains('canada') ||
        lower.contains('toronto') ||
        lower.contains('vancouver')) {
      return 'CAD';
    }

    return defaultCurrency;
  }

  /// Dynamically resolves the primary trip currency, giving precedence to destination
  /// country/district keywords, trip title, existing expense currencies, and explicit currency.
  static String resolveTripCurrency({
    String? explicitCurrency,
    String? destinationCountry,
    String? title,
    String? budgetCurrency,
    List<String>? expenseCurrencies,
    String defaultCurrency = 'USD',
  }) {
    // 1. Try resolving destinationCountry first (without falling back to default)
    if (destinationCountry != null && destinationCountry.trim().isNotEmpty) {
      final fromDest = resolveCurrency(destinationCountry, defaultCurrency: '');
      if (fromDest.isNotEmpty && fromDest != defaultCurrency) {
        return fromDest;
      }
    }

    // 2. Try resolving trip title next
    if (title != null && title.trim().isNotEmpty) {
      final fromTitle = resolveCurrency(title, defaultCurrency: '');
      if (fromTitle.isNotEmpty && fromTitle != defaultCurrency) {
        return fromTitle;
      }
    }

    // 3. If expenses exist in the trip, inspect what currencies were used
    if (expenseCurrencies != null && expenseCurrencies.isNotEmpty) {
      final counts = <String, int>{};
      for (final cur in expenseCurrencies) {
        final clean = cur.trim().toUpperCase();
        if (clean.isNotEmpty) {
          counts[clean] = (counts[clean] ?? 0) + 1;
        }
      }
      if (counts.isNotEmpty) {
        final sorted = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        if (sorted.first.key.isNotEmpty &&
            sorted.first.key != defaultCurrency) {
          return sorted.first.key;
        }
      }
    }

    // 4. If explicitCurrency is non-empty and non-default, use it
    if (explicitCurrency != null &&
        explicitCurrency.trim().isNotEmpty &&
        explicitCurrency.toUpperCase() != defaultCurrency) {
      return explicitCurrency.toUpperCase();
    }

    // 5. If budget currency is set and non-default, use it
    if (budgetCurrency != null &&
        budgetCurrency.trim().isNotEmpty &&
        budgetCurrency.toUpperCase() != defaultCurrency) {
      return budgetCurrency.toUpperCase();
    }

    // 6. If destinationCountry resolved to something (even if USD for US destinations)
    if (destinationCountry != null && destinationCountry.trim().isNotEmpty) {
      final fromDest = resolveCurrency(destinationCountry, defaultCurrency: '');
      if (fromDest.isNotEmpty) return fromDest;
    }

    // 7. If title resolved to something
    if (title != null && title.trim().isNotEmpty) {
      final fromTitle = resolveCurrency(title, defaultCurrency: '');
      if (fromTitle.isNotEmpty) return fromTitle;
    }

    // 8. If explicitCurrency was provided at all
    if (explicitCurrency != null && explicitCurrency.trim().isNotEmpty) {
      return explicitCurrency.toUpperCase();
    }

    return defaultCurrency;
  }

  static CountryItem? findByCode(String? code) {
    if (code == null) return null;
    final upper = code.toUpperCase();
    for (final c in supportedCountries) {
      if (c.code == upper) return c;
    }
    return null;
  }

  static String? resolveFlag(String? input, {String? fallback}) {
    if (input == null || input.trim().isEmpty) return fallback;
    final trimmed = input.trim();

    // 1. Direct 2-letter ISO country code check
    if (trimmed.length == 2 && RegExp(r'^[a-zA-Z]{2}$').hasMatch(trimmed)) {
      final upper = trimmed.toUpperCase();
      for (final c in supportedCountries) {
        if (c.code == upper) return c.flag;
      }
      try {
        final first = 0x1F1E6 + (upper.codeUnitAt(0) - 65);
        final second = 0x1F1E6 + (upper.codeUnitAt(1) - 65);
        return String.fromCharCode(first) + String.fromCharCode(second);
      } catch (_) {}
    }

    final lower = trimmed.toLowerCase();

    // 2. Direct exact match in supported countries
    for (final c in supportedCountries) {
      if (lower == c.name.toLowerCase() || lower == c.code.toLowerCase()) {
        return c.flag;
      }
    }
    for (final c in supportedCountries) {
      if (lower.contains(c.name.toLowerCase())) {
        return c.flag;
      }
    }

    // 3. Known city/region keywords
    if (lower.contains('tokyo') ||
        lower.contains('osaka') ||
        lower.contains('kyoto') ||
        lower.contains('hokkaido') ||
        lower.contains('fukuoka') ||
        lower.contains('hakone') ||
        lower.contains('sapporo') ||
        lower.contains('okinawa') ||
        lower.contains('shibuya') ||
        lower.contains('shinjuku') ||
        lower.contains('asakusa') ||
        lower.contains('japan')) {
      return '🇯🇵';
    }
    if (lower.contains('hong kong') ||
        lower.contains('hongkong') ||
        lower.contains('kowloon') ||
        lower.contains('tsim sha tsui') ||
        lower.contains('disneyland') ||
        lower.contains('disney') ||
        lower.contains('迪士尼') ||
        lower.contains('mong kok')) {
      return '🇭🇰';
    }
    if (lower.contains('manila') ||
        lower.contains('taguig') ||
        lower.contains('bgc') ||
        lower.contains('bonifacio') ||
        lower.contains('makati') ||
        lower.contains('cebu') ||
        lower.contains('boracay') ||
        lower.contains('palawan') ||
        lower.contains('el nido') ||
        lower.contains('coron') ||
        lower.contains('davao') ||
        lower.contains('siargao') ||
        lower.contains('bohol') ||
        lower.contains('panglao') ||
        lower.contains('baguio') ||
        lower.contains('pasig') ||
        lower.contains('quezon city') ||
        lower.contains('philippines')) {
      return '🇵🇭';
    }
    if (lower.contains('singapore') ||
        lower.contains('changi') ||
        lower.contains('sentosa')) {
      return '🇸🇬';
    }
    if (lower.contains('seoul') ||
        lower.contains('busan') ||
        lower.contains('korea') ||
        lower.contains('incheon') ||
        lower.contains('jeju') ||
        lower.contains('myeongdong') ||
        lower.contains('gangnam') ||
        lower.contains('hongdae') ||
        lower.contains('itaewon')) {
      return '🇰🇷';
    }
    if (lower.contains('paris') ||
        lower.contains('france') ||
        lower.contains('nice') ||
        lower.contains('lyon')) {
      return '🇫🇷';
    }
    if (lower.contains('london') ||
        lower.contains('uk') ||
        lower.contains('england') ||
        lower.contains('scotland') ||
        lower.contains('edinburgh') ||
        lower.contains('manchester')) {
      return '🇬🇧';
    }
    if (lower.contains('bangkok') ||
        lower.contains('phuket') ||
        lower.contains('chiang mai') ||
        lower.contains('pattaya') ||
        lower.contains('krabi') ||
        lower.contains('thailand')) {
      return '🇹🇭';
    }
    if (lower.contains('bali') ||
        lower.contains('jakarta') ||
        lower.contains('ubud') ||
        lower.contains('indonesia')) {
      return '🇮🇩';
    }
    if (lower.contains('sydney') ||
        lower.contains('melbourne') ||
        lower.contains('brisbane') ||
        lower.contains('australia')) {
      return '🇦🇺';
    }
    if (lower.contains('taipei') || lower.contains('taiwan')) {
      return '🇹🇼';
    }
    if (lower.contains('kuala lumpur') || lower.contains('malaysia')) {
      return '🇲🇾';
    }
    if (lower.contains('dubai') || lower.contains('abu dhabi')) {
      return '🇦🇪';
    }
    if (lower.contains('rome') ||
        lower.contains('milan') ||
        lower.contains('florence') ||
        lower.contains('venice') ||
        lower.contains('italy')) {
      return '🇮🇹';
    }
    if (lower.contains('madrid') ||
        lower.contains('barcelona') ||
        lower.contains('spain')) {
      return '🇪🇸';
    }
    if (lower.contains('berlin') ||
        lower.contains('munich') ||
        lower.contains('germany')) {
      return '🇩🇪';
    }
    if (lower.contains('toronto') ||
        lower.contains('vancouver') ||
        lower.contains('canada')) {
      return '🇨🇦';
    }
    if (lower.contains('new york') ||
        lower.contains('los angeles') ||
        lower.contains('hawaii') ||
        lower.contains('california') ||
        lower.contains('san francisco') ||
        lower.contains('usa') ||
        lower.contains('united states')) {
      return '🇺🇸';
    }
    if (lower.contains('hanoi') ||
        lower.contains('saigon') ||
        lower.contains('da nang') ||
        lower.contains('vietnam')) {
      return '🇻🇳';
    }
    if (lower.contains('zurich') ||
        lower.contains('geneva') ||
        lower.contains('switzerland')) {
      return '🇨🇭';
    }

    return fallback;
  }

  static String? resolveTripFlag({
    String? destinationCountry,
    String? title,
    String? fallback,
  }) {
    if (destinationCountry != null && destinationCountry.trim().isNotEmpty) {
      final flag = resolveFlag(destinationCountry);
      if (flag != null) return flag;
    }
    if (title != null && title.trim().isNotEmpty) {
      final flag = resolveFlag(title);
      if (flag != null) return flag;
    }
    return fallback;
  }
}
