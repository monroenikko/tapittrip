<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\TripAnnouncement;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripAnnouncement
 */
final class TripAnnouncementResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'trip_id' => (string) $this->trip_id,
            'author_id' => (string) $this->author_id,
            'author_name' => (string) ($this->author?->display_name ?? $this->author?->name ?? 'Organizer'),
            'title' => (string) $this->title,
            'body' => (string) $this->body,
            'is_pinned' => (bool) $this->is_pinned,
            'client_operation_id' => $this->client_operation_id !== null ? (string) $this->client_operation_id : null,
            'version' => (int) $this->version,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
