<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\TripOwnershipTransfer;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripOwnershipTransfer
 */
final class TripOwnershipTransferResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'trip_id' => (string) $this->trip_id,
            'trip_title' => (string) ($this->trip?->title ?? 'Shared Trip'),
            'from_user_id' => (string) $this->from_user_id,
            'from_user_name' => (string) ($this->fromUser?->display_name ?? $this->fromUser?->name ?? 'Organizer'),
            'to_user_id' => (string) $this->to_user_id,
            'to_user_name' => (string) ($this->toUser?->display_name ?? $this->toUser?->name ?? 'Companion'),
            'former_owner_role' => (string) $this->former_owner_role,
            'status' => $this->effectiveStatus(),
            'expires_at' => $this->expires_at->toIso8601String(),
            'responded_at' => $this->responded_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
