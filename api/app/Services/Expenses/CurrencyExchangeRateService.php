<?php

declare(strict_types=1);

namespace App\Services\Expenses;

use App\Contracts\ExchangeRateProviderInterface;
use App\DTOs\Expenses\ExchangeRateData;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;

final class CurrencyExchangeRateService
{
    public function __construct(
        private ExchangeRateProviderInterface $provider,
    ) {}

    /**
     * Get the exchange rate and reciprocal rate for a currency pair with caching.
     */
    public function getRate(string $fromCurrency, string $toCurrency): ExchangeRateData
    {
        $from = strtoupper(trim($fromCurrency));
        $to = strtoupper(trim($toCurrency));

        if ($from === $to) {
            return new ExchangeRateData(
                from: $from,
                to: $to,
                rate: 1.0,
                reciprocalRate: 1.0,
                asOf: Carbon::now()->toIso8601String(),
                provider: 'identity',
            );
        }

        $cacheKey = "forex_rate_{$from}_{$to}";
        $cached = Cache::get($cacheKey);
        if (is_array($cached) && isset($cached['rate']) && is_numeric($cached['rate']) && (float) $cached['rate'] > 0) {
            $rate = (float) $cached['rate'];
            $reciprocalRate = round(1.0 / $rate, 6);

            return new ExchangeRateData(
                from: $from,
                to: $to,
                rate: $rate,
                reciprocalRate: $reciprocalRate,
                asOf: (string) ($cached['as_of'] ?? Carbon::now()->toIso8601String()),
                provider: $this->provider instanceof FakeExchangeRateProvider ? 'fake' : 'open_exchange_rates',
                available: true,
            );
        }

        $rate = $this->provider->getRate($from, $to);
        if ($rate === null || $rate <= 0) {
            return new ExchangeRateData(
                from: $from,
                to: $to,
                rate: null,
                reciprocalRate: null,
                asOf: Carbon::now()->toIso8601String(),
                provider: 'unavailable',
                available: false,
            );
        }

        $asOf = Carbon::now()->toIso8601String();
        Cache::put($cacheKey, ['rate' => $rate, 'as_of' => $asOf], 3600);

        $reciprocalRate = round(1.0 / $rate, 6);

        return new ExchangeRateData(
            from: $from,
            to: $to,
            rate: (float) $rate,
            reciprocalRate: (float) $reciprocalRate,
            asOf: $asOf,
            provider: $this->provider instanceof FakeExchangeRateProvider ? 'fake' : 'open_exchange_rates',
            available: true,
        );
    }
}
