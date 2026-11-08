<?php

declare(strict_types=1);

namespace App\Application\Expenses\Data;

final readonly class GroupSettlementResult
{
    /**
     * @param  array<int, array<string, mixed>>  $balances
     * @param  array<int, array<string, mixed>>  $suggestedSettlements
     * @param  array<int, array<string, mixed>>  $settlementHistory
     */
    public function __construct(
        public string $tripId,
        public string $baseCurrency,
        public array $balances,
        public array $suggestedSettlements,
        public array $settlementHistory,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'trip_id' => $this->tripId,
            'base_currency' => $this->baseCurrency,
            'balances' => $this->balances,
            'suggested_settlements' => $this->suggestedSettlements,
            'settlement_history' => $this->settlementHistory,
        ];
    }
}
