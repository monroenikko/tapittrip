<?php

declare(strict_types=1);

namespace App\Application\Expenses\Services;

use App\Application\Expenses\Data\SetTripBudgetData;
use App\Domain\Expenses\Models\TripBudget;
use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Facades\DB;

final class SetTripBudgetService
{
    /**
     * Set or update the target budget and base currency for a trip.
     */
    public function execute(Trip $trip, SetTripBudgetData $data): TripBudget
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
}
