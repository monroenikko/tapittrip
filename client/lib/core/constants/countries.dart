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
    CountryItem(name: 'United States', code: 'US', currency: 'USD', flag: '🇺🇸'),
    CountryItem(name: 'Singapore', code: 'SG', currency: 'SGD', flag: '🇸🇬'),
    CountryItem(name: 'United Kingdom', code: 'GB', currency: 'GBP', flag: '🇬🇧'),
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
    CountryItem(name: 'United Arab Emirates', code: 'AE', currency: 'AED', flag: '🇦🇪'),
    CountryItem(name: 'Vietnam', code: 'VN', currency: 'VND', flag: '🇻🇳'),
    CountryItem(name: 'Switzerland', code: 'CH', currency: 'CHF', flag: '🇨🇭'),
  ];

  static String resolveCurrency(String? input, {String defaultCurrency = 'USD'}) {
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
      if (lower.contains(c.name.toLowerCase()) || lower.contains(c.code.toLowerCase())) {
        return c.currency;
      }
    }

    // Common city/island keywords
    if (lower.contains('tokyo') || lower.contains('osaka') || lower.contains('kyoto')) {
      return 'JPY';
    }
    if (lower.contains('manila') || lower.contains('cebu') || lower.contains('boracay')) {
      return 'PHP';
    }
    if (lower.contains('paris') || lower.contains('rome') || lower.contains('madrid') || lower.contains('berlin')) {
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
}
