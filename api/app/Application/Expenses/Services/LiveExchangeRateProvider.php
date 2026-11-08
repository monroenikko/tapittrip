<?php

declare(strict_types=1);

namespace App\Application\Expenses\Services;

use App\Application\Expenses\Contracts\ExchangeRateProviderInterface;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

final class LiveExchangeRateProvider implements ExchangeRateProviderInterface
{
    private FakeExchangeRateProvider $fallbackProvider;

    public function __construct(?FakeExchangeRateProvider $fallbackProvider = null)
    {
        $this->fallbackProvider = $fallbackProvider ?? new FakeExchangeRateProvider;
    }

    public function getRate(string $fromCurrency, string $toCurrency): float
    {
        $from = strtoupper(trim($fromCurrency));
        $to = strtoupper(trim($toCurrency));

        if ($from === $to) {
            return 1.0;
        }

        try {
            $response = Http::timeout(3)
                ->retry(2, 100)
                ->get("https://open.er-api.com/v6/latest/{$from}");

            if ($response->successful()) {
                $data = $response->json();
                if (isset($data['rates'][$to]) && is_numeric($data['rates'][$to])) {
                    return (float) $data['rates'][$to];
                }
            }
        } catch (\Throwable $e) {
            Log::warning("LiveExchangeRateProvider failed to fetch live rate for {$from}->{$to}: ".$e->getMessage());
        }

        return $this->fallbackProvider->getRate($from, $to);
    }

    public function getRatesForBase(string $baseCurrency): array
    {
        $base = strtoupper(trim($baseCurrency));

        try {
            $response = Http::timeout(3)
                ->retry(2, 100)
                ->get("https://open.er-api.com/v6/latest/{$base}");

            if ($response->successful()) {
                $data = $response->json();
                if (isset($data['rates']) && is_array($data['rates'])) {
                    $rates = [];
                    foreach ($data['rates'] as $curr => $rate) {
                        if (is_numeric($rate)) {
                            $rates[(string) $curr] = (float) $rate;
                        }
                    }

                    return $rates;
                }
            }
        } catch (\Throwable $e) {
            Log::warning("LiveExchangeRateProvider failed to fetch rates for {$base}: ".$e->getMessage());
        }

        return $this->fallbackProvider->getRatesForBase($base);
    }
}
