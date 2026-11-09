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
        'PH' => 'PHP',
        'JP' => 'JPY',
        'US' => 'USD',
        'SG' => 'SGD',
        'GB' => 'GBP',
        'AU' => 'AUD',
        'TH' => 'THB',
        'KR' => 'KRW',
        'CA' => 'CAD',
        'HK' => 'HKD',
        'TW' => 'TWD',
        'ID' => 'IDR',
        'MY' => 'MYR',
        'AE' => 'AED',
        'VN' => 'VND',
        'CH' => 'CHF',
        'NZ' => 'NZD',
        // Eurozone
        'FR' => 'EUR',
        'DE' => 'EUR',
        'IT' => 'EUR',
        'ES' => 'EUR',
        'NL' => 'EUR',
        'BE' => 'EUR',
        'AT' => 'EUR',
        'PT' => 'EUR',
        'GR' => 'EUR',
        'IE' => 'EUR',
        'FI' => 'EUR',
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
