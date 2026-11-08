<?php

declare(strict_types=1);

namespace App\Application\Expenses\Services;

use App\Application\Expenses\Data\CreateExpenseData;
use App\Domain\Expenses\Models\Expense;
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
                $baseAmountMinor = (int) round($data->amountMinor * $exchangeRate);
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

            return $expense->load(['payer', 'itineraryItem', 'stay']);
        });
    }
}
