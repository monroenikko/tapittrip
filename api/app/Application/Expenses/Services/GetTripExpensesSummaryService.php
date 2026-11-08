<?php

declare(strict_types=1);

namespace App\Application\Expenses\Services;

use App\Application\Expenses\Data\TripExpensesSummaryResult;
use App\Domain\Trips\Models\Trip;

final class GetTripExpensesSummaryService
{
    /**
     * Aggregate total spent, category distribution, daily breakdown, and remaining budget.
     */
    public function execute(Trip $trip): TripExpensesSummaryResult
    {
        $budget = $trip->budget;
        $baseCurrency = $budget?->currency ?? 'USD';
        $totalBudgetMinor = $budget?->total_budget_minor;
        $dailyBudgetMinor = $budget?->daily_budget_minor;

        $expenses = $trip->expenses()->get();

        $totalSpentBaseMinor = 0;
        $categoryTotals = [];
        $categoryCounts = [];
        $dailyTotals = [];
        $dailyCounts = [];

        foreach ($expenses as $expense) {
            $baseAmount = $expense->base_amount_minor;
            $totalSpentBaseMinor += $baseAmount;

            $cat = $expense->category;
            $categoryTotals[$cat] = ($categoryTotals[$cat] ?? 0) + $baseAmount;
            $categoryCounts[$cat] = ($categoryCounts[$cat] ?? 0) + 1;

            $date = $expense->expense_date->toDateString();
            $dailyTotals[$date] = ($dailyTotals[$date] ?? 0) + $baseAmount;
            $dailyCounts[$date] = ($dailyCounts[$date] ?? 0) + 1;
        }

        $categoryBreakdown = [];
        foreach ($categoryTotals as $cat => $amount) {
            $percent = $totalSpentBaseMinor > 0
                ? round(($amount / $totalSpentBaseMinor) * 100, 1)
                : 0.0;
            $categoryBreakdown[] = [
                'category' => $cat,
                'amount_minor' => $amount,
                'count' => $categoryCounts[$cat],
                'percent' => $percent,
            ];
        }

        $dailySpending = [];
        ksort($dailyTotals);
        foreach ($dailyTotals as $date => $amount) {
            $dailySpending[] = [
                'date' => $date,
                'amount_minor' => $amount,
                'count' => $dailyCounts[$date],
            ];
        }

        $remainingBudgetMinor = null;
        $budgetUtilizationPercent = null;
        if ($totalBudgetMinor !== null && $totalBudgetMinor > 0) {
            $remainingBudgetMinor = $totalBudgetMinor - $totalSpentBaseMinor;
            $budgetUtilizationPercent = round(($totalSpentBaseMinor / $totalBudgetMinor) * 100, 1);
        }

        return new TripExpensesSummaryResult(
            tripId: $trip->id,
            baseCurrency: $baseCurrency,
            totalBudgetMinor: $totalBudgetMinor,
            dailyBudgetMinor: $dailyBudgetMinor,
            totalSpentBaseMinor: $totalSpentBaseMinor,
            remainingBudgetMinor: $remainingBudgetMinor,
            budgetUtilizationPercent: $budgetUtilizationPercent,
            expensesCount: $expenses->count(),
            categoryBreakdown: $categoryBreakdown,
            dailySpending: $dailySpending,
        );
    }
}
