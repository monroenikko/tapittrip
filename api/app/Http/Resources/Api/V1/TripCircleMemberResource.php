<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\TripMember;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripMember
 */
final class TripCircleMemberResource extends JsonResource
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
            'display_name' => $this->user?->display_name ?? $this->user?->name ?? 'Traveler',
            'avatar_url' => $this->user?->avatar_url,
            'role' => $this->role,
            'invitation_status' => $this->invitation_status,
            'joined_at' => $this->created_at?->toIso8601String(),
        ];
    }
}

