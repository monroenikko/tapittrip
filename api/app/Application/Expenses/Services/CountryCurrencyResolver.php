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
        'philippines' => 'PHP',
        'manila' => 'PHP',
        'taguig' => 'PHP',
        'bgc' => 'PHP',
        'makati' => 'PHP',
        'cebu' => 'PHP',
        'boracay' => 'PHP',
        'palawan' => 'PHP',
        'davao' => 'PHP',
        'siargao' => 'PHP',
        'bohol' => 'PHP',
        'baguio' => 'PHP',
        'pasig' => 'PHP',
        'quezon city' => 'PHP',
        'japan' => 'JPY',
        'tokyo' => 'JPY',
        'osaka' => 'JPY',
        'kyoto' => 'JPY',
        'hokkaido' => 'JPY',
        'united states' => 'USD',
        'usa' => 'USD',
        'new york' => 'USD',
        'los angeles' => 'USD',
        'san francisco' => 'USD',
        'hawaii' => 'USD',
        'singapore' => 'SGD',
        'united kingdom' => 'GBP',
        'great britain' => 'GBP',
        'england' => 'GBP',
        'london' => 'GBP',
        'scotland' => 'GBP',
        'australia' => 'AUD',
        'sydney' => 'AUD',
        'melbourne' => 'AUD',
        'thailand' => 'THB',
        'bangkok' => 'THB',
        'phuket' => 'THB',
        'chiang mai' => 'THB',
        'south korea' => 'KRW',
        'korea' => 'KRW',
        'seoul' => 'KRW',
        'busan' => 'KRW',
        'canada' => 'CAD',
        'toronto' => 'CAD',
        'vancouver' => 'CAD',
        'hong kong' => 'HKD',
        'taiwan' => 'TWD',
        'taipei' => 'TWD',
        'indonesia' => 'IDR',
        'bali' => 'IDR',
        'jakarta' => 'IDR',
        'malaysia' => 'MYR',
        'kuala lumpur' => 'MYR',
        'united arab emirates' => 'AED',
        'uae' => 'AED',
        'dubai' => 'AED',
        'abu dhabi' => 'AED',
        'vietnam' => 'VND',
        'hanoi' => 'VND',
        'ho chi minh' => 'VND',
        'france' => 'EUR',
        'paris' => 'EUR',
        'germany' => 'EUR',
        'berlin' => 'EUR',
        'munich' => 'EUR',
        'frankfurt' => 'EUR',
        'italy' => 'EUR',
        'rome' => 'EUR',
        'milan' => 'EUR',
        'florence' => 'EUR',
        'spain' => 'EUR',
        'madrid' => 'EUR',
        'barcelona' => 'EUR',
        'netherlands' => 'EUR',
        'amsterdam' => 'EUR',
        'europe' => 'EUR',
        'switzerland' => 'CHF',
        'zurich' => 'CHF',
        'geneva' => 'CHF',
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
