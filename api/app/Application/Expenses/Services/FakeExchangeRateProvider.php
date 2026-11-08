<?php

declare(strict_types=1);

namespace App\Application\Expenses\Services;

use App\Application\Expenses\Contracts\ExchangeRateProviderInterface;

final class FakeExchangeRateProvider implements ExchangeRateProviderInterface
{
    /**
     * Standard deterministic exchange rates based on USD.
     *
     * @var array<string, float>
     */
    private const RATES_TO_USD = [
        'USD' => 1.0,
        'PHP' => 58.50,
        'JPY' => 154.00,
        'EUR' => 0.92,
        'GBP' => 0.78,
        'SGD' => 1.33,
        'AUD' => 1.52,
        'THB' => 34.20,
        'KRW' => 1380.0,
        'CAD' => 1.39,
        'HKD' => 7.78,
        'TWD' => 32.10,
        'IDR' => 15700.0,
        'MYR' => 4.40,
        'AED' => 3.67,
        'CHF' => 0.88,
    ];

    /**
     * @var array<string, float>
     */
    private array $customRates = [];

    public function setCustomRate(string $from, string $to, float $rate): void
    {
        $this->customRates[strtoupper($from).'_'.strtoupper($to)] = $rate;
    }

    public function getRate(string $fromCurrency, string $toCurrency): float
    {
        $from = strtoupper(trim($fromCurrency));
        $to = strtoupper(trim($toCurrency));

        if ($from === $to) {
            return 1.0;
        }

        $customKey = "{$from}_{$to}";
        if (isset($this->customRates[$customKey])) {
            return $this->customRates[$customKey];
        }

        $invKey = "{$to}_{$from}";
        if (isset($this->customRates[$invKey])) {
            return round(1.0 / $this->customRates[$invKey], 6);
        }

        // Specific high-frequency test pair overrides
        if ($from === 'JPY' && $to === 'PHP') {
            return 0.3800;
        }
        if ($from === 'PHP' && $to === 'JPY') {
            return round(1.0 / 0.3800, 4);
        }

        $fromUsdRate = self::RATES_TO_USD[$from] ?? 1.0;
        $toUsdRate = self::RATES_TO_USD[$to] ?? 1.0;

        return round($toUsdRate / $fromUsdRate, 6);
    }

    public function getRatesForBase(string $baseCurrency): array
    {
        $base = strtoupper(trim($baseCurrency));
        $rates = [];

        foreach (array_keys(self::RATES_TO_USD) as $curr) {
            $rates[$curr] = $this->getRate($base, $curr);
        }

        return $rates;
    }
}
