<?php

declare(strict_types=1);

namespace App\Application\Expenses\Data;

final readonly class TripExpensesSummaryResult
{
    /**
     * @param  list<array{category: string, amount_minor: int, count: int, percent: float}>  $categoryBreakdown
     * @param  list<array{date: string, amount_minor: int, count: int}>  $dailySpending
     */
    public function __construct(
        public string $tripId,
        public string $baseCurrency,
        public ?int $totalBudgetMinor,
        public ?int $dailyBudgetMinor,
        public int $totalSpentBaseMinor,
        public ?int $remainingBudgetMinor,
        public ?float $budgetUtilizationPercent,
        public int $expensesCount,
        public array $categoryBreakdown = [],
        public array $dailySpending = [],
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'trip_id' => $this->tripId,
            'base_currency' => $this->baseCurrency,
            'total_budget_minor' => $this->totalBudgetMinor,
            'daily_budget_minor' => $this->dailyBudgetMinor,
            'total_spent_base_minor' => $this->totalSpentBaseMinor,
            'remaining_budget_minor' => $this->remainingBudgetMinor,
            'budget_utilization_percent' => $this->budgetUtilizationPercent,
            'expenses_count' => $this->expensesCount,
            'category_breakdown' => $this->categoryBreakdown,
            'daily_spending' => $this->dailySpending,
        ];
    }
}
