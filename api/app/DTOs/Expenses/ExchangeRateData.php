<?php

declare(strict_types=1);

namespace App\DTOs\Expenses;

final class ExchangeRateData
{
    public function __construct(
        public string $from,
        public string $to,
        public ?float $rate,
        public ?float $reciprocalRate,
        public string $asOf,
        public string $provider = 'open_exchange_rates',
        public bool $available = true,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'from' => $this->from,
            'to' => $this->to,
            'rate' => $this->rate,
            'reciprocal_rate' => $this->reciprocalRate,
            'as_of' => $this->asOf,
            'provider' => $this->provider,
            'available' => $this->available,
        ];
    }
}
