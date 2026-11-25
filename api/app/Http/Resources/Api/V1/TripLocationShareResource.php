<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\TripLocationShare;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripLocationShare
 */
final class TripLocationShareResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'trip_id' => (string) $this->trip_id,
            'user_id' => (string) $this->user_id,
            'user_name' => (string) ($this->user?->display_name ?? $this->user?->name ?? 'Traveler'),
            'enabled' => (bool) $this->enabled,
            'is_active' => (bool) $this->isActive(),
            'is_stale' => (bool) $this->isStale(),
            'duration_minutes' => (int) $this->duration_minutes,
            'expires_at' => $this->expires_at?->toIso8601String(),
            'audience' => (string) $this->audience,
            'latitude' => $this->latitude !== null ? (float) $this->latitude : null,
            'longitude' => $this->longitude !== null ? (float) $this->longitude : null,
            'last_shared_at' => $this->last_shared_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
