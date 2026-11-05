<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Services;

use App\Domain\Itinerary\Models\TripDay;
use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Facades\DB;

final class EnsureTripDayService
{
    public function handle(Trip $trip, string $localDate, ?string $notes = null): TripDay
    {
        return DB::transaction(function () use ($trip, $localDate, $notes): TripDay {
            /** @var TripDay $day */
            $day = TripDay::query()->firstOrCreate(
                [
                    'trip_id' => $trip->id,
                    'local_date' => $localDate,
                ],
                [
                    'notes' => $notes,
                ]
            );

            if ($notes !== null && $day->notes !== $notes) {
                $day->update(['notes' => $notes]);
            }

            return $day;
        });
    }
}
