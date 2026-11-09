<?php

declare(strict_types=1);

namespace App\Application\Expenses\Services;

use App\Application\Expenses\Data\GroupSettlementResult;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\ExpenseSettlement;
use App\Domain\Trips\Models\Trip;
use App\Models\User;

final class CalculateGroupSettlementService
{
    /**
     * Compute member net balances and simplified debt settlement transfers.
     */
    public function execute(Trip $trip, ?User $user = null): GroupSettlementResult
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

        foreach ($users as $user) {
            $userMap[$user->id] = $user;
            $netBalances[$user->id] = 0;
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

                    $splitBase = $split->base_amount_minor ?? (int) round($split->amount_minor * ((float) ($expense->exchange_rate ?: 1.0)));
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
            $user = $userMap[$userId] ?? User::find($userId);
            $status = $balance > 0 ? 'is_owed' : ($balance < 0 ? 'owes' : 'settled');

            $balances[] = [
                'user_id' => $userId,
                'name' => $user?->name ?? 'Unknown',
                'email' => $user?->email ?? '',
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
}
