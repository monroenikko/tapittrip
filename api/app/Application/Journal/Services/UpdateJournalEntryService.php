<?php

declare(strict_types=1);

namespace App\Application\Journal\Services;

use App\Application\Journal\Data\UpdateJournalEntryData;
use App\Domain\Journal\Models\JournalEntry;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;

final class UpdateJournalEntryService
{
    public function execute(JournalEntry $entry, User $user, UpdateJournalEntryData $data): JournalEntry
    {
        // Only author or trip owner can update journal entry
        if ($entry->user_id !== $user->id && $entry->trip->owner_id !== $user->id) {
            throw new AuthorizationException('You are not authorized to update this journal entry.');
        }

        $attributes = [];

        if ($data->title !== null) {
            $attributes['title'] = $data->title;
        }
        if ($data->content !== null) {
            $attributes['content'] = $data->content;
        }
        if ($data->entryDate !== null) {
            $attributes['entry_date'] = $data->entryDate;
        }
        if ($data->locationName !== null) {
            $attributes['location_name'] = $data->locationName;
        }
        if ($data->weather !== null) {
            $attributes['weather'] = $data->weather;
        }
        if ($data->mood !== null) {
            $attributes['mood'] = $data->mood;
        }
        if ($data->isShared !== null) {
            $attributes['is_shared'] = $data->isShared;
        }
        if ($data->itineraryItemId !== null) {
            $attributes['itinerary_item_id'] = $data->itineraryItemId;
        }
        if ($data->photos !== null) {
            $attributes['photos'] = $data->photos;
        }

        if (! empty($attributes)) {
            $entry->update($attributes);
        }

        return $entry->fresh(['author', 'itineraryItem']);
    }
}
