<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\TripInvitation;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripInvitation
 */
final class TripInvitationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $inviteType = (string) ($this->invite_type ?? 'link');

        return [
            'id' => (string) $this->id,
            'trip_id' => (string) $this->trip_id,
            'invite_type' => $inviteType,
            'target_display_name' => $inviteType === 'direct'
                ? ($this->targetUser?->display_name ?? $this->targetUser?->name)
                : null,
            'proposed_role' => $this->proposed_role,
            'status' => $this->effectiveStatus(),
            'max_uses' => (int) $this->max_uses,
            'use_count' => (int) $this->use_count,
            'expires_at' => $this->expires_at->toIso8601String(),
            'revoked_at' => $this->revoked_at?->toIso8601String(),
            'responded_at' => $this->responded_at?->toIso8601String(),
            'inviter_name' => $this->inviter?->display_name ?? $this->inviter?->name ?? 'Organizer',
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
