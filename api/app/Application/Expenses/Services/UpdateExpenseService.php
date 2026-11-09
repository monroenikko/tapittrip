<?php

declare(strict_types=1);

namespace App\Application\Expenses\Services;

use App\Application\Expenses\Data\UpdateExpenseData;
use App\Domain\Expenses\Models\Expense;
use Illuminate\Support\Facades\DB;

final class UpdateExpenseService
{
    /**
     * In-place update an existing expense and recompute base currency amounts if changed.
     */
    public function execute(Expense $expense, UpdateExpenseData $data): Expense
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
}
