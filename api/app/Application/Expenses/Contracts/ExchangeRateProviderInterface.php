<?php

declare(strict_types=1);

namespace App\Application\Expenses\Contracts;

interface ExchangeRateProviderInterface
{
    /**
     * Get the exchange rate from one currency to another.
     */
    public function getRate(string $fromCurrency, string $toCurrency): float;

    /**
     * Get all available rates for a base currency.
     *
     * @return array<string, float>
     */
    public function getRatesForBase(string $baseCurrency): array;
}
