<?php

declare(strict_types=1);

namespace App\Application\Expenses\Data;

final readonly class SetTripBudgetData
{
    public function __construct(
        public string $currency,
        public int $totalBudgetMinor,
        public ?int $dailyBudgetMinor = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            currency: strtoupper(trim((string) $data['currency'])),
            totalBudgetMinor: (int) $data['total_budget_minor'],
            dailyBudgetMinor: isset($data['daily_budget_minor']) ? (int) $data['daily_budget_minor'] : null,
        );
    }
}
