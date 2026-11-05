<?php

declare(strict_types=1);

namespace App\Domain\Trips\Actions;

use App\Domain\Trips\Data\CreateTripData;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Support\Facades\DB;

final class CreateTrip
{
    /**
     * Create a new trip and assign the creator as the owner.
     */
    public function handle(User $owner, CreateTripData $data): Trip
    {
        return DB::transaction(function () use ($owner, $data): Trip {
            /** @var Trip $trip */
            $trip = Trip::query()->create([
                'owner_id' => $owner->id,
                'title' => $data->title,
                'start_date' => $data->startDate,
                'end_date' => $data->endDate,
                'primary_timezone' => $data->primaryTimezone,
                'origin_country' => $data->originCountry,
                'destination_country' => $data->destinationCountry,
                'trip_type' => $data->tripType,
                'planning_mode' => $data->planningMode,
                'status' => 'planned',
                'version' => 1,
            ]);

            $trip->members()->create([
                'user_id' => $owner->id,
                'role' => 'owner',
                'invitation_status' => 'accepted',
            ]);

            return $trip;
        });
    }
}
