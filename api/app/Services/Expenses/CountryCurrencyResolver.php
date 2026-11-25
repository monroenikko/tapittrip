<?php

declare(strict_types=1);

namespace App\Services\Expenses;

use App\Models\Country;
use Illuminate\Support\Facades\Cache;

final class CountryCurrencyResolver
{
    /**
     * Standard ISO 4217 zero-decimal currencies (currencies where 1 unit is not subdivided into cents).
     *
     * @var list<string>
     */
    public const ZERO_DECIMAL_CURRENCIES = [
        'BIF',
        'CLP',
        'DJF',
        'GNF',
        'ISK',
        'JPY',
        'KMF',
        'KRW',
        'PYG',
        'RWF',
        'UGX',
        'VND',
        'VUV',
        'XAF',
        'XOF',
        'XPF',
    ];

    /**
     * Get the cached lookup map of countries, currencies, and destination aliases.
     *
     * @return array{
     *     codes: array<string, string>,
     *     names: array<string, string>,
     *     aliases: array<string, string>,
     *     zero_decimals: list<string>
     * }
     */
    public static function getLookupMap(): array
    {
        return Cache::rememberForever(Country::CACHE_KEY, function (): array {
            $codes = [];
            $names = [];
            $aliases = [];
            $zeroDecimals = self::ZERO_DECIMAL_CURRENCIES;

            try {
                $countries = Country::query()->get();
            } catch (\Throwable) {
                $countries = collect();
            }

            if ($countries->isEmpty()) {
                $path = database_path('data/countries.json');
                if (file_exists($path)) {
                    $json = json_decode((string) file_get_contents($path), true);
                    if (is_array($json)) {
                        foreach ($json as $item) {
                            $code = strtoupper((string) ($item['code'] ?? ''));
                            $curr = strtoupper((string) ($item['currency_code'] ?? ''));
                            $name = strtolower(trim((string) ($item['name'] ?? '')));
                            if ($code !== '' && $curr !== '') {
                                $codes[$code] = $curr;
                            }
                            if ($name !== '' && $curr !== '') {
                                $names[$name] = $curr;
                            }
                            if (! empty($item['is_zero_decimal']) && ! in_array($curr, $zeroDecimals, true)) {
                                $zeroDecimals[] = $curr;
                            }
                            if (! empty($item['aliases']) && is_array($item['aliases'])) {
                                foreach ($item['aliases'] as $alias) {
                                    $aliases[strtolower(trim((string) $alias))] = $curr;
                                }
                            }
                        }
                    }
                }
            } else {
                foreach ($countries as $country) {
                    $code = strtoupper($country->code);
                    $curr = strtoupper($country->currency_code);
                    $name = strtolower(trim($country->name));

                    $codes[$code] = $curr;
                    $names[$name] = $curr;

                    if ($country->is_zero_decimal && ! in_array($curr, $zeroDecimals, true)) {
                        $zeroDecimals[] = $curr;
                    }

                    if (! empty($country->aliases) && is_array($country->aliases)) {
                        foreach ($country->aliases as $alias) {
                            $aliases[strtolower(trim((string) $alias))] = $curr;
                        }
                    }
                }
            }

            return [
                'codes' => $codes,
                'names' => $names,
                'aliases' => $aliases,
                'zero_decimals' => $zeroDecimals,
            ];
        });
    }

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
        $map = self::getLookupMap();

        // 1. Direct 2-letter ISO country code
        if (isset($map['codes'][$upper])) {
            return $map['codes'][$upper];
        }

        // 2. Direct 3-letter currency code
        if (strlen($upper) === 3 && in_array($upper, $map['codes'], true)) {
            return $upper;
        }

        $lower = strtolower($trimmed);

        // 3. Exact full country name match
        if (isset($map['names'][$lower])) {
            return $map['names'][$lower];
        }

        // 4. Keyword / Alias substring match
        foreach ($map['aliases'] as $keyword => $currency) {
            if (str_contains($lower, $keyword)) {
                return $currency;
            }
        }

        // 5. Country name substring match
        foreach ($map['names'] as $name => $currency) {
            if (str_contains($lower, $name)) {
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
        if (in_array($cur, self::ZERO_DECIMAL_CURRENCIES, true)) {
            return true;
        }

        $map = self::getLookupMap();

        return in_array($cur, $map['zero_decimals'], true);
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
