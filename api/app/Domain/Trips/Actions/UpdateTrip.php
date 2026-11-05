<?php

declare(strict_types=1);

namespace App\Domain\Trips\Actions;

use App\Domain\Trips\Data\UpdateTripData;
use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Facades\DB;

final class UpdateTrip
{
    /**
     * Update an existing trip.
     *
     * @param  array<string, mixed>  $rawPayload
     */
    public function handle(Trip $trip, UpdateTripData $data, array $rawPayload): Trip
    {
        return DB::transaction(function () use ($trip, $data, $rawPayload): Trip {
            $updates = $data->toUpdatePayload($rawPayload);
            $updates['version'] = $trip->version + 1;

            $trip->update($updates);

            return $trip->fresh();
        });
    }
}
