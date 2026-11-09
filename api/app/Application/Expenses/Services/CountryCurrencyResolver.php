<?php

declare(strict_types=1);

namespace App\Application\Expenses\Services;

final class CountryCurrencyResolver
{
    /**
     * Map of ISO 3166-1 alpha-2 country codes to primary ISO 4217 currencies.
     *
     * @var array<string, string>
     */
    private const COUNTRY_CODE_TO_CURRENCY = [
        'AF' => 'AFN',
        'AL' => 'ALL',
        'DZ' => 'DZD',
        'AD' => 'EUR',
        'AO' => 'AOA',
        'AG' => 'XCD',
        'AR' => 'ARS',
        'AM' => 'AMD',
        'AW' => 'AWG',
        'AU' => 'AUD',
        'AT' => 'EUR',
        'AZ' => 'AZN',
        'BS' => 'BSD',
        'BH' => 'BHD',
        'BD' => 'BDT',
        'BB' => 'BBD',
        'BY' => 'BYN',
        'BE' => 'EUR',
        'BZ' => 'BZD',
        'BJ' => 'XOF',
        'BM' => 'BMD',
        'BT' => 'BTN',
        'BO' => 'BOB',
        'BA' => 'BAM',
        'BW' => 'BWP',
        'BR' => 'BRL',
        'BN' => 'BND',
        'BG' => 'BGN',
        'BF' => 'XOF',
        'BI' => 'BIF',
        'CV' => 'CVE',
        'KH' => 'KHR',
        'CM' => 'XAF',
        'CA' => 'CAD',
        'KY' => 'KYD',
        'CF' => 'XAF',
        'TD' => 'XAF',
        'CL' => 'CLP',
        'CN' => 'CNY',
        'CO' => 'COP',
        'KM' => 'KMF',
        'CD' => 'CDF',
        'CG' => 'XAF',
        'CR' => 'CRC',
        'HR' => 'EUR',
        'CU' => 'CUP',
        'CW' => 'ANG',
        'CY' => 'EUR',
        'CZ' => 'CZK',
        'DK' => 'DKK',
        'DJ' => 'DJF',
        'DM' => 'XCD',
        'DO' => 'DOP',
        'EC' => 'USD',
        'EG' => 'EGP',
        'SV' => 'USD',
        'GQ' => 'XAF',
        'ER' => 'ERN',
        'EE' => 'EUR',
        'SZ' => 'SZL',
        'ET' => 'ETB',
        'FO' => 'DKK',
        'FJ' => 'FJD',
        'FI' => 'EUR',
        'FR' => 'EUR',
        'PF' => 'XPF',
        'GA' => 'XAF',
        'GM' => 'GMD',
        'GE' => 'GEL',
        'DE' => 'EUR',
        'GH' => 'GHS',
        'GI' => 'GIP',
        'GR' => 'EUR',
        'GL' => 'DKK',
        'GD' => 'XCD',
        'GU' => 'USD',
        'GT' => 'GTQ',
        'GG' => 'GBP',
        'GN' => 'GNF',
        'GW' => 'XOF',
        'GY' => 'GYD',
        'HT' => 'HTG',
        'HN' => 'HNL',
        'HK' => 'HKD',
        'HU' => 'HUF',
        'IS' => 'ISK',
        'IN' => 'INR',
        'ID' => 'IDR',
        'IR' => 'IRR',
        'IQ' => 'IQD',
        'IE' => 'EUR',
        'IM' => 'GBP',
        'IL' => 'ILS',
        'IT' => 'EUR',
        'CI' => 'XOF',
        'JM' => 'JMD',
        'JP' => 'JPY',
        'JE' => 'GBP',
        'JO' => 'JOD',
        'KZ' => 'KZT',
        'KE' => 'KES',
        'KI' => 'AUD',
        'XK' => 'EUR',
        'KW' => 'KWD',
        'KG' => 'KGS',
        'LA' => 'LAK',
        'LV' => 'EUR',
        'LB' => 'LBP',
        'LS' => 'LSL',
        'LR' => 'LRD',
        'LY' => 'LYD',
        'LI' => 'CHF',
        'LT' => 'EUR',
        'LU' => 'EUR',
        'MO' => 'MOP',
        'MG' => 'MGA',
        'MW' => 'MWK',
        'MY' => 'MYR',
        'MV' => 'MVR',
        'ML' => 'XOF',
        'MT' => 'EUR',
        'MH' => 'USD',
        'MR' => 'MRU',
        'MU' => 'MUR',
        'MX' => 'MXN',
        'FM' => 'USD',
        'MD' => 'MDL',
        'MC' => 'EUR',
        'MN' => 'MNT',
        'ME' => 'EUR',
        'MA' => 'MAD',
        'MZ' => 'MZN',
        'MM' => 'MMK',
        'NA' => 'NAD',
        'NR' => 'AUD',
        'NP' => 'NPR',
        'NL' => 'EUR',
        'NC' => 'XPF',
        'NZ' => 'NZD',
        'NI' => 'NIO',
        'NE' => 'XOF',
        'NG' => 'NGN',
        'KP' => 'KPW',
        'MK' => 'MKD',
        'NO' => 'NOK',
        'OM' => 'OMR',
        'PK' => 'PKR',
        'PW' => 'USD',
        'PS' => 'ILS',
        'PA' => 'PAB',
        'PG' => 'PGK',
        'PY' => 'PYG',
        'PE' => 'PEN',
        'PH' => 'PHP',
        'PL' => 'PLN',
        'PT' => 'EUR',
        'PR' => 'USD',
        'QA' => 'QAR',
        'RO' => 'RON',
        'RU' => 'RUB',
        'RW' => 'RWF',
        'KN' => 'XCD',
        'LC' => 'XCD',
        'VC' => 'XCD',
        'WS' => 'WST',
        'SM' => 'EUR',
        'ST' => 'STN',
        'SA' => 'SAR',
        'SN' => 'XOF',
        'RS' => 'RSD',
        'SC' => 'SCR',
        'SL' => 'SLE',
        'SG' => 'SGD',
        'SK' => 'EUR',
        'SI' => 'EUR',
        'SB' => 'SBD',
        'SO' => 'SOS',
        'ZA' => 'ZAR',
        'KR' => 'KRW',
        'SS' => 'SSP',
        'ES' => 'EUR',
        'LK' => 'LKR',
        'SD' => 'SDG',
        'SR' => 'SRD',
        'SE' => 'SEK',
        'CH' => 'CHF',
        'SY' => 'SYP',
        'TW' => 'TWD',
        'TJ' => 'TJS',
        'TZ' => 'TZS',
        'TH' => 'THB',
        'TL' => 'USD',
        'TG' => 'XOF',
        'TO' => 'TOP',
        'TT' => 'TTD',
        'TN' => 'TND',
        'TR' => 'TRY',
        'TM' => 'TMT',
        'TV' => 'AUD',
        'UG' => 'UGX',
        'UA' => 'UAH',
        'AE' => 'AED',
        'GB' => 'GBP',
        'US' => 'USD',
        'UY' => 'UYU',
        'UZ' => 'UZS',
        'VU' => 'VUV',
        'VA' => 'EUR',
        'VE' => 'VES',
        'VN' => 'VND',
        'VG' => 'USD',
        'VI' => 'USD',
        'YE' => 'YER',
        'ZM' => 'ZMW',
        'ZW' => 'ZWG',
    ];

    /**
     * Map of common location keywords and destination strings to currencies.
     *
     * @var array<string, string>
     */
    private const KEYWORD_TO_CURRENCY = [
        // Philippines
        'philippines' => 'PHP',
        'manila' => 'PHP',
        'taguig' => 'PHP',
        'bgc' => 'PHP',
        'bonifacio' => 'PHP',
        'makati' => 'PHP',
        'cebu' => 'PHP',
        'boracay' => 'PHP',
        'palawan' => 'PHP',
        'el nido' => 'PHP',
        'coron' => 'PHP',
        'davao' => 'PHP',
        'siargao' => 'PHP',
        'bohol' => 'PHP',
        'panglao' => 'PHP',
        'baguio' => 'PHP',
        'pasig' => 'PHP',
        'quezon city' => 'PHP',

        // Japan
        'japan' => 'JPY',
        'tokyo' => 'JPY',
        'osaka' => 'JPY',
        'kyoto' => 'JPY',
        'hokkaido' => 'JPY',
        'sapporo' => 'JPY',
        'fukuoka' => 'JPY',
        'hakone' => 'JPY',
        'okinawa' => 'JPY',
        'shibuya' => 'JPY',
        'shinjuku' => 'JPY',
        'asakusa' => 'JPY',

        // South Korea
        'south korea' => 'KRW',
        'korea' => 'KRW',
        'seoul' => 'KRW',
        'busan' => 'KRW',
        'incheon' => 'KRW',
        'jeju' => 'KRW',
        'myeongdong' => 'KRW',
        'gangnam' => 'KRW',
        'hongdae' => 'KRW',
        'itaewon' => 'KRW',

        // Hong Kong
        'hong kong' => 'HKD',
        'hongkong' => 'HKD',
        'kowloon' => 'HKD',
        'tsim sha tsui' => 'HKD',
        'disneyland' => 'HKD',
        'disney' => 'HKD',
        '迪士尼' => 'HKD',
        'mong kok' => 'HKD',

        // Singapore
        'singapore' => 'SGD',
        'changi' => 'SGD',
        'sentosa' => 'SGD',

        // Taiwan
        'taiwan' => 'TWD',
        'taipei' => 'TWD',
        'kaohsiung' => 'TWD',

        // Thailand
        'thailand' => 'THB',
        'bangkok' => 'THB',
        'phuket' => 'THB',
        'chiang mai' => 'THB',
        'pattaya' => 'THB',
        'krabi' => 'THB',

        // Indonesia
        'indonesia' => 'IDR',
        'bali' => 'IDR',
        'jakarta' => 'IDR',
        'ubud' => 'IDR',
        'seminyak' => 'IDR',
        'canggu' => 'IDR',

        // Malaysia
        'malaysia' => 'MYR',
        'kuala lumpur' => 'MYR',
        'penang' => 'MYR',

        // United States
        'united states' => 'USD',
        'usa' => 'USD',
        'new york' => 'USD',
        'los angeles' => 'USD',
        'san francisco' => 'USD',
        'hawaii' => 'USD',
        'california' => 'USD',
        'las vegas' => 'USD',
        'orlando' => 'USD',

        // United Kingdom
        'united kingdom' => 'GBP',
        'great britain' => 'GBP',
        'england' => 'GBP',
        'london' => 'GBP',
        'scotland' => 'GBP',
        'edinburgh' => 'GBP',
        'manchester' => 'GBP',

        // Australia
        'australia' => 'AUD',
        'sydney' => 'AUD',
        'melbourne' => 'AUD',
        'brisbane' => 'AUD',
        'perth' => 'AUD',

        // UAE
        'united arab emirates' => 'AED',
        'uae' => 'AED',
        'dubai' => 'AED',
        'abu dhabi' => 'AED',

        // Vietnam
        'vietnam' => 'VND',
        'hanoi' => 'VND',
        'ho chi minh' => 'VND',
        'saigon' => 'VND',
        'da nang' => 'VND',

        // Europe
        'france' => 'EUR',
        'paris' => 'EUR',
        'nice' => 'EUR',
        'germany' => 'EUR',
        'berlin' => 'EUR',
        'munich' => 'EUR',
        'frankfurt' => 'EUR',
        'italy' => 'EUR',
        'rome' => 'EUR',
        'milan' => 'EUR',
        'florence' => 'EUR',
        'venice' => 'EUR',
        'spain' => 'EUR',
        'madrid' => 'EUR',
        'barcelona' => 'EUR',
        'netherlands' => 'EUR',
        'amsterdam' => 'EUR',
        'europe' => 'EUR',
        'austria' => 'EUR',
        'vienna' => 'EUR',

        // Switzerland
        'switzerland' => 'CHF',
        'zurich' => 'CHF',
        'geneva' => 'CHF',

        // Canada
        'canada' => 'CAD',
        'toronto' => 'CAD',
        'vancouver' => 'CAD',
    ];

    /**
     * Resolve currency for a country code, destination name, or location query.
     */
    public static function resolve(?string $locationOrCountryCode, string $default = 'USD'): string
    {
        if ($locationOrCountryCode === null || trim($locationOrCountryCode) === '') {
            return $default;
        }

        $trimmed = trim($locationOrCountryCode);
        $upper = strtoupper($trimmed);

        // Check direct 2-letter ISO country code
        if (isset(self::COUNTRY_CODE_TO_CURRENCY[$upper])) {
            return self::COUNTRY_CODE_TO_CURRENCY[$upper];
        }

        // If it's already a 3-letter currency code, return it
        if (strlen($upper) === 3 && in_array($upper, array_values(self::COUNTRY_CODE_TO_CURRENCY), true)) {
            return $upper;
        }

        // Check substring keyword matches
        $lower = strtolower($trimmed);
        foreach (self::KEYWORD_TO_CURRENCY as $keyword => $currency) {
            if (str_contains($lower, $keyword)) {
                return $currency;
            }
        }

        return $default;
    }

    /**
     * Resolve currency for a trip, checking destination country first, then title.
     */
    public static function resolveTripCurrency(?string $destinationCountry, ?string $title = null, string $default = 'USD'): string
    {
        if ($destinationCountry !== null && trim($destinationCountry) !== '') {
            $currency = self::resolve($destinationCountry, '');
            if ($currency !== '') {
                return $currency;
            }
        }

        if ($title !== null && trim($title) !== '') {
            $currency = self::resolve($title, '');
            if ($currency !== '') {
                return $currency;
            }
        }

        return $default;
    }

    /**
     * Check whether an ISO 4217 currency is zero-decimal (no fractional cents).
     */
    public static function isZeroDecimal(string $currency): bool
    {
        $cur = strtoupper(trim($currency));

        return in_array($cur, ['JPY', 'KRW', 'VND'], true);
    }

    /**
     * Accurately convert an amount from one currency to another in minor integer units,
     * accounting for zero-decimal vs fractional (cents) currency scales.
     */
    public static function convertAmountMinor(
        int $amountMinor,
        string $fromCurrency,
        string $toCurrency,
        float $exchangeRate,
    ): int {
        $from = strtoupper(trim($fromCurrency));
        $to = strtoupper(trim($toCurrency));

        if ($from === $to) {
            return $amountMinor;
        }

        $rate = $exchangeRate > 0 ? $exchangeRate : 1.0;

        // Step 1: Normalize source amount to major units
        $sourceMajor = self::isZeroDecimal($from)
            ? (float) $amountMinor
            : ($amountMinor / 100.0);

        // Step 2: Convert using exchange rate
        $targetMajor = $sourceMajor * $rate;

        // Step 3: Convert to target currency's minor units
        return self::isZeroDecimal($to)
            ? (int) round($targetMajor)
            : (int) round($targetMajor * 100.0);
    }
}
