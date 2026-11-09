<?php

declare(strict_types=1);

namespace App\Application\Expenses\Services;

use App\Application\Expenses\Data\CreateExpenseData;
use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\ExpenseSplit;
use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Facades\DB;

final class CreateExpenseService
{
    /**
     * Create a new expense for the trip with currency conversion.
     */
    public function execute(Trip $trip, CreateExpenseData $data): Expense
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
}
