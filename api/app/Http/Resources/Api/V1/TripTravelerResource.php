<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\TripTraveler;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripTraveler
 */
final class TripTravelerResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $viewer = $request->user();
        $isManager = $viewer !== null && $this->managing_user_id === $viewer->id;
        $isTripOwner = $viewer !== null && (
            ($this->relationLoaded('trip') ? $this->trip?->owner_id : $this->trip()->value('owner_id')) === $viewer->id
        );

        return [
            'id' => (string) $this->id,
            'trip_id' => (string) $this->trip_id,
            'linked_member_id' => $this->linked_member_id !== null ? (string) $this->linked_member_id : null,
            'managing_user_id' => (string) $this->managing_user_id,
            'managing_user_name' => (string) ($this->managingUser?->display_name ?? $this->managingUser?->name ?? 'Traveler'),
            'display_name' => (string) $this->display_name,
            'traveler_category' => (string) $this->traveler_category,
            'restricted_notes' => $isManager ? $this->restricted_notes : null,
            'can_edit' => $isManager,
            'can_delete' => $isManager || $isTripOwner,
            'version' => (int) $this->version,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
