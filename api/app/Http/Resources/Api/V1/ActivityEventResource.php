<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\ActivityEvent;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ActivityEvent
 */
final class ActivityEventResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'trip_id' => (string) $this->trip_id,
            'event_type' => $this->event_type,
            'title' => $this->title,
            'summary' => $this->summary,
            'entity_type' => $this->entity_type,
            'entity_id' => $this->entity_id ? (string) $this->entity_id : null,
            'metadata' => $this->metadata ?? (object) [],
            'occurred_at' => $this->occurred_at?->toIso8601String(),
            'actor' => [
                'id' => (string) $this->actor?->id,
                'name' => $this->actor?->name ?? 'Traveler',
                'display_name' => $this->actor?->display_name ?? $this->actor?->name ?? 'Traveler',
                'avatar_url' => $this->actor?->avatar_url,
            ],
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
