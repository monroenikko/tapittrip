<?php

declare(strict_types=1);

namespace App\Application\Journal\Services;

use App\Domain\Journal\Models\JournalEntry;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

final class UploadJournalPhotoService
{
    public function execute(JournalEntry $entry, User $user, UploadedFile $file): JournalEntry
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
}
