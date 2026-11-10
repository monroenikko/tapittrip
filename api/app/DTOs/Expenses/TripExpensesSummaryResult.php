<?php

declare(strict_types=1);

namespace App\DTOs\Expenses;

final readonly class TripExpensesSummaryResult
{
    /**
     * @param  list<array{category: string, amount_minor: int, count: int, percent: float}>  $categoryBreakdown
     * @param  list<array{date: string, amount_minor: int, count: int}>  $dailySpending
     * @param  list<array{currency: string, amount_minor: int, count: int}>  $unconvertedTotals
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
        public int $sharedSpentBaseMinor = 0,
        public int $personalSpentBaseMinor = 0,
        public int $unconvertedExpensesCount = 0,
        public array $unconvertedTotals = [],
        public string $accountingNotice = 'Tracks recorded expenses and balances only; TapItTrip does not process or verify real money transfers.',
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
            'shared_spent_base_minor' => $this->sharedSpentBaseMinor,
            'personal_spent_base_minor' => $this->personalSpentBaseMinor,
            'remaining_budget_minor' => $this->remainingBudgetMinor,
            'budget_utilization_percent' => $this->budgetUtilizationPercent,
            'expenses_count' => $this->expensesCount,
            'unconverted_expenses_count' => $this->unconvertedExpensesCount,
            'unconverted_totals' => $this->unconvertedTotals,
            'accounting_notice' => $this->accountingNotice,
            'category_breakdown' => $this->categoryBreakdown,
            'daily_spending' => $this->dailySpending,
        ];
    }
}
