<?php

declare(strict_types=1);

namespace App\Application\Notifications\Services;

use App\Domain\Notifications\Models\Reminder;
use App\Domain\Trips\Models\Trip;
use Illuminate\Database\Eloquent\Collection;

final class GetTripRemindersService
{
    /**
     * Retrieve reminders for a trip.
     *
     * @return Collection<int, Reminder>
     */
    public function execute(Trip $trip, ?string $status = null): Collection
    {
        $query = $trip->reminders()->with(['itineraryItem', 'checklist']);

        if ($status !== null) {
            $query->where('status', $status);
        }

        return $query->get();
    }
}

