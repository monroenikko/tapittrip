<?php

declare(strict_types=1);

namespace App\Services\Expenses;

use App\Domain\Expenses\ExpenseSplitCalculator;
use App\DTOs\Expenses\CreateExpenseData;
use App\DTOs\Expenses\GroupSettlementResult;
use App\DTOs\Expenses\RecordSettlementData;
use App\DTOs\Expenses\SetTripBudgetData;
use App\DTOs\Expenses\TripExpensesSummaryResult;
use App\DTOs\Expenses\UpdateExpenseData;
use App\Exceptions\VersionConflictException;
use App\Http\Resources\Api\V1\ExpenseResource;
use App\Models\Expense;
use App\Models\ExpenseSettlement;
use App\Models\ExpenseSplit;
use App\Models\ItineraryItem;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\TripBudget;
use App\Models\TripMember;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

final class ExpenseService
{
    public function __construct(
        private readonly CurrencyExchangeRateService $rateService,
    ) {}

    /**
     * Enforce viewer access for private personal expenses vs shared group expenses.
     *
     * @throws AuthorizationException
     */
    public function ensureVisibleTo(Expense $expense, ?User $user): void
    {
        if (! $expense->isVisibleTo($user)) {
            throw new AuthorizationException('Personal expenses remain private until shared.');
        }
    }

    /**
     * Create a new expense with attributed rate snapshot, participant membership validation,
     * and exact minor-unit splits.
     */
    public function createExpense(Trip $trip, CreateExpenseData $data): Expense
    {
        return DB::transaction(function () use ($trip, $data): Expense {
            if ($data->clientOperationId !== null) {
                $existing = Expense::query()
                    ->where('trip_id', $trip->id)
                    ->where('client_operation_id', $data->clientOperationId)
                    ->first();

                if ($existing !== null) {
                    return $existing->load(['payer', 'creator', 'itineraryItem', 'stay', 'splits.user']);
                }
            }

            $this->ensureAcceptedMember($trip, $data->payerId, 'payer_id', 'The selected payer is not an accepted member of this trip.');
            $this->ensureSameTripLinks($trip, $data->itineraryItemId, $data->stayId);

            $baseCurrency = $this->resolveTripLedgerCurrency($trip);
            $snapshot = $this->resolveConversionSnapshot(
                currency: $data->currency,
                baseCurrency: $baseCurrency,
                amountMinor: $data->amountMinor,
                explicitRate: $data->exchangeRate,
                explicitSource: $data->rateSource,
                explicitCapturedAt: $data->rateCapturedAt,
                explicitStatus: $data->conversionStatus,
            );

            $splitPlan = $this->resolveSplitPlan(
                trip: $trip,
                amountMinor: $data->amountMinor,
                baseAmountMinor: $snapshot['base_amount_minor'],
                splitType: $data->splitType,
                visibility: $data->visibility,
                participantIds: $data->participantIds,
                rawSplits: $data->splits,
            );

            /** @var Expense $expense */
            $expense = new Expense([
                'trip_id' => $trip->id,
                'payer_id' => $data->payerId,
                'created_by_user_id' => $data->createdByUserId,
                'category' => $data->category,
                'title' => $data->title,
                'amount_minor' => $data->amountMinor,
                'currency' => $data->currency,
                'exchange_rate' => $snapshot['exchange_rate'],
                'rate_source' => $snapshot['rate_source'],
                'rate_captured_at' => $snapshot['rate_captured_at'],
                'conversion_status' => $snapshot['conversion_status'],
                'base_amount_minor' => $snapshot['base_amount_minor'],
                'expense_date' => $data->expenseDate,
                'itinerary_item_id' => $data->itineraryItemId,
                'stay_id' => $data->stayId,
                'split_type' => $data->splitType,
                'visibility' => $splitPlan['visibility'],
                'notes' => $data->notes,
                'receipt_url' => $data->receiptUrl,
                'version' => 1,
                'client_operation_id' => $data->clientOperationId,
            ]);
            if ($data->id !== null && $data->id !== '') {
                $expense->id = $data->id;
            }
            $expense->save();

            foreach ($splitPlan['rows'] as $row) {
                ExpenseSplit::create([
                    'expense_id' => $expense->id,
                    'user_id' => $row['user_id'],
                    'amount_minor' => $row['amount_minor'],
                    'base_amount_minor' => $row['base_amount_minor'],
                    'shares' => $row['shares'],
                    'settled' => false,
                ]);
            }

            return $expense->load(['payer', 'creator', 'itineraryItem', 'stay', 'splits.user']);
        });
    }

    /**
     * In-place update an existing expense, preserving historical FX snapshots unless
     * currency/rate inputs change and recomputing splits atomically under base_version locking.
     */
    public function updateExpense(Expense $expense, UpdateExpenseData $data, ?User $actor = null): Expense
    {
        return DB::transaction(function () use ($expense, $data, $actor): Expense {
            /** @var Expense $locked */
            $locked = Expense::query()
                ->whereKey($expense->id)
                ->with(['splits', 'trip.budget', 'trip.owner'])
                ->lockForUpdate()
                ->firstOrFail();

            if ($locked->visibility === 'private' && $actor !== null && ! $locked->isOwnedBy($actor)) {
                throw new AuthorizationException('Personal expenses can only be modified by their creator.');
            }

            if ($data->baseVersion !== null && $locked->version !== $data->baseVersion) {
                throw new VersionConflictException(
                    serverVersion: $locked->version,
                    serverPayload: $this->serializeConflictPayload($locked),
                    message: 'Expense was modified on another device.',
                );
            }

            $trip = $locked->trip;
            if ($data->payerId !== null) {
                $this->ensureAcceptedMember($trip, $data->payerId, 'payer_id', 'The selected payer is not an accepted member of this trip.');
            }

            $nextItineraryItemId = $data->hasItineraryItemId ? $data->itineraryItemId : $locked->itinerary_item_id;
            $nextStayId = $data->hasStayId ? $data->stayId : $locked->stay_id;
            $this->ensureSameTripLinks($trip, $nextItineraryItemId, $nextStayId);

            $baseCurrency = $this->resolveTripLedgerCurrency($trip);
            $nextCurrency = $data->currency ?? $locked->currency;
            $nextAmountMinor = $data->amountMinor ?? $locked->amount_minor;
            $rateInputsProvided = $data->currency !== null
                || $data->hasExchangeRate
                || $data->conversionStatus !== null
                || $data->rateSource !== null;

            if ($rateInputsProvided) {
                $snapshot = $this->resolveConversionSnapshot(
                    currency: $nextCurrency,
                    baseCurrency: $baseCurrency,
                    amountMinor: $nextAmountMinor,
                    explicitRate: $data->exchangeRate,
                    explicitSource: $data->rateSource,
                    explicitCapturedAt: $data->rateCapturedAt,
                    explicitStatus: $data->conversionStatus,
                );
            } elseif ($locked->conversion_status === 'unavailable' || $locked->exchange_rate === null || $locked->base_amount_minor === null) {
                $snapshot = [
                    'exchange_rate' => null,
                    'base_amount_minor' => null,
                    'rate_source' => $locked->rate_source ?? 'unavailable',
                    'rate_captured_at' => $locked->rate_captured_at,
                    'conversion_status' => 'unavailable',
                ];
            } else {
                $lockedRate = (float) $locked->exchange_rate;
                $recomputedBase = $nextCurrency === $baseCurrency
                    ? $nextAmountMinor
                    : CountryCurrencyResolver::convertAmountMinor(
                        $nextAmountMinor,
                        $nextCurrency,
                        $baseCurrency,
                        $lockedRate,
                    );

                $snapshot = [
                    'exchange_rate' => $lockedRate,
                    'base_amount_minor' => $recomputedBase,
                    'rate_source' => $locked->rate_source ?? 'snapshot',
                    'rate_captured_at' => $locked->rate_captured_at,
                    'conversion_status' => 'converted',
                ];
            }

            $nextSplitType = $data->splitType ?? $locked->split_type;
            $nextVisibility = $data->visibility ?? ($nextSplitType === $locked->split_type ? $locked->visibility : null);

            $shouldRecomputeSplits = $data->amountMinor !== null
                || $data->splitType !== null
                || $data->visibility !== null
                || $data->hasParticipantIds
                || $data->hasSplits
                || $rateInputsProvided;

            if ($shouldRecomputeSplits) {
                $participantIds = $data->hasParticipantIds ? $data->participantIds : null;
                $rawSplits = $data->hasSplits ? $data->splits : null;

                // Preserve existing participants/proportions when only amount/rate changed on selected/custom.
                if (! $data->hasParticipantIds && ! $data->hasSplits && $data->splitType === null && $locked->splits->isNotEmpty()) {
                    if ($nextSplitType === 'selected') {
                        $participantIds = $locked->splits->pluck('user_id')->map('strval')->values()->all();
                    } elseif ($nextSplitType === 'custom') {
                        if ($data->amountMinor === null) {
                            $rawSplits = $locked->splits->map(fn (ExpenseSplit $s): array => [
                                'user_id' => $s->user_id,
                                'amount_minor' => $s->amount_minor,
                                'shares' => $s->shares,
                            ])->values()->all();
                        } else {
                            $priorShares = [];
                            foreach ($locked->splits as $s) {
                                $priorShares[$s->user_id] = $s->amount_minor;
                            }
                            $scaledShares = ExpenseSplitCalculator::allocateProportional($nextAmountMinor, $priorShares);
                            $rawSplits = [];
                            foreach ($scaledShares as $uid => $amt) {
                                $rawSplits[] = ['user_id' => $uid, 'amount_minor' => $amt, 'shares' => 1];
                            }
                        }
                    }
                }

                $splitPlan = $this->resolveSplitPlan(
                    trip: $trip,
                    amountMinor: $nextAmountMinor,
                    baseAmountMinor: $snapshot['base_amount_minor'],
                    splitType: $nextSplitType,
                    visibility: $nextVisibility,
                    participantIds: $participantIds,
                    rawSplits: $rawSplits,
                );
            } else {
                $splitPlan = [
                    'visibility' => $nextVisibility ?? $locked->visibility,
                    'rows' => null,
                ];
            }

            $attributes = [
                'amount_minor' => $nextAmountMinor,
                'currency' => $nextCurrency,
                'exchange_rate' => $snapshot['exchange_rate'],
                'rate_source' => $snapshot['rate_source'],
                'rate_captured_at' => $snapshot['rate_captured_at'],
                'conversion_status' => $snapshot['conversion_status'],
                'base_amount_minor' => $snapshot['base_amount_minor'],
                'split_type' => $nextSplitType,
                'visibility' => $splitPlan['visibility'],
                'version' => $locked->version + 1,
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
            if ($data->hasNotes) {
                $attributes['notes'] = $data->notes;
            }
            if ($data->hasReceiptUrl) {
                $attributes['receipt_url'] = $data->receiptUrl;
            }
            if ($data->hasItineraryItemId) {
                $attributes['itinerary_item_id'] = $data->itineraryItemId;
            }
            if ($data->hasStayId) {
                $attributes['stay_id'] = $data->stayId;
            }

            $locked->update($attributes);

            if ($splitPlan['rows'] !== null) {
                ExpenseSplit::withTrashed()
                    ->where('expense_id', $locked->id)
                    ->forceDelete();

                foreach ($splitPlan['rows'] as $row) {
                    ExpenseSplit::create([
                        'expense_id' => $locked->id,
                        'user_id' => $row['user_id'],
                        'amount_minor' => $row['amount_minor'],
                        'base_amount_minor' => $row['base_amount_minor'],
                        'shares' => $row['shares'],
                        'settled' => false,
                    ]);
                }
            }

            return $locked->fresh(['payer', 'creator', 'itineraryItem', 'stay', 'splits.user']);
        });
    }

    /**
     * Soft delete an expense under optional base_version concurrency check.
     */
    public function deleteExpense(Expense $expense, ?User $actor = null, ?int $baseVersion = null): bool
    {
        return DB::transaction(function () use ($expense, $actor, $baseVersion): bool {
            /** @var Expense $locked */
            $locked = Expense::query()->whereKey($expense->id)->lockForUpdate()->firstOrFail();

            if ($locked->visibility === 'private' && $actor !== null && ! $locked->isOwnedBy($actor)) {
                throw new AuthorizationException('Personal expenses can only be deleted by their creator.');
            }

            if ($baseVersion !== null && $locked->version !== $baseVersion) {
                throw new VersionConflictException(
                    serverVersion: $locked->version,
                    serverPayload: $this->serializeConflictPayload($locked),
                    message: 'Expense was modified on another device.',
                );
            }

            $locked->splits()->delete();

            return (bool) $locked->delete();
        });
    }

    /**
     * Aggregate visible spending summary, separating shared vs personal totals and
     * reporting unconverted foreign expenses without inventing conversion rates.
     */
    public function getExpensesSummary(Trip $trip, ?User $user = null): TripExpensesSummaryResult
    {
        $budget = $trip->budget;
        $baseCurrency = $this->resolveTripLedgerCurrency($trip, $user);
        $totalBudgetMinor = $budget?->total_budget_minor;
        $dailyBudgetMinor = $budget?->daily_budget_minor;

        $expenses = $trip->expenses()->visibleTo($user)->get();

        $totalSpentBaseMinor = 0;
        $sharedSpentBaseMinor = 0;
        $personalSpentBaseMinor = 0;
        $unconvertedExpensesCount = 0;
        $unconvertedByCurrency = [];

        $categoryTotals = [];
        $categoryCounts = [];
        $dailyTotals = [];
        $dailyCounts = [];

        foreach ($expenses as $expense) {
            $isConverted = ($expense->conversion_status ?? 'converted') === 'converted'
                && $expense->base_amount_minor !== null;

            if (! $isConverted) {
                $unconvertedExpensesCount++;
                $cur = $expense->currency;
                if (! isset($unconvertedByCurrency[$cur])) {
                    $unconvertedByCurrency[$cur] = ['currency' => $cur, 'amount_minor' => 0, 'count' => 0];
                }
                $unconvertedByCurrency[$cur]['amount_minor'] += $expense->amount_minor;
                $unconvertedByCurrency[$cur]['count']++;

                continue;
            }

            $baseAmount = (int) $expense->base_amount_minor;
            $totalSpentBaseMinor += $baseAmount;

            if (($expense->visibility ?? 'shared') === 'shared') {
                $sharedSpentBaseMinor += $baseAmount;
            } else {
                $personalSpentBaseMinor += $baseAmount;
            }

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
            sharedSpentBaseMinor: $sharedSpentBaseMinor,
            personalSpentBaseMinor: $personalSpentBaseMinor,
            unconvertedExpensesCount: $unconvertedExpensesCount,
            unconvertedTotals: array_values($unconvertedByCurrency),
        );
    }

    /**
     * Set or update the target budget and base currency for a trip.
     */
    public function setBudget(Trip $trip, SetTripBudgetData $data): TripBudget
    {
        return DB::transaction(function () use ($trip, $data): TripBudget {
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
     * Compute shared member net balances, per-currency breakdowns, unconverted flags,
     * and simplified debt settlement suggestions. Private personal expenses are strictly excluded.
     */
    public function calculateGroupSettlement(Trip $trip, ?User $user = null): GroupSettlementResult
    {
        $baseCurrency = $this->resolveTripLedgerCurrency($trip);

        // 1. Gather active accepted trip members
        $users = $trip->users()->get();
        if ($trip->owner !== null && ! $users->contains('id', $trip->owner_id)) {
            $users->push($trip->owner);
        }

        $activeUserIds = $users->pluck('id')->map('strval')->all();
        $userMap = [];
        $netBalances = [];
        $perCurrencyNet = [];

        foreach ($users as $u) {
            $userMap[$u->id] = $u;
            $netBalances[$u->id] = 0;
        }

        $ensureParticipant = function (string $uid, ?User $loadedUser = null) use (&$userMap, &$netBalances): void {
            if (! isset($userMap[$uid])) {
                $resolved = $loadedUser ?? User::find($uid);
                if ($resolved !== null) {
                    $userMap[$resolved->id] = $resolved;
                    $netBalances[$resolved->id] = $netBalances[$resolved->id] ?? 0;
                }
            }
        };

        // 2. Process strictly SHARED expenses
        $expenses = $trip->expenses()
            ->where('visibility', 'shared')
            ->with(['splits.user', 'payer'])
            ->get();

        $unconvertedExpenses = [];

        foreach ($expenses as $expense) {
            $ensureParticipant($expense->payer_id, $expense->payer);
            $expCur = strtoupper($expense->currency);
            if (! isset($perCurrencyNet[$expCur])) {
                $perCurrencyNet[$expCur] = [];
            }

            // Track native-currency shared contribution and splits
            $perCurrencyNet[$expCur][$expense->payer_id] = ($perCurrencyNet[$expCur][$expense->payer_id] ?? 0) + $expense->amount_minor;
            if ($expense->splits->isNotEmpty()) {
                foreach ($expense->splits as $split) {
                    $ensureParticipant($split->user_id, $split->user);
                    $perCurrencyNet[$expCur][$split->user_id] = ($perCurrencyNet[$expCur][$split->user_id] ?? 0) - $split->amount_minor;
                }
            } elseif ($expense->split_type === 'equal') {
                $equalNative = ExpenseSplitCalculator::allocateEqual($expense->amount_minor, array_keys($userMap));
                foreach ($equalNative as $uid => $shareMinor) {
                    $perCurrencyNet[$expCur][$uid] = ($perCurrencyNet[$expCur][$uid] ?? 0) - $shareMinor;
                }
            } else {
                $perCurrencyNet[$expCur][$expense->payer_id] -= $expense->amount_minor;
            }

            // Exclude unconverted expenses from base_currency balances instead of fabricating a rate
            if (($expense->conversion_status ?? 'converted') !== 'converted' || $expense->base_amount_minor === null) {
                $unconvertedExpenses[] = [
                    'id' => $expense->id,
                    'title' => $expense->title,
                    'amount_minor' => $expense->amount_minor,
                    'currency' => $expense->currency,
                    'payer_id' => $expense->payer_id,
                    'payer_name' => $expense->payer?->name ?? 'Unknown',
                    'expense_date' => $expense->expense_date->toDateString(),
                    'reason' => 'exchange_rate_unavailable',
                ];

                continue;
            }

            // Base-currency settlement ledger
            $netBalances[$expense->payer_id] = ($netBalances[$expense->payer_id] ?? 0) + (int) $expense->base_amount_minor;

            if ($expense->splits->isNotEmpty()) {
                $missingBaseSplits = $expense->splits->contains(fn (ExpenseSplit $s): bool => $s->base_amount_minor === null);
                if ($missingBaseSplits) {
                    $sourceShares = [];
                    foreach ($expense->splits as $s) {
                        $sourceShares[$s->user_id] = $s->amount_minor;
                    }
                    $allocatedBase = ExpenseSplitCalculator::allocateProportional((int) $expense->base_amount_minor, $sourceShares);
                    foreach ($allocatedBase as $uid => $splitBase) {
                        $netBalances[$uid] = ($netBalances[$uid] ?? 0) - $splitBase;
                    }
                } else {
                    foreach ($expense->splits as $split) {
                        $netBalances[$split->user_id] = ($netBalances[$split->user_id] ?? 0) - (int) $split->base_amount_minor;
                    }
                }
            } elseif ($expense->split_type === 'equal') {
                $memberIds = array_map('strval', array_keys($userMap));
                if ($memberIds !== []) {
                    $equalBase = ExpenseSplitCalculator::allocateEqual((int) $expense->base_amount_minor, $memberIds);
                    foreach ($equalBase as $uid => $debit) {
                        $netBalances[$uid] = ($netBalances[$uid] ?? 0) - $debit;
                    }
                }
            } else {
                // Single-payer shared informational expense: payer bears their own cost
                $netBalances[$expense->payer_id] -= (int) $expense->base_amount_minor;
            }
        }

        // 3. Process settlements already recorded (with foreign-currency conversion safety)
        $settlements = $trip->settlements()
            ->with(['payer', 'payee'])
            ->orderBy('settled_at', 'desc')
            ->get();

        foreach ($settlements as $settlement) {
            $ensureParticipant($settlement->payer_id, $settlement->payer);
            $ensureParticipant($settlement->payee_id, $settlement->payee);

            $setCur = strtoupper($settlement->currency);
            $perCurrencyNet[$setCur][$settlement->payer_id] = ($perCurrencyNet[$setCur][$settlement->payer_id] ?? 0) + $settlement->amount_minor;
            $perCurrencyNet[$setCur][$settlement->payee_id] = ($perCurrencyNet[$setCur][$settlement->payee_id] ?? 0) - $settlement->amount_minor;

            $settlementBaseMinor = $settlement->base_amount_minor;
            if ($settlementBaseMinor === null) {
                if ($setCur === $baseCurrency) {
                    $settlementBaseMinor = $settlement->amount_minor;
                } elseif ($settlement->exchange_rate !== null && (float) $settlement->exchange_rate > 0) {
                    $settlementBaseMinor = CountryCurrencyResolver::convertAmountMinor(
                        $settlement->amount_minor,
                        $setCur,
                        $baseCurrency,
                        (float) $settlement->exchange_rate,
                    );
                } else {
                    $rateData = $this->rateService->getRate($setCur, $baseCurrency);
                    if ($rateData !== null && $rateData->rate > 0) {
                        $settlementBaseMinor = CountryCurrencyResolver::convertAmountMinor(
                            $settlement->amount_minor,
                            $setCur,
                            $baseCurrency,
                            $rateData->rate,
                        );
                    } else {
                        $settlementBaseMinor = null;
                    }
                }
            }

            if ($settlementBaseMinor !== null) {
                $netBalances[$settlement->payer_id] = ($netBalances[$settlement->payer_id] ?? 0) + (int) $settlementBaseMinor;
                $netBalances[$settlement->payee_id] = ($netBalances[$settlement->payee_id] ?? 0) - (int) $settlementBaseMinor;
            }
        }

        // 4. Construct balances array without exposing member email PII
        $balances = [];
        $creditors = [];
        $debtors = [];

        foreach ($netBalances as $userId => $balance) {
            $u = $userMap[$userId] ?? User::find($userId);
            $status = $balance > 0 ? 'is_owed' : ($balance < 0 ? 'owes' : 'settled');

            $balances[] = [
                'user_id' => $userId,
                'name' => $u?->name ?? 'Former companion',
                'net_balance_minor' => $balance,
                'status' => $status,
                'is_departed' => ! in_array((string) $userId, $activeUserIds, true),
            ];

            if ($balance > 0) {
                $creditors[] = ['user_id' => $userId, 'amount' => $balance];
            } elseif ($balance < 0) {
                $debtors[] = ['user_id' => $userId, 'amount' => abs($balance)];
            }
        }

        usort($balances, fn (array $a, array $b): int => strcmp((string) $a['name'], (string) $b['name']));

        // Format per-currency native balances
        $perCurrencyBalances = [];
        ksort($perCurrencyNet);
        foreach ($perCurrencyNet as $cur => $byUser) {
            $list = [];
            foreach ($byUser as $uid => $bal) {
                $u = $userMap[$uid] ?? User::find($uid);
                $list[] = [
                    'user_id' => $uid,
                    'name' => $u?->name ?? 'Former companion',
                    'net_balance_minor' => $bal,
                    'status' => $bal > 0 ? 'is_owed' : ($bal < 0 ? 'owes' : 'settled'),
                    'is_departed' => ! in_array((string) $uid, $activeUserIds, true),
                ];
            }
            usort($list, fn (array $a, array $b): int => strcmp((string) $a['name'], (string) $b['name']));
            $perCurrencyBalances[$cur] = $list;
        }

        // 5. Greedy Cash-Flow Simplification Algorithm
        usort($creditors, fn (array $a, array $b): int => $b['amount'] <=> $a['amount']);
        usort($debtors, fn (array $a, array $b): int => $b['amount'] <=> $a['amount']);

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
                    'payer_name' => $debtorUser?->name ?? 'Former companion',
                    'payee_id' => $c['user_id'],
                    'payee_name' => $creditorUser?->name ?? 'Former companion',
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
        $settlementHistory = $settlements->map(fn (ExpenseSettlement $s): array => [
            'id' => $s->id,
            'payer_id' => $s->payer_id,
            'payer_name' => $s->payer?->name ?? 'Former companion',
            'payee_id' => $s->payee_id,
            'payee_name' => $s->payee?->name ?? 'Former companion',
            'amount_minor' => $s->amount_minor,
            'currency' => $s->currency,
            'exchange_rate' => $s->exchange_rate !== null ? (float) $s->exchange_rate : null,
            'base_amount_minor' => $s->base_amount_minor,
            'base_currency' => $baseCurrency,
            'rate_source' => $s->rate_source,
            'settled_at' => $s->settled_at?->toIso8601String(),
            'notes' => $s->notes,
        ])->values()->all();

        return new GroupSettlementResult(
            tripId: $trip->id,
            baseCurrency: $baseCurrency,
            balances: $balances,
            suggestedSettlements: $suggestedSettlements,
            settlementHistory: $settlementHistory,
            perCurrencyBalances: $perCurrencyBalances,
            unconvertedExpenses: $unconvertedExpenses,
        );
    }

    /**
     * Record an offline/manual debt settlement ledger adjustment between two trip companions.
     */
    public function recordSettlement(Trip $trip, User $actor, RecordSettlementData $data): ExpenseSettlement
    {
        if (! $trip->hasMember($actor) && $trip->owner_id !== $actor->id) {
            throw new AuthorizationException('You are not authorized to record settlements for this trip.');
        }

        if ($data->clientOperationId !== null) {
            $existing = ExpenseSettlement::query()
                ->where('trip_id', $trip->id)
                ->where('client_operation_id', $data->clientOperationId)
                ->first();

            if ($existing !== null) {
                return $existing->load(['payer', 'payee']);
            }
        }

        if ($data->payerId === $data->payeeId) {
            throw ValidationException::withMessages([
                'payee_id' => ['The payer and payee must be different travelers.'],
            ]);
        }

        $this->ensureAcceptedMember($trip, $data->payerId, 'payer_id', 'The selected payer is not a member of this trip.');
        $this->ensureAcceptedMember($trip, $data->payeeId, 'payee_id', 'The selected payee is not a member of this trip.');

        if ($data->amountMinor <= 0) {
            throw ValidationException::withMessages([
                'amount_minor' => ['The settlement amount must be greater than zero.'],
            ]);
        }

        $baseCurrency = $this->resolveTripLedgerCurrency($trip);
        $snapshot = $this->resolveConversionSnapshot(
            currency: $data->currency,
            baseCurrency: $baseCurrency,
            amountMinor: $data->amountMinor,
            explicitRate: $data->exchangeRate,
            explicitSource: $data->rateSource,
            explicitCapturedAt: $data->rateCapturedAt,
            explicitStatus: null,
        );

        if ($snapshot['conversion_status'] !== 'converted' || $snapshot['base_amount_minor'] === null) {
            throw ValidationException::withMessages([
                'exchange_rate' => ["Exchange rate unavailable to convert {$data->currency} settlement to {$baseCurrency}."],
            ]);
        }

        /** @var ExpenseSettlement $settlement */
        $settlement = ExpenseSettlement::create([
            'trip_id' => $trip->id,
            'payer_id' => $data->payerId,
            'payee_id' => $data->payeeId,
            'created_by_user_id' => $actor->id,
            'amount_minor' => $data->amountMinor,
            'currency' => $data->currency,
            'exchange_rate' => $snapshot['exchange_rate'],
            'base_amount_minor' => $snapshot['base_amount_minor'],
            'rate_source' => $snapshot['rate_source'],
            'rate_captured_at' => $snapshot['rate_captured_at'],
            'settled_at' => $data->settledAt,
            'notes' => $data->notes,
            'client_operation_id' => $data->clientOperationId,
        ]);

        return $settlement->load(['payer', 'payee']);
    }

    /**
     * List visible expenses for a trip with optional category and date filters.
     *
     * @return Collection<int, Expense>
     */
    public function getTripExpenses(
        Trip $trip,
        ?User $viewer = null,
        ?string $category = null,
        ?string $expenseDate = null,
    ): Collection {
        $query = $trip->expenses()
            ->visibleTo($viewer)
            ->with(['payer', 'creator', 'itineraryItem', 'stay', 'splits.user']);

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

        return $expense->fresh(['payer', 'creator', 'itineraryItem', 'stay', 'splits.user']);
    }

    private function resolveTripLedgerCurrency(Trip $trip, ?User $fallbackUser = null): string
    {
        $resolved = $trip->budget?->currency
            ?? $trip->owner?->home_currency;

        if ($resolved === null || trim((string) $resolved) === '') {
            $resolved = $trip->expenses()
                ->where('visibility', 'shared')
                ->reorder()
                ->orderBy('created_at')
                ->value('currency')
                ?? $trip->expenses()
                    ->reorder()
                    ->orderBy('created_at')
                    ->value('currency');
        }

        if ($resolved === null || trim((string) $resolved) === '') {
            $resolved = $fallbackUser?->home_currency
                ?? CountryCurrencyResolver::resolve($trip->destination_country ?? $trip->title);
        }

        $normalized = strtoupper(trim((string) $resolved));

        return $normalized !== '' ? $normalized : 'USD';
    }

    private function ensureAcceptedMember(Trip $trip, string $userId, string $field, string $message): void
    {
        if ($trip->owner_id === $userId) {
            return;
        }

        $isMember = TripMember::query()
            ->where('trip_id', $trip->id)
            ->where('user_id', $userId)
            ->where('invitation_status', 'accepted')
            ->exists();

        if (! $isMember) {
            throw ValidationException::withMessages([$field => [$message]]);
        }
    }

    private function ensureSameTripLinks(Trip $trip, ?string $itineraryItemId, ?string $stayId): void
    {
        if ($itineraryItemId !== null) {
            $belongs = ItineraryItem::query()
                ->where('id', $itineraryItemId)
                ->where('trip_id', $trip->id)
                ->exists();

            if (! $belongs) {
                throw ValidationException::withMessages([
                    'itinerary_item_id' => ['The linked itinerary item does not belong to this trip.'],
                ]);
            }
        }

        if ($stayId !== null) {
            $belongs = Stay::query()
                ->where('id', $stayId)
                ->where('trip_id', $trip->id)
                ->exists();

            if (! $belongs) {
                throw ValidationException::withMessages([
                    'stay_id' => ['The linked stay does not belong to this trip.'],
                ]);
            }
        }
    }

    /**
     * @return array{
     *   exchange_rate: float|null,
     *   base_amount_minor: int|null,
     *   rate_source: string,
     *   rate_captured_at: CarbonImmutable|null,
     *   conversion_status: string
     * }
     */
    private function resolveConversionSnapshot(
        string $currency,
        string $baseCurrency,
        int $amountMinor,
        ?float $explicitRate,
        ?string $explicitSource,
        ?string $explicitCapturedAt,
        ?string $explicitStatus,
    ): array {
        $from = strtoupper(trim($currency));
        $to = strtoupper(trim($baseCurrency));
        $capturedAt = $explicitCapturedAt !== null
            ? CarbonImmutable::parse($explicitCapturedAt)->setTimezone('UTC')
            : CarbonImmutable::now('UTC');

        if ($from === $to) {
            return [
                'exchange_rate' => 1.0,
                'base_amount_minor' => $amountMinor,
                'rate_source' => 'identity',
                'rate_captured_at' => $capturedAt,
                'conversion_status' => 'converted',
            ];
        }

        if ($explicitStatus === 'unavailable' || $explicitSource === 'unavailable') {
            return [
                'exchange_rate' => null,
                'base_amount_minor' => null,
                'rate_source' => 'unavailable',
                'rate_captured_at' => null,
                'conversion_status' => 'unavailable',
            ];
        }

        if ($explicitRate !== null && $explicitRate > 0) {
            return [
                'exchange_rate' => $explicitRate,
                'base_amount_minor' => CountryCurrencyResolver::convertAmountMinor($amountMinor, $from, $to, $explicitRate),
                'rate_source' => $explicitSource ?? 'user_manual',
                'rate_captured_at' => $capturedAt,
                'conversion_status' => 'converted',
            ];
        }

        $rateData = $this->rateService->getRate($from, $to);
        if (! $rateData->available || $rateData->rate === null || $rateData->rate <= 0) {
            return [
                'exchange_rate' => null,
                'base_amount_minor' => null,
                'rate_source' => 'unavailable',
                'rate_captured_at' => null,
                'conversion_status' => 'unavailable',
            ];
        }

        return [
            'exchange_rate' => $rateData->rate,
            'base_amount_minor' => CountryCurrencyResolver::convertAmountMinor($amountMinor, $from, $to, $rateData->rate),
            'rate_source' => $explicitSource ?? $rateData->provider,
            'rate_captured_at' => CarbonImmutable::parse($rateData->asOf)->setTimezone('UTC'),
            'conversion_status' => 'converted',
        ];
    }

    /**
     * @param  list<string>|null  $participantIds
     * @param  array<int, array<string, mixed>>|null  $rawSplits
     * @return array{
     *   visibility: string,
     *   rows: list<array{user_id: string, amount_minor: int, base_amount_minor: int|null, shares: int}>
     * }
     */
    private function resolveSplitPlan(
        Trip $trip,
        int $amountMinor,
        ?int $baseAmountMinor,
        string $splitType,
        ?string $visibility,
        ?array $participantIds,
        ?array $rawSplits,
    ): array {
        if (! in_array($splitType, ExpenseSplitCalculator::SPLIT_TYPES, true)) {
            throw ValidationException::withMessages([
                'split_type' => ['Unsupported split type.'],
            ]);
        }

        if ($splitType === 'single') {
            if (($participantIds !== null && $participantIds !== []) || ($rawSplits !== null && $rawSplits !== [])) {
                throw ValidationException::withMessages([
                    'splits' => ['Single personal expenses cannot define companion splits.'],
                ]);
            }

            return [
                'visibility' => $visibility ?? 'private',
                'rows' => [],
            ];
        }

        if ($visibility === 'private') {
            throw ValidationException::withMessages([
                'visibility' => ['Shared split modes cannot use private visibility.'],
            ]);
        }

        $sharesByUser = [];
        $weightsByUser = [];

        if ($splitType === 'custom') {
            if ($rawSplits === null || $rawSplits === []) {
                throw ValidationException::withMessages([
                    'splits' => ['Custom split mode requires at least one participant share.'],
                ]);
            }

            foreach ($rawSplits as $entry) {
                $uid = (string) ($entry['user_id'] ?? '');
                $shareMinor = (int) ($entry['amount_minor'] ?? 0);
                if ($uid === '' || $shareMinor <= 0) {
                    throw ValidationException::withMessages([
                        'splits' => ['Each custom split must reference a valid participant and positive amount.'],
                    ]);
                }
                if (isset($sharesByUser[$uid])) {
                    throw ValidationException::withMessages([
                        'splits' => ['Duplicate participants are not allowed in custom splits.'],
                    ]);
                }

                $this->ensureAcceptedMember($trip, $uid, 'splits', 'All split participants must be accepted members of this trip.');
                $sharesByUser[$uid] = $shareMinor;
                $weightsByUser[$uid] = max(1, (int) ($entry['shares'] ?? 1));
            }

            if (array_sum($sharesByUser) !== $amountMinor) {
                throw ValidationException::withMessages([
                    'splits' => ['Custom split amounts must equal the exact expense total in minor units.'],
                ]);
            }
        } elseif ($splitType === 'selected') {
            if ($participantIds === null || $participantIds === []) {
                throw ValidationException::withMessages([
                    'participant_ids' => ['Select at least one accepted trip member to split with.'],
                ]);
            }

            $uniqueIds = [];
            foreach ($participantIds as $uid) {
                $uidStr = (string) $uid;
                if (in_array($uidStr, $uniqueIds, true)) {
                    throw ValidationException::withMessages([
                        'participant_ids' => ['Duplicate participants are not allowed in selected splits.'],
                    ]);
                }
                $this->ensureAcceptedMember($trip, $uidStr, 'participant_ids', 'All selected split participants must be accepted members of this trip.');
                $uniqueIds[] = $uidStr;
            }

            $sharesByUser = ExpenseSplitCalculator::allocateEqual($amountMinor, $uniqueIds);
            $weightsByUser = array_fill_keys($uniqueIds, 1);
        } elseif ($rawSplits !== null && $rawSplits !== []) {
            // Equal mode with explicit participant splits array
            foreach ($rawSplits as $entry) {
                $uid = (string) ($entry['user_id'] ?? '');
                $shareMinor = (int) ($entry['amount_minor'] ?? 0);
                if ($uid === '' || $shareMinor <= 0) {
                    throw ValidationException::withMessages([
                        'splits' => ['Each split must reference a valid participant and positive amount.'],
                    ]);
                }
                if (isset($sharesByUser[$uid])) {
                    throw ValidationException::withMessages([
                        'splits' => ['Duplicate participants are not allowed in expense splits.'],
                    ]);
                }
                $this->ensureAcceptedMember($trip, $uid, 'splits', 'All split participants must be accepted members of this trip.');
                $sharesByUser[$uid] = $shareMinor;
                $weightsByUser[$uid] = max(1, (int) ($entry['shares'] ?? 1));
            }

            if (array_sum($sharesByUser) !== $amountMinor) {
                throw ValidationException::withMessages([
                    'splits' => ['Provided split amounts must sum to the exact expense total in minor units.'],
                ]);
            }
        } else {
            // Equal mode across all accepted trip members
            $members = $trip->users()->get();
            if ($trip->owner !== null && ! $members->contains('id', $trip->owner_id)) {
                $members->push($trip->owner);
            }

            $memberIds = $members->pluck('id')->map('strval')->values()->all();
            if ($participantIds !== null && $participantIds !== []) {
                $memberIds = [];
                foreach ($participantIds as $uid) {
                    $uidStr = (string) $uid;
                    if (! in_array($uidStr, $memberIds, true)) {
                        $this->ensureAcceptedMember($trip, $uidStr, 'participant_ids', 'All split participants must be accepted members of this trip.');
                        $memberIds[] = $uidStr;
                    }
                }
            }

            if ($memberIds !== []) {
                $sharesByUser = ExpenseSplitCalculator::allocateEqual($amountMinor, $memberIds);
                $weightsByUser = array_fill_keys($memberIds, 1);
            }
        }

        $baseSharesByUser = ($baseAmountMinor !== null && $sharesByUser !== [])
            ? ExpenseSplitCalculator::allocateProportional($baseAmountMinor, $sharesByUser)
            : [];

        $rows = [];
        foreach ($sharesByUser as $uid => $shareMinor) {
            $rows[] = [
                'user_id' => $uid,
                'amount_minor' => $shareMinor,
                'base_amount_minor' => $baseSharesByUser[$uid] ?? null,
                'shares' => $weightsByUser[$uid] ?? 1,
            ];
        }

        return [
            'visibility' => 'shared',
            'rows' => $rows,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function serializeConflictPayload(Expense $expense): array
    {
        $expense->loadMissing(['payer', 'creator', 'splits.user']);

        return (new ExpenseResource($expense))->resolve();
    }
}
