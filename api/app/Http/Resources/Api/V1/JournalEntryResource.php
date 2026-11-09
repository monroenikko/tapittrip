<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Journal\Models\JournalEntry;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin JournalEntry
 */
final class JournalEntryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $currentUser = $request->user();
        $isAuthor = $currentUser !== null && (string) $currentUser->id === (string) $this->user_id;

        return [
            'id' => (string) $this->id,
            'trip_id' => (string) $this->trip_id,
            'user_id' => (string) $this->user_id,
            'author_name' => $this->author?->display_name ?? $this->author?->name ?? 'Traveler',
            'author_avatar_url' => $this->author?->avatar_url,
            'itinerary_item_id' => $this->itinerary_item_id ? (string) $this->itinerary_item_id : null,
            'title' => $this->title,
            'content' => $this->content,
            'entry_date' => $this->entry_date?->format('Y-m-d') ?? (string) $this->entry_date,
            'location_name' => $this->location_name,
            'weather' => $this->weather,
            'mood' => $this->mood,
            'is_shared' => (bool) $this->is_shared,
            'is_author' => $isAuthor,
            'photos' => $this->photos ?? [],
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
