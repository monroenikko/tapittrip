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
  /// Comprehensive global list of countries and territories worldwide
  static const List<CountryItem> allCountries = [
    CountryItem(name: 'Afghanistan', code: 'AF', currency: 'AFN', flag: '🇦🇫'),
    CountryItem(name: 'Albania', code: 'AL', currency: 'ALL', flag: '🇦🇱'),
    CountryItem(name: 'Algeria', code: 'DZ', currency: 'DZD', flag: '🇩🇿'),
    CountryItem(name: 'Andorra', code: 'AD', currency: 'EUR', flag: '🇦🇩'),
    CountryItem(name: 'Angola', code: 'AO', currency: 'AOA', flag: '🇦🇴'),
    CountryItem(
      name: 'Antigua and Barbuda',
      code: 'AG',
      currency: 'XCD',
      flag: '🇦🇬',
    ),
    CountryItem(name: 'Argentina', code: 'AR', currency: 'ARS', flag: '🇦🇷'),
    CountryItem(name: 'Armenia', code: 'AM', currency: 'AMD', flag: '🇦🇲'),
    CountryItem(name: 'Aruba', code: 'AW', currency: 'AWG', flag: '🇦🇼'),
    CountryItem(name: 'Australia', code: 'AU', currency: 'AUD', flag: '🇦🇺'),
    CountryItem(name: 'Austria', code: 'AT', currency: 'EUR', flag: '🇦🇹'),
    CountryItem(name: 'Azerbaijan', code: 'AZ', currency: 'AZN', flag: '🇦🇿'),
    CountryItem(name: 'Bahamas', code: 'BS', currency: 'BSD', flag: '🇧🇸'),
    CountryItem(name: 'Bahrain', code: 'BH', currency: 'BHD', flag: '🇧🇭'),
    CountryItem(name: 'Bangladesh', code: 'BD', currency: 'BDT', flag: '🇧🇩'),
    CountryItem(name: 'Barbados', code: 'BB', currency: 'BBD', flag: '🇧🇧'),
    CountryItem(name: 'Belarus', code: 'BY', currency: 'BYN', flag: '🇧🇾'),
    CountryItem(name: 'Belgium', code: 'BE', currency: 'EUR', flag: '🇧🇪'),
    CountryItem(name: 'Belize', code: 'BZ', currency: 'BZD', flag: '🇧🇿'),
    CountryItem(name: 'Benin', code: 'BJ', currency: 'XOF', flag: '🇧🇯'),
    CountryItem(name: 'Bermuda', code: 'BM', currency: 'BMD', flag: '🇧🇲'),
    CountryItem(name: 'Bhutan', code: 'BT', currency: 'BTN', flag: '🇧🇹'),
    CountryItem(name: 'Bolivia', code: 'BO', currency: 'BOB', flag: '🇧🇴'),
    CountryItem(
      name: 'Bosnia and Herzegovina',
      code: 'BA',
      currency: 'BAM',
      flag: '🇧🇦',
    ),
    CountryItem(name: 'Botswana', code: 'BW', currency: 'BWP', flag: '🇧🇼'),
    CountryItem(name: 'Brazil', code: 'BR', currency: 'BRL', flag: '🇧🇷'),
    CountryItem(name: 'Brunei', code: 'BN', currency: 'BND', flag: '🇧🇳'),
    CountryItem(name: 'Bulgaria', code: 'BG', currency: 'BGN', flag: '🇧🇬'),
    CountryItem(
      name: 'Burkina Faso',
      code: 'BF',
      currency: 'XOF',
      flag: '🇧🇫',
    ),
    CountryItem(name: 'Burundi', code: 'BI', currency: 'BIF', flag: '🇧🇮'),
    CountryItem(name: 'Cabo Verde', code: 'CV', currency: 'CVE', flag: '🇨🇻'),
    CountryItem(name: 'Cambodia', code: 'KH', currency: 'KHR', flag: '🇰🇭'),
    CountryItem(name: 'Cameroon', code: 'CM', currency: 'XAF', flag: '🇨🇲'),
    CountryItem(name: 'Canada', code: 'CA', currency: 'CAD', flag: '🇨🇦'),
    CountryItem(
      name: 'Cayman Islands',
      code: 'KY',
      currency: 'KYD',
      flag: '🇰🇾',
    ),
    CountryItem(
      name: 'Central African Republic',
      code: 'CF',
      currency: 'XAF',
      flag: '🇨🇫',
    ),
    CountryItem(name: 'Chad', code: 'TD', currency: 'XAF', flag: '🇹🇩'),
    CountryItem(name: 'Chile', code: 'CL', currency: 'CLP', flag: '🇨🇱'),
    CountryItem(name: 'China', code: 'CN', currency: 'CNY', flag: '🇨🇳'),
    CountryItem(name: 'Colombia', code: 'CO', currency: 'COP', flag: '🇨🇴'),
    CountryItem(name: 'Comoros', code: 'KM', currency: 'KMF', flag: '🇰🇲'),
    CountryItem(name: 'Congo (DRC)', code: 'CD', currency: 'CDF', flag: '🇨🇩'),
    CountryItem(
      name: 'Congo (Republic)',
      code: 'CG',
      currency: 'XAF',
      flag: '🇨🇬',
    ),
    CountryItem(name: 'Costa Rica', code: 'CR', currency: 'CRC', flag: '🇨🇷'),
    CountryItem(name: 'Croatia', code: 'HR', currency: 'EUR', flag: '🇭🇷'),
    CountryItem(name: 'Cuba', code: 'CU', currency: 'CUP', flag: '🇨🇺'),
    CountryItem(name: 'Curaçao', code: 'CW', currency: 'ANG', flag: '🇨🇼'),
    CountryItem(name: 'Cyprus', code: 'CY', currency: 'EUR', flag: '🇨🇾'),
    CountryItem(
      name: 'Czech Republic',
      code: 'CZ',
      currency: 'CZK',
      flag: '🇨🇿',
    ),
    CountryItem(name: 'Denmark', code: 'DK', currency: 'DKK', flag: '🇩🇰'),
    CountryItem(name: 'Djibouti', code: 'DJ', currency: 'DJF', flag: '🇩🇯'),
    CountryItem(name: 'Dominica', code: 'DM', currency: 'XCD', flag: '🇩🇲'),
    CountryItem(
      name: 'Dominican Republic',
      code: 'DO',
      currency: 'DOP',
      flag: '🇩🇴',
    ),
    CountryItem(name: 'Ecuador', code: 'EC', currency: 'USD', flag: '🇪🇨'),
    CountryItem(name: 'Egypt', code: 'EG', currency: 'EGP', flag: '🇪🇬'),
    CountryItem(name: 'El Salvador', code: 'SV', currency: 'USD', flag: '🇸🇻'),
    CountryItem(
      name: 'Equatorial Guinea',
      code: 'GQ',
      currency: 'XAF',
      flag: '🇬🇶',
    ),
    CountryItem(name: 'Eritrea', code: 'ER', currency: 'ERN', flag: '🇪🇷'),
    CountryItem(name: 'Estonia', code: 'EE', currency: 'EUR', flag: '🇪🇪'),
    CountryItem(name: 'Eswatini', code: 'SZ', currency: 'SZL', flag: '🇸🇿'),
    CountryItem(name: 'Ethiopia', code: 'ET', currency: 'ETB', flag: '🇪🇹'),
    CountryItem(
      name: 'Faroe Islands',
      code: 'FO',
      currency: 'DKK',
      flag: '🇫🇴',
    ),
    CountryItem(name: 'Fiji', code: 'FJ', currency: 'FJD', flag: '🇫🇯'),
    CountryItem(name: 'Finland', code: 'FI', currency: 'EUR', flag: '🇫🇮'),
    CountryItem(name: 'France', code: 'FR', currency: 'EUR', flag: '🇫🇷'),
    CountryItem(
      name: 'French Polynesia',
      code: 'PF',
      currency: 'XPF',
      flag: '🇵🇫',
    ),
    CountryItem(name: 'Gabon', code: 'GA', currency: 'XAF', flag: '🇬🇦'),
    CountryItem(name: 'Gambia', code: 'GM', currency: 'GMD', flag: '🇬🇲'),
    CountryItem(name: 'Georgia', code: 'GE', currency: 'GEL', flag: '🇬🇪'),
    CountryItem(name: 'Germany', code: 'DE', currency: 'EUR', flag: '🇩🇪'),
    CountryItem(name: 'Ghana', code: 'GH', currency: 'GHS', flag: '🇬🇭'),
    CountryItem(name: 'Gibraltar', code: 'GI', currency: 'GIP', flag: '🇬🇮'),
    CountryItem(name: 'Greece', code: 'GR', currency: 'EUR', flag: '🇬🇷'),
    CountryItem(name: 'Greenland', code: 'GL', currency: 'DKK', flag: '🇬🇱'),
    CountryItem(name: 'Grenada', code: 'GD', currency: 'XCD', flag: '🇬🇩'),
    CountryItem(name: 'Guam', code: 'GU', currency: 'USD', flag: '🇬🇺'),
    CountryItem(name: 'Guatemala', code: 'GT', currency: 'GTQ', flag: '🇬🇹'),
    CountryItem(name: 'Guernsey', code: 'GG', currency: 'GBP', flag: '🇬🇬'),
    CountryItem(name: 'Guinea', code: 'GN', currency: 'GNF', flag: '🇬🇳'),
    CountryItem(
      name: 'Guinea-Bissau',
      code: 'GW',
      currency: 'XOF',
      flag: '🇬🇼',
    ),
    CountryItem(name: 'Guyana', code: 'GY', currency: 'GYD', flag: '🇬🇾'),
    CountryItem(name: 'Haiti', code: 'HT', currency: 'HTG', flag: '🇭🇹'),
    CountryItem(name: 'Honduras', code: 'HN', currency: 'HNL', flag: '🇭🇳'),
    CountryItem(name: 'Hong Kong', code: 'HK', currency: 'HKD', flag: '🇭🇰'),
    CountryItem(name: 'Hungary', code: 'HU', currency: 'HUF', flag: '🇭🇺'),
    CountryItem(name: 'Iceland', code: 'IS', currency: 'ISK', flag: '🇮🇸'),
    CountryItem(name: 'India', code: 'IN', currency: 'INR', flag: '🇮🇳'),
    CountryItem(name: 'Indonesia', code: 'ID', currency: 'IDR', flag: '🇮🇩'),
    CountryItem(name: 'Iran', code: 'IR', currency: 'IRR', flag: '🇮🇷'),
    CountryItem(name: 'Iraq', code: 'IQ', currency: 'IQD', flag: '🇮🇶'),
    CountryItem(name: 'Ireland', code: 'IE', currency: 'EUR', flag: '🇮🇪'),
    CountryItem(name: 'Isle of Man', code: 'IM', currency: 'GBP', flag: '🇮🇲'),
    CountryItem(name: 'Israel', code: 'IL', currency: 'ILS', flag: '🇮🇱'),
    CountryItem(name: 'Italy', code: 'IT', currency: 'EUR', flag: '🇮🇹'),
    CountryItem(name: 'Ivory Coast', code: 'CI', currency: 'XOF', flag: '🇨🇮'),
    CountryItem(name: 'Jamaica', code: 'JM', currency: 'JMD', flag: '🇯🇲'),
    CountryItem(name: 'Japan', code: 'JP', currency: 'JPY', flag: '🇯🇵'),
    CountryItem(name: 'Jersey', code: 'JE', currency: 'GBP', flag: '🇯🇪'),
    CountryItem(name: 'Jordan', code: 'JO', currency: 'JOD', flag: '🇯🇴'),
    CountryItem(name: 'Kazakhstan', code: 'KZ', currency: 'KZT', flag: '🇰🇿'),
    CountryItem(name: 'Kenya', code: 'KE', currency: 'KES', flag: '🇰🇪'),
    CountryItem(name: 'Kiribati', code: 'KI', currency: 'AUD', flag: '🇰🇮'),
    CountryItem(name: 'Kosovo', code: 'XK', currency: 'EUR', flag: '🇽🇰'),
    CountryItem(name: 'Kuwait', code: 'KW', currency: 'KWD', flag: '🇰🇼'),
    CountryItem(name: 'Kyrgyzstan', code: 'KG', currency: 'KGS', flag: '🇰🇬'),
    CountryItem(name: 'Laos', code: 'LA', currency: 'LAK', flag: '🇱🇦'),
    CountryItem(name: 'Latvia', code: 'LV', currency: 'EUR', flag: '🇱🇻'),
    CountryItem(name: 'Lebanon', code: 'LB', currency: 'LBP', flag: '🇱🇧'),
    CountryItem(name: 'Lesotho', code: 'LS', currency: 'LSL', flag: '🇱🇸'),
    CountryItem(name: 'Liberia', code: 'LR', currency: 'LRD', flag: '🇱🇷'),
    CountryItem(name: 'Libya', code: 'LY', currency: 'LYD', flag: '🇱🇾'),
    CountryItem(
      name: 'Liechtenstein',
      code: 'LI',
      currency: 'CHF',
      flag: '🇱🇮',
    ),
    CountryItem(name: 'Lithuania', code: 'LT', currency: 'EUR', flag: '🇱🇹'),
    CountryItem(name: 'Luxembourg', code: 'LU', currency: 'EUR', flag: '🇱🇺'),
    CountryItem(name: 'Macau', code: 'MO', currency: 'MOP', flag: '🇲🇴'),
    CountryItem(name: 'Madagascar', code: 'MG', currency: 'MGA', flag: '🇲🇬'),
    CountryItem(name: 'Malawi', code: 'MW', currency: 'MWK', flag: '🇲🇼'),
    CountryItem(name: 'Malaysia', code: 'MY', currency: 'MYR', flag: '🇲🇾'),
    CountryItem(name: 'Maldives', code: 'MV', currency: 'MVR', flag: '🇲🇻'),
    CountryItem(name: 'Mali', code: 'ML', currency: 'XOF', flag: '🇲🇱'),
    CountryItem(name: 'Malta', code: 'MT', currency: 'EUR', flag: '🇲🇹'),
    CountryItem(
      name: 'Marshall Islands',
      code: 'MH',
      currency: 'USD',
      flag: '🇲🇭',
    ),
    CountryItem(name: 'Mauritania', code: 'MR', currency: 'MRU', flag: '🇲🇷'),
    CountryItem(name: 'Mauritius', code: 'MU', currency: 'MUR', flag: '🇲🇺'),
    CountryItem(name: 'Mexico', code: 'MX', currency: 'MXN', flag: '🇲🇽'),
    CountryItem(name: 'Micronesia', code: 'FM', currency: 'USD', flag: '🇫🇲'),
    CountryItem(name: 'Moldova', code: 'MD', currency: 'MDL', flag: '🇲🇩'),
    CountryItem(name: 'Monaco', code: 'MC', currency: 'EUR', flag: '🇲🇨'),
    CountryItem(name: 'Mongolia', code: 'MN', currency: 'MNT', flag: '🇲🇳'),
    CountryItem(name: 'Montenegro', code: 'ME', currency: 'EUR', flag: '🇲🇪'),
    CountryItem(name: 'Morocco', code: 'MA', currency: 'MAD', flag: '🇲🇦'),
    CountryItem(name: 'Mozambique', code: 'MZ', currency: 'MZN', flag: '🇲🇿'),
    CountryItem(name: 'Myanmar', code: 'MM', currency: 'MMK', flag: '🇲🇲'),
    CountryItem(name: 'Namibia', code: 'NA', currency: 'NAD', flag: '🇳🇦'),
    CountryItem(name: 'Nauru', code: 'NR', currency: 'AUD', flag: '🇳🇷'),
    CountryItem(name: 'Nepal', code: 'NP', currency: 'NPR', flag: '🇳🇵'),
    CountryItem(name: 'Netherlands', code: 'NL', currency: 'EUR', flag: '🇳🇱'),
    CountryItem(
      name: 'New Caledonia',
      code: 'NC',
      currency: 'XPF',
      flag: '🇳🇨',
    ),
    CountryItem(name: 'New Zealand', code: 'NZ', currency: 'NZD', flag: '🇳🇿'),
    CountryItem(name: 'Nicaragua', code: 'NI', currency: 'NIO', flag: '🇳🇮'),
    CountryItem(name: 'Niger', code: 'NE', currency: 'XOF', flag: '🇳🇪'),
    CountryItem(name: 'Nigeria', code: 'NG', currency: 'NGN', flag: '🇳🇬'),
    CountryItem(name: 'North Korea', code: 'KP', currency: 'KPW', flag: '🇰🇵'),
    CountryItem(
      name: 'North Macedonia',
      code: 'MK',
      currency: 'MKD',
      flag: '🇲🇰',
    ),
    CountryItem(name: 'Norway', code: 'NO', currency: 'NOK', flag: '🇳🇴'),
    CountryItem(name: 'Oman', code: 'OM', currency: 'OMR', flag: '🇴🇲'),
    CountryItem(name: 'Pakistan', code: 'PK', currency: 'PKR', flag: '🇵🇰'),
    CountryItem(name: 'Palau', code: 'PW', currency: 'USD', flag: '🇵🇼'),
    CountryItem(name: 'Palestine', code: 'PS', currency: 'ILS', flag: '🇵🇸'),
    CountryItem(name: 'Panama', code: 'PA', currency: 'PAB', flag: '🇵🇦'),
    CountryItem(
      name: 'Papua New Guinea',
      code: 'PG',
      currency: 'PGK',
      flag: '🇵🇬',
    ),
    CountryItem(name: 'Paraguay', code: 'PY', currency: 'PYG', flag: '🇵🇾'),
    CountryItem(name: 'Peru', code: 'PE', currency: 'PEN', flag: '🇵🇪'),
    CountryItem(name: 'Philippines', code: 'PH', currency: 'PHP', flag: '🇵🇭'),
    CountryItem(name: 'Poland', code: 'PL', currency: 'PLN', flag: '🇵🇱'),
    CountryItem(name: 'Portugal', code: 'PT', currency: 'EUR', flag: '🇵🇹'),
    CountryItem(name: 'Puerto Rico', code: 'PR', currency: 'USD', flag: '🇵🇷'),
    CountryItem(name: 'Qatar', code: 'QA', currency: 'QAR', flag: '🇶🇦'),
    CountryItem(name: 'Romania', code: 'RO', currency: 'RON', flag: '🇷🇴'),
    CountryItem(name: 'Russia', code: 'RU', currency: 'RUB', flag: '🇷🇺'),
    CountryItem(name: 'Rwanda', code: 'RW', currency: 'RWF', flag: '🇷🇼'),
    CountryItem(
      name: 'Saint Kitts and Nevis',
      code: 'KN',
      currency: 'XCD',
      flag: '🇰🇳',
    ),
    CountryItem(name: 'Saint Lucia', code: 'LC', currency: 'XCD', flag: '🇱🇨'),
    CountryItem(
      name: 'Saint Vincent and the Grenadines',
      code: 'VC',
      currency: 'XCD',
      flag: '🇻🇨',
    ),
    CountryItem(name: 'Samoa', code: 'WS', currency: 'WST', flag: '🇼🇸'),
    CountryItem(name: 'San Marino', code: 'SM', currency: 'EUR', flag: '🇸🇲'),
    CountryItem(
      name: 'Sao Tome and Principe',
      code: 'ST',
      currency: 'STN',
      flag: '🇸🇹',
    ),
    CountryItem(
      name: 'Saudi Arabia',
      code: 'SA',
      currency: 'SAR',
      flag: '🇸🇦',
    ),
    CountryItem(name: 'Senegal', code: 'SN', currency: 'XOF', flag: '🇸🇳'),
    CountryItem(name: 'Serbia', code: 'RS', currency: 'RSD', flag: '🇷🇸'),
    CountryItem(name: 'Seychelles', code: 'SC', currency: 'SCR', flag: '🇸🇨'),
    CountryItem(
      name: 'Sierra Leone',
      code: 'SL',
      currency: 'SLE',
      flag: '🇸🇱',
    ),
    CountryItem(name: 'Singapore', code: 'SG', currency: 'SGD', flag: '🇸🇬'),
    CountryItem(name: 'Slovakia', code: 'SK', currency: 'EUR', flag: '🇸🇰'),
    CountryItem(name: 'Slovenia', code: 'SI', currency: 'EUR', flag: '🇸🇮'),
    CountryItem(
      name: 'Solomon Islands',
      code: 'SB',
      currency: 'SBD',
      flag: '🇸🇧',
    ),
    CountryItem(name: 'Somalia', code: 'SO', currency: 'SOS', flag: '🇸🇴'),
    CountryItem(
      name: 'South Africa',
      code: 'ZA',
      currency: 'ZAR',
      flag: '🇿🇦',
    ),
    CountryItem(name: 'South Korea', code: 'KR', currency: 'KRW', flag: '🇰🇷'),
    CountryItem(name: 'South Sudan', code: 'SS', currency: 'SSP', flag: '🇸🇸'),
    CountryItem(name: 'Spain', code: 'ES', currency: 'EUR', flag: '🇪🇸'),
    CountryItem(name: 'Sri Lanka', code: 'LK', currency: 'LKR', flag: '🇱🇰'),
    CountryItem(name: 'Sudan', code: 'SD', currency: 'SDG', flag: '🇸🇩'),
    CountryItem(name: 'Suriname', code: 'SR', currency: 'SRD', flag: '🇸🇷'),
    CountryItem(name: 'Sweden', code: 'SE', currency: 'SEK', flag: '🇸🇪'),
    CountryItem(name: 'Switzerland', code: 'CH', currency: 'CHF', flag: '🇨🇭'),
    CountryItem(name: 'Syria', code: 'SY', currency: 'SYP', flag: '🇸🇾'),
    CountryItem(name: 'Taiwan', code: 'TW', currency: 'TWD', flag: '🇹🇼'),
    CountryItem(name: 'Tajikistan', code: 'TJ', currency: 'TJS', flag: '🇹🇯'),
    CountryItem(name: 'Tanzania', code: 'TZ', currency: 'TZS', flag: '🇹🇿'),
    CountryItem(name: 'Thailand', code: 'TH', currency: 'THB', flag: '🇹🇭'),
    CountryItem(name: 'Timor-Leste', code: 'TL', currency: 'USD', flag: '🇹🇱'),
    CountryItem(name: 'Togo', code: 'TG', currency: 'XOF', flag: '🇹🇬'),
    CountryItem(name: 'Tonga', code: 'TO', currency: 'TOP', flag: '🇹🇴'),
    CountryItem(
      name: 'Trinidad and Tobago',
      code: 'TT',
      currency: 'TTD',
      flag: '🇹🇹',
    ),
    CountryItem(name: 'Tunisia', code: 'TN', currency: 'TND', flag: '🇹🇳'),
    CountryItem(name: 'Turkey', code: 'TR', currency: 'TRY', flag: '🇹🇷'),
    CountryItem(
      name: 'Turkmenistan',
      code: 'TM',
      currency: 'TMT',
      flag: '🇹🇲',
    ),
    CountryItem(name: 'Tuvalu', code: 'TV', currency: 'AUD', flag: '🇹🇻'),
    CountryItem(name: 'Uganda', code: 'UG', currency: 'UGX', flag: '🇺🇬'),
    CountryItem(name: 'Ukraine', code: 'UA', currency: 'UAH', flag: '🇺🇦'),
    CountryItem(
      name: 'United Arab Emirates',
      code: 'AE',
      currency: 'AED',
      flag: '🇦🇪',
    ),
    CountryItem(
      name: 'United Kingdom',
      code: 'GB',
      currency: 'GBP',
      flag: '🇬🇧',
    ),
    CountryItem(
      name: 'United States',
      code: 'US',
      currency: 'USD',
      flag: '🇺🇸',
    ),
    CountryItem(name: 'Uruguay', code: 'UY', currency: 'UYU', flag: '🇺🇾'),
    CountryItem(name: 'Uzbekistan', code: 'UZ', currency: 'UZS', flag: '🇺🇿'),
    CountryItem(name: 'Vanuatu', code: 'VU', currency: 'VUV', flag: '🇻🇺'),
    CountryItem(
      name: 'Vatican City',
      code: 'VA',
      currency: 'EUR',
      flag: '🇻🇦',
    ),
    CountryItem(name: 'Venezuela', code: 'VE', currency: 'VES', flag: '🇻🇪'),
    CountryItem(name: 'Vietnam', code: 'VN', currency: 'VND', flag: '🇻🇳'),
    CountryItem(
      name: 'Virgin Islands (British)',
      code: 'VG',
      currency: 'USD',
      flag: '🇻🇬',
    ),
    CountryItem(
      name: 'Virgin Islands (U.S.)',
      code: 'VI',
      currency: 'USD',
      flag: '🇻🇮',
    ),
    CountryItem(name: 'Yemen', code: 'YE', currency: 'YER', flag: '🇾🇪'),
    CountryItem(name: 'Zambia', code: 'ZM', currency: 'ZMW', flag: '🇿🇲'),
    CountryItem(name: 'Zimbabwe', code: 'ZW', currency: 'ZWG', flag: '🇿🇼'),
  ];

  /// Global supported countries alias across all features
  static const List<CountryItem> supportedCountries = allCountries;

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
