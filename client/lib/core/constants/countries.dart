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

    // Check code directly
    for (final c in supportedCountries) {
      if (c.code == upper) return c.currency;
    }

    // If it's already a 3-letter currency code
    if (upper.length == 3) {
      for (final c in supportedCountries) {
        if (c.currency == upper) return upper;
      }
    }

    // Check keyword
    final lower = trimmed.toLowerCase();
    for (final c in supportedCountries) {
      if (lower.contains(c.name.toLowerCase()) ||
          lower.contains(c.code.toLowerCase())) {
        return c.currency;
      }
    }

    // Common city/island keywords
    if (lower.contains('tokyo') ||
        lower.contains('osaka') ||
        lower.contains('kyoto')) {
      return 'JPY';
    }
    if (lower.contains('manila') ||
        lower.contains('taguig') ||
        lower.contains('bgc') ||
        lower.contains('makati') ||
        lower.contains('cebu') ||
        lower.contains('boracay') ||
        lower.contains('palawan') ||
        lower.contains('davao') ||
        lower.contains('siargao') ||
        lower.contains('bohol') ||
        lower.contains('baguio') ||
        lower.contains('pasig')) {
      return 'PHP';
    }
    if (lower.contains('paris') ||
        lower.contains('rome') ||
        lower.contains('madrid') ||
        lower.contains('berlin')) {
      return 'EUR';
    }
    if (lower.contains('london')) {
      return 'GBP';
    }
    if (lower.contains('bangkok') || lower.contains('phuket')) {
      return 'THB';
    }
    if (lower.contains('seoul')) {
      return 'KRW';
    }
    if (lower.contains('sydney') || lower.contains('melbourne')) {
      return 'AUD';
    }
    if (lower.contains('bali') || lower.contains('jakarta')) {
      return 'IDR';
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

    // 2. Direct exact or substring match in supported countries
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
        lower.contains('japan')) {
      return '🇯🇵';
    }
    if (lower.contains('hong kong') ||
        lower.contains('hongkong') ||
        lower.contains('kowloon') ||
        lower.contains('disney')) {
      return '🇭🇰';
    }
    if (lower.contains('manila') ||
        lower.contains('taguig') ||
        lower.contains('bgc') ||
        lower.contains('makati') ||
        lower.contains('cebu') ||
        lower.contains('boracay') ||
        lower.contains('palawan') ||
        lower.contains('davao') ||
        lower.contains('siargao') ||
        lower.contains('bohol') ||
        lower.contains('baguio') ||
        lower.contains('pasig') ||
        lower.contains('philippines')) {
      return '🇵🇭';
    }
    if (lower.contains('singapore') || lower.contains('changi')) {
      return '🇸🇬';
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
        lower.contains('scotland')) {
      return '🇬🇧';
    }
    if (lower.contains('bangkok') ||
        lower.contains('phuket') ||
        lower.contains('chiang mai') ||
        lower.contains('thailand')) {
      return '🇹🇭';
    }
    if (lower.contains('seoul') ||
        lower.contains('busan') ||
        lower.contains('korea') ||
        lower.contains('incheon')) {
      return '🇰🇷';
    }
    if (lower.contains('bali') ||
        lower.contains('jakarta') ||
        lower.contains('indonesia')) {
      return '🇮🇩';
    }
    if (lower.contains('sydney') ||
        lower.contains('melbourne') ||
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
}
