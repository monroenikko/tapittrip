<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\ChecklistItem;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ChecklistItem
 */
final class ChecklistItemResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'checklist_id' => $this->checklist_id,
            'trip_id' => $this->trip_id,
            'assigned_user_id' => $this->assigned_user_id,
            'assigned_user_name' => $this->assignedUser?->display_name ?? $this->assignedUser?->name,
            'assigned_traveler_id' => $this->assigned_traveler_id,
            'assigned_traveler_name' => $this->assignedTraveler?->display_name,
            'assigned_traveler_category' => $this->assignedTraveler?->traveler_category,
            'title' => $this->title,
            'category' => $this->category,
            'is_packed' => $this->is_packed,
            'quantity' => $this->quantity,
            'notes' => $this->notes,
            'photo_url' => $this->photo_url,
            'sort_order' => $this->sort_order,
            'packed_at' => $this->packed_at?->toIso8601String(),
            'completed_by_user_id' => $this->completed_by_user_id,
            'completed_by_name' => $this->completedBy?->display_name ?? $this->completedBy?->name,
            'version' => $this->version,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
