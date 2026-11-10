<?php

declare(strict_types=1);

namespace App\Services\Expenses;

use App\DTOs\Expenses\CreateExpenseData;
use App\DTOs\Expenses\GroupSettlementResult;
use App\DTOs\Expenses\RecordSettlementData;
use App\DTOs\Expenses\SetTripBudgetData;
use App\DTOs\Expenses\TripExpensesSummaryResult;
use App\DTOs\Expenses\UpdateExpenseData;
use App\Models\Expense;
use App\Models\ExpenseSettlement;
use App\Models\ExpenseSplit;
use App\Models\Trip;
use App\Models\TripBudget;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

final class ExpenseService
{
    /**
     * Create a new expense for the trip with currency conversion and optional splits.
     */
    public function createExpense(Trip $trip, CreateExpenseData $data): Expense
    {
        return DB::transaction(function () use ($trip, $data) {
            $baseCurrency = $trip->budget?->currency ?? $data->currency;

            // Compute base amount in trip currency
            if ($data->currency === $baseCurrency) {
                $baseAmountMinor = $data->amountMinor;
                $exchangeRate = 1.0;
            } else {
                $exchangeRate = $data->exchangeRate > 0 ? $data->exchangeRate : 1.0;
                $baseAmountMinor = CountryCurrencyResolver::convertAmountMinor(
                    $data->amountMinor,
                    $data->currency,
                    $baseCurrency,
                    $exchangeRate,
                );
            }

            /** @var Expense $expense */
            $expense = Expense::create([
                'trip_id' => $trip->id,
                'payer_id' => $data->payerId,
                'category' => $data->category,
                'title' => $data->title,
                'amount_minor' => $data->amountMinor,
                'currency' => $data->currency,
                'exchange_rate' => $exchangeRate,
                'base_amount_minor' => $baseAmountMinor,
                'expense_date' => $data->expenseDate,
                'itinerary_item_id' => $data->itineraryItemId,
                'stay_id' => $data->stayId,
                'split_type' => $data->splitType,
                'notes' => $data->notes,
                'receipt_url' => $data->receiptUrl,
                'version' => 1,
            ]);

            // Create splits if provided or if equal
            if ($data->splits !== null && count($data->splits) > 0) {
                foreach ($data->splits as $split) {
                    $splitAmount = (int) $split['amount_minor'];
                    $splitBase = isset($split['base_amount_minor'])
                        ? (int) $split['base_amount_minor']
                        : CountryCurrencyResolver::convertAmountMinor(
                            $splitAmount,
                            $data->currency,
                            $baseCurrency,
                            $exchangeRate,
                        );

                    ExpenseSplit::create([
                        'expense_id' => $expense->id,
                        'user_id' => (string) $split['user_id'],
                        'amount_minor' => $splitAmount,
                        'base_amount_minor' => $splitBase,
                        'shares' => (int) ($split['shares'] ?? 1),
                        'settled' => (bool) ($split['settled'] ?? false),
                    ]);
                }
            } elseif ($data->splitType === 'equal') {
                $users = $trip->users()->get();
                if ($trip->owner !== null && ! $users->contains('id', $trip->owner_id)) {
                    $users->push($trip->owner);
                }

                $count = count($users);
                if ($count > 0) {
                    $perUserAmount = intdiv($data->amountMinor, $count);
                    $remainderAmount = $data->amountMinor % $count;
                    $perUserBase = intdiv($baseAmountMinor, $count);
                    $remainderBase = $baseAmountMinor % $count;

                    $i = 0;
                    foreach ($users as $u) {
                        $uAmount = $perUserAmount + ($i < $remainderAmount ? 1 : 0);
                        $uBase = $perUserBase + ($i < $remainderBase ? 1 : 0);

                        ExpenseSplit::create([
                            'expense_id' => $expense->id,
                            'user_id' => $u->id,
                            'amount_minor' => $uAmount,
                            'base_amount_minor' => $uBase,
                            'shares' => 1,
                            'settled' => false,
                        ]);
                        $i++;
                    }
                }
            }

            return $expense->load(['payer', 'itineraryItem', 'stay', 'splits.user']);
        });
    }

    /**
     * In-place update an existing expense and recompute base currency amounts if changed.
     */
    public function updateExpense(Expense $expense, UpdateExpenseData $data): Expense
    {
        return DB::transaction(function () use ($expense, $data) {
            $currency = $data->currency ?? $expense->currency;
            $amountMinor = $data->amountMinor ?? $expense->amount_minor;
            $exchangeRate = $data->exchangeRate ?? (float) $expense->exchange_rate;

            $trip = $expense->trip;
            $baseCurrency = $trip->budget?->currency ?? $currency;

            if ($currency === $baseCurrency) {
                $baseAmountMinor = $amountMinor;
                $exchangeRate = 1.0;
            } else {
                $exchangeRate = $exchangeRate > 0 ? $exchangeRate : 1.0;
                $baseAmountMinor = CountryCurrencyResolver::convertAmountMinor(
                    $amountMinor,
                    $currency,
                    $baseCurrency,
                    $exchangeRate,
                );
            }

            $attributes = [
                'amount_minor' => $amountMinor,
                'currency' => $currency,
                'exchange_rate' => $exchangeRate,
                'base_amount_minor' => $baseAmountMinor,
                'version' => $expense->version + 1,
            ];

            if ($data->payerId !== null) {
                $attributes['payer_id'] = $data->payerId;
            }
            if ($data->category !== null) {
                $attributes['category'] = $data->category;
            }
            if ($data->title !== null) {
                $attributes['title'] = $data->title;
            }
            if ($data->expenseDate !== null) {
                $attributes['expense_date'] = $data->expenseDate;
            }
            if ($data->splitType !== null) {
                $attributes['split_type'] = $data->splitType;
            }
            if ($data->notes !== null || $data->notes === null) {
                $attributes['notes'] = $data->notes;
            }
            if ($data->receiptUrl !== null || $data->receiptUrl === null) {
                $attributes['receipt_url'] = $data->receiptUrl;
            }
            if ($data->itineraryItemId !== null) {
                $attributes['itinerary_item_id'] = $data->itineraryItemId;
            }
            if ($data->stayId !== null) {
                $attributes['stay_id'] = $data->stayId;
            }

            $expense->update($attributes);

            return $expense->fresh(['payer', 'itineraryItem', 'stay']);
        });
    }

    /**
     * Soft delete an expense.
     */
    public function deleteExpense(Expense $expense): bool
    {
        return DB::transaction(function () use ($expense) {
            return (bool) $expense->delete();
        });
    }

    /**
     * Aggregate total spent, category distribution, daily breakdown, and remaining budget.
     */
    public function getExpensesSummary(Trip $trip, ?User $user = null): TripExpensesSummaryResult
    {
        $budget = $trip->budget;
        $baseCurrency = $budget?->currency
            ?? $user?->home_currency
            ?? $trip->owner?->home_currency
            ?? CountryCurrencyResolver::resolve($trip->destination_country ?? $trip->title)
            ?? 'USD';
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

    /**
     * Set or update the target budget and base currency for a trip.
     */
    public function setBudget(Trip $trip, SetTripBudgetData $data): TripBudget
    {
        return DB::transaction(function () use ($trip, $data) {
            /** @var TripBudget $budget */
            $budget = TripBudget::updateOrCreate(
                ['trip_id' => $trip->id],
                [
                    'currency' => $data->currency,
                    'total_budget_minor' => $data->totalBudgetMinor,
                    'daily_budget_minor' => $data->dailyBudgetMinor,
                ]
            );

            return $budget;
        });
    }

    /**
     * Compute member net balances and simplified debt settlement transfers.
     */
    public function calculateGroupSettlement(Trip $trip, ?User $user = null): GroupSettlementResult
    {
        $baseCurrency = $trip->budget?->currency
            ?? $user?->home_currency
            ?? $trip->owner?->home_currency
            ?? CountryCurrencyResolver::resolve($trip->destination_country ?? $trip->title)
            ?? 'USD';

        // 1. Gather all trip users
        $users = $trip->users()->get();
        if ($trip->owner !== null && ! $users->contains('id', $trip->owner_id)) {
            $users->push($trip->owner);
        }

        $userMap = [];
        $netBalances = [];

        foreach ($users as $u) {
            $userMap[$u->id] = $u;
            $netBalances[$u->id] = 0;
        }

        // 2. Process all expenses
        $expenses = $trip->expenses()
            ->with(['splits', 'payer'])
            ->get();

        foreach ($expenses as $expense) {
            if (! isset($userMap[$expense->payer_id])) {
                $payer = $expense->payer ?? User::find($expense->payer_id);
                if ($payer !== null) {
                    $userMap[$payer->id] = $payer;
                    $netBalances[$payer->id] = 0;
                }
            }

            // Payer is credited the full base amount paid
            $netBalances[$expense->payer_id] = ($netBalances[$expense->payer_id] ?? 0) + $expense->base_amount_minor;

            if ($expense->splits->isNotEmpty()) {
                // Explicit splits recorded
                foreach ($expense->splits as $split) {
                    if (! isset($userMap[$split->user_id])) {
                        $splitUser = $split->user ?? User::find($split->user_id);
                        if ($splitUser !== null) {
                            $userMap[$splitUser->id] = $splitUser;
                            $netBalances[$splitUser->id] = 0;
                        }
                    }

                    $splitBase = $split->base_amount_minor ?? CountryCurrencyResolver::convertAmountMinor(
                        $split->amount_minor,
                        $expense->currency,
                        $baseCurrency,
                        (float) ($expense->exchange_rate ?: 1.0),
                    );
                    $netBalances[$split->user_id] = ($netBalances[$split->user_id] ?? 0) - $splitBase;
                }
            } elseif ($expense->split_type === 'equal') {
                // Split equally across all trip users
                $count = count($userMap);
                if ($count > 0) {
                    $perUserBase = (int) intdiv($expense->base_amount_minor, $count);
                    $remainder = $expense->base_amount_minor % $count;

                    $i = 0;
                    foreach (array_keys($userMap) as $uid) {
                        $debit = $perUserBase + ($i < $remainder ? 1 : 0);
                        $netBalances[$uid] = ($netBalances[$uid] ?? 0) - $debit;
                        $i++;
                    }
                }
            } else {
                // Single expense: payer pays for themselves, zero net debt
                $netBalances[$expense->payer_id] -= $expense->base_amount_minor;
            }
        }

        // 3. Process settlements already made
        $settlements = $trip->settlements()
            ->with(['payer', 'payee'])
            ->orderBy('settled_at', 'desc')
            ->get();

        foreach ($settlements as $settlement) {
            // Payer paid settlement -> their balance goes up (debt reduced)
            $netBalances[$settlement->payer_id] = ($netBalances[$settlement->payer_id] ?? 0) + $settlement->amount_minor;
            // Payee received settlement -> their balance goes down (credit reduced)
            $netBalances[$settlement->payee_id] = ($netBalances[$settlement->payee_id] ?? 0) - $settlement->amount_minor;
        }

        // 4. Construct balances array
        $balances = [];
        $creditors = [];
        $debtors = [];

        foreach ($netBalances as $userId => $balance) {
            $u = $userMap[$userId] ?? User::find($userId);
            $status = $balance > 0 ? 'is_owed' : ($balance < 0 ? 'owes' : 'settled');

            $balances[] = [
                'user_id' => $userId,
                'name' => $u?->name ?? 'Unknown',
                'email' => $u?->email ?? '',
                'net_balance_minor' => $balance,
                'status' => $status,
            ];

            if ($balance > 0) {
                $creditors[] = ['user_id' => $userId, 'amount' => $balance];
            } elseif ($balance < 0) {
                $debtors[] = ['user_id' => $userId, 'amount' => abs($balance)];
            }
        }

        // Sort balances by name
        usort($balances, fn ($a, $b) => strcmp((string) $a['name'], (string) $b['name']));

        // 5. Greedy Cash-Flow Simplification Algorithm
        usort($creditors, fn ($a, $b) => $b['amount'] <=> $a['amount']);
        usort($debtors, fn ($a, $b) => $b['amount'] <=> $a['amount']);

        $suggestedSettlements = [];
        $cIdx = 0;
        $dIdx = 0;

        while ($cIdx < count($creditors) && $dIdx < count($debtors)) {
            $c = &$creditors[$cIdx];
            $d = &$debtors[$dIdx];

            $transfer = min($c['amount'], $d['amount']);
            if ($transfer > 0) {
                $debtorUser = $userMap[$d['user_id']] ?? User::find($d['user_id']);
                $creditorUser = $userMap[$c['user_id']] ?? User::find($c['user_id']);

                $suggestedSettlements[] = [
                    'payer_id' => $d['user_id'],
                    'payer_name' => $debtorUser?->name ?? 'Unknown',
                    'payee_id' => $c['user_id'],
                    'payee_name' => $creditorUser?->name ?? 'Unknown',
                    'amount_minor' => $transfer,
                    'currency' => $baseCurrency,
                ];

                $c['amount'] -= $transfer;
                $d['amount'] -= $transfer;
            }

            if ($c['amount'] === 0) {
                $cIdx++;
            }
            if ($d['amount'] === 0) {
                $dIdx++;
            }
        }

        // 6. Settlement history
        $settlementHistory = $settlements->map(fn (ExpenseSettlement $s) => [
            'id' => $s->id,
            'payer_id' => $s->payer_id,
            'payer_name' => $s->payer?->name ?? 'Unknown',
            'payee_id' => $s->payee_id,
            'payee_name' => $s->payee?->name ?? 'Unknown',
            'amount_minor' => $s->amount_minor,
            'currency' => $s->currency,
            'settled_at' => $s->settled_at?->toIso8601String(),
            'notes' => $s->notes,
        ])->values()->all();

        return new GroupSettlementResult(
            tripId: $trip->id,
            baseCurrency: $baseCurrency,
            balances: $balances,
            suggestedSettlements: $suggestedSettlements,
            settlementHistory: $settlementHistory,
        );
    }

    /**
     * Record a debt settlement between two trip companions.
     */
    public function recordSettlement(Trip $trip, User $actor, RecordSettlementData $data): ExpenseSettlement
    {
        // 1. Authorize actor
        if (! $trip->hasMember($actor) && $trip->owner_id !== $actor->id) {
            throw new AuthorizationException('You are not authorized to record settlements for this trip.');
        }

        // 2. Validate payer and payee are distinct
        if ($data->payerId === $data->payeeId) {
            throw ValidationException::withMessages([
                'payee_id' => ['The payer and payee must be different travelers.'],
            ]);
        }

        // 3. Validate payer is a trip member
        if (! $trip->hasMember($data->payerId) && $trip->owner_id !== $data->payerId) {
            throw ValidationException::withMessages([
                'payer_id' => ['The selected payer is not a member of this trip.'],
            ]);
        }

        // 4. Validate payee is a trip member
        if (! $trip->hasMember($data->payeeId) && $trip->owner_id !== $data->payeeId) {
            throw ValidationException::withMessages([
                'payee_id' => ['The selected payee is not a member of this trip.'],
            ]);
        }

        // 5. Amount validation
        if ($data->amountMinor <= 0) {
            throw ValidationException::withMessages([
                'amount_minor' => ['The settlement amount must be greater than zero.'],
            ]);
        }

        /** @var ExpenseSettlement $settlement */
        $settlement = ExpenseSettlement::create([
            'trip_id' => $trip->id,
            'payer_id' => $data->payerId,
            'payee_id' => $data->payeeId,
            'amount_minor' => $data->amountMinor,
            'currency' => $data->currency,
            'settled_at' => $data->settledAt,
            'notes' => $data->notes,
        ]);

        return $settlement->load(['payer', 'payee']);
    }

    /**
     * List expenses for a trip with optional category and date filters.
     *
     * @return Collection<int, Expense>
     */
    public function getTripExpenses(Trip $trip, ?string $category = null, ?string $expenseDate = null): Collection
    {
        $query = $trip->expenses()->with(['payer', 'itineraryItem', 'stay']);

        if ($category !== null && trim($category) !== '') {
            $query->where('category', $category);
        }

        if ($expenseDate !== null && trim($expenseDate) !== '') {
            $query->whereDate('expense_date', $expenseDate);
        }

        return $query->get();
    }

    /**
     * Get the target budget for a trip.
     */
    public function getTripBudget(Trip $trip): ?TripBudget
    {
        return $trip->budget;
    }

    /**
     * Upload and attach a receipt photo to an expense.
     */
    public function uploadReceipt(Expense $expense, UploadedFile $file): Expense
    {
        $path = $file->store("receipts/{$expense->trip_id}", 'public');
        $url = Storage::disk('public')->url($path);

        $expense->update(['receipt_url' => $url]);

        return $expense->fresh(['payer', 'itineraryItem', 'stay', 'splits.user']);
    }
}
