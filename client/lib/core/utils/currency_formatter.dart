class CurrencyFormatter {
  CurrencyFormatter._();

  /// Resolve the display symbol for an ISO 4217 currency code.
  static String symbol(String? currency) {
    if (currency == null || currency.trim().isEmpty) return '\$';
    switch (currency.trim().toUpperCase()) {
      case 'USD':
      case 'CAD':
      case 'AUD':
      case 'NZD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'PHP':
        return '₱';
      case 'SGD':
        return 'S\$';
      case 'HKD':
        return 'HK\$';
      case 'TWD':
        return 'NT\$';
      case 'THB':
        return '฿';
      case 'KRW':
        return '₩';
      case 'IDR':
        return 'Rp ';
      case 'MYR':
        return 'RM ';
      case 'AED':
        return 'AED ';
      case 'CHF':
        return 'CHF ';
      case 'VND':
        return '₫';
      default:
        return '$currency ';
    }
  }

  /// Whether the currency does not use decimal fractions (cents).
  static bool isZeroDecimal(String? currency) {
    if (currency == null) return false;
    final cur = currency.trim().toUpperCase();
    return cur == 'JPY' || cur == 'KRW' || cur == 'VND';
  }

  /// Format an amount into a localized currency string.
  /// If [isMinor] is true, non-zero decimal currencies will be divided by 100.
  /// If [trimZeroCents] is true, whole currency values will omit '.00' (e.g. '$35').
  static String formatAmount(
    num amount,
    String? currency, {
    bool isMinor = false,
    bool trimZeroCents = false,
  }) {
    final cur = (currency == null || currency.trim().isEmpty)
        ? 'USD'
        : currency.trim().toUpperCase();
    final sym = symbol(cur);
    final zeroDec = isZeroDecimal(cur);
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    if (zeroDec) {
      final whole = absAmount.round();
      return '${isNegative ? '-' : ''}$sym$whole';
    } else {
      final value = isMinor ? (absAmount / 100.0) : absAmount.toDouble();
      if (trimZeroCents && value.truncateToDouble() == value) {
        return '${isNegative ? '-' : ''}$sym${value.toInt()}';
      }
      return '${isNegative ? '-' : ''}$sym${value.toStringAsFixed(2)}';
    }
  }

  /// Formats both the primary currency amount and its converted equivalent in [toCurrency].
  /// Example: "¥18,500 (≈ ₱7,364.85)"
  static String formatDual({
    required num amount,
    required String fromCurrency,
    required String toCurrency,
    required double rate,
    bool isMinor = false,
  }) {
    final primary = formatAmount(amount, fromCurrency, isMinor: isMinor);
    if (fromCurrency.trim().toUpperCase() == toCurrency.trim().toUpperCase()) {
      return primary;
    }
    final fromZero = isZeroDecimal(fromCurrency);
    final fromUnits = isMinor
        ? (fromZero ? amount.toDouble() : amount / 100.0)
        : amount.toDouble();
    final toUnits = fromUnits * rate;
    final secondary = formatAmount(toUnits, toCurrency, isMinor: false);
    return '$primary (≈ $secondary)';
  }

  static String _commaSeparate(String s) {
    return s.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
