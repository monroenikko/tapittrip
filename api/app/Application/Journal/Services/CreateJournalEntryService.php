<?php

declare(strict_types=1);

namespace App\Application\Journal\Services;

use App\Application\Journal\Data\CreateJournalEntryData;
use App\Domain\Journal\Models\JournalEntry;
use App\Domain\Trips\Models\Trip;
use App\Models\User;

final class CreateJournalEntryService
{
    public function execute(Trip $trip, User $user, CreateJournalEntryData $data): JournalEntry
    {
        /** @var JournalEntry $entry */
        $entry = JournalEntry::create([
            'trip_id' => $trip->id,
            'user_id' => $user->id,
            'itinerary_item_id' => $data->itineraryItemId,
            'title' => $data->title,
            'content' => $data->content,
            'entry_date' => $data->entryDate,
            'location_name' => $data->locationName,
            'weather' => $data->weather,
            'mood' => $data->mood,
            'is_shared' => $data->isShared,
            'photos' => $data->photos,
        ]);

        return $entry;
    }
}
