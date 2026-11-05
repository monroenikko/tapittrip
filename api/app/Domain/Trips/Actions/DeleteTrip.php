<?php

declare(strict_types=1);

namespace App\Domain\Trips\Actions;

use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Facades\DB;

final class DeleteTrip
{
    /**
     * Delete an existing trip.
     */
    public function handle(Trip $trip): void
    {
        DB::transaction(function () use ($trip): void {
            $trip->delete();
        });
    }
}
