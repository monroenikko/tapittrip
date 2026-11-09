<?php

declare(strict_types=1);

namespace App\Application\Journal\Services;

use App\Domain\Journal\Models\JournalEntry;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;

final class GetTripJournalService
{
    /**
     * Get accessible journal entries for a traveler on a trip.
     * Shows traveler's own entries + entries shared with the circle.
     *
     * @return Collection<int, JournalEntry>
     */
    public function execute(Trip $trip, User $user, ?string $entryDate = null): Collection
    {
        $query = JournalEntry::query()
            ->where('trip_id', $trip->id)
            ->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                    ->orWhere('is_shared', true);
            })
            ->with(['author', 'itineraryItem']);

        if ($entryDate !== null && trim($entryDate) !== '') {
            $query->where('entry_date', $entryDate);
        }

        return $query
            ->orderBy('entry_date', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();
    }
}
