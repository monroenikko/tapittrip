<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\TripInvitation;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripInvitation
 */
final class IncomingTripInvitationResource extends JsonResource
{
    /**
     * Expose only safe summary fields for a targeted direct invitation.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'trip_id' => (string) $this->trip_id,
            'trip_title' => (string) ($this->trip?->title ?? 'Shared Trip'),
            'destination_country' => $this->trip?->destination_country,
            'proposed_role' => (string) $this->proposed_role,
            'status' => $this->effectiveStatus(),
            'inviter_name' => (string) ($this->inviter?->display_name ?? $this->inviter?->name ?? 'Organizer'),
            'expires_at' => $this->expires_at->toIso8601String(),
            'responded_at' => $this->responded_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
