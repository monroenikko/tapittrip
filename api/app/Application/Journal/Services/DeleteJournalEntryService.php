<?php

declare(strict_types=1);

namespace App\Application\Journal\Services;

use App\Domain\Journal\Models\JournalEntry;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;

final class DeleteJournalEntryService
{
    public function execute(JournalEntry $entry, User $user): void
    {
        if ($entry->user_id !== $user->id && $entry->trip->owner_id !== $user->id) {
            throw new AuthorizationException('You are not authorized to delete this journal entry.');
        }

        $entry->delete();
    }
}
