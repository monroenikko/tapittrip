<?php

declare(strict_types=1);

namespace App\Services\Journal;

use App\DTOs\Journal\CreateJournalEntryData;
use App\DTOs\Journal\UpdateJournalEntryData;
use App\Models\JournalEntry;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

final class JournalService
{
    /**
     * Get accessible journal entries for a traveler on a trip.
     * Shows traveler's own entries + entries shared with the circle.
     *
     * @return Collection<int, JournalEntry>
     */
    public function getTripJournal(Trip $trip, User $user, ?string $entryDate = null): Collection
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

    /**
     * Create a new journal entry.
     */
    public function createEntry(Trip $trip, User $user, CreateJournalEntryData $data): JournalEntry
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

    /**
     * Update an existing journal entry.
     */
    public function updateEntry(JournalEntry $entry, User $user, UpdateJournalEntryData $data): JournalEntry
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

    /**
     * Upload and attach a photo to the journal entry.
     */
    public function uploadPhoto(JournalEntry $entry, User $user, UploadedFile $file): JournalEntry
    {
        if ($entry->user_id !== $user->id && $entry->trip->owner_id !== $user->id) {
            throw new AuthorizationException('You are not authorized to add photos to this journal entry.');
        }

        $extension = $file->getClientOriginalExtension() ?: 'jpg';
        $filename = Str::uuid()->toString().'.'.$extension;
        $path = $file->storeAs("journal-photos/{$entry->trip_id}/{$entry->id}", $filename, 'public');

        $url = Storage::disk('public')->url($path);

        $currentPhotos = $entry->photos ?? [];
        $currentPhotos[] = $url;

        $entry->update(['photos' => $currentPhotos]);

        return $entry->fresh(['author', 'itineraryItem']);
    }

    /**
     * Delete a journal entry.
     */
    public function deleteEntry(JournalEntry $entry, User $user): void
    {
        if ($entry->user_id !== $user->id && $entry->trip->owner_id !== $user->id) {
            throw new AuthorizationException('You are not authorized to delete this journal entry.');
        }

        $entry->delete();
    }
}
