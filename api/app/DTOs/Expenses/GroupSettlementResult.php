<?php

declare(strict_types=1);

namespace App\DTOs\Expenses;

final readonly class GroupSettlementResult
{
    /**
     * @param  array<int, array<string, mixed>>  $balances
     * @param  array<int, array<string, mixed>>  $suggestedSettlements
     * @param  array<int, array<string, mixed>>  $settlementHistory
     * @param  array<string, array<int, array<string, mixed>>>  $perCurrencyBalances
     * @param  array<int, array<string, mixed>>  $unconvertedExpenses
     */
    public function __construct(
        public string $tripId,
        public string $baseCurrency,
        public array $balances,
        public array $suggestedSettlements,
        public array $settlementHistory,
        public array $perCurrencyBalances = [],
        public array $unconvertedExpenses = [],
        public string $accountingNotice = 'Balances and settlements are trip ledger records only; TapItTrip does not transfer funds or verify external payments.',
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
            'per_currency_balances' => $this->perCurrencyBalances,
            'unconverted_expenses' => $this->unconvertedExpenses,
            'accounting_notice' => $this->accountingNotice,
        ];
    }
}
