<?php

declare(strict_types=1);

namespace App\Application\Expenses\Services;

use App\Application\Expenses\Contracts\ExchangeRateProviderInterface;
use App\Application\Expenses\Data\ExchangeRateData;
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

        /** @var float $rate */
        $rate = Cache::remember($cacheKey, 3600, function () use ($from, $to) {
            return $this->provider->getRate($from, $to);
        });

        $reciprocalRate = $rate > 0 ? round(1.0 / $rate, 6) : 0.0;

        return new ExchangeRateData(
            from: $from,
            to: $to,
            rate: $rate,
            reciprocalRate: $reciprocalRate,
            asOf: Carbon::now()->toIso8601String(),
            provider: $this->provider instanceof FakeExchangeRateProvider ? 'fake' : 'open_exchange_rates',
        );
    }
}
