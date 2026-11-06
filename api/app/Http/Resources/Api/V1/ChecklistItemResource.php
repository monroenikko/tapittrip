<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Checklists\Models\ChecklistItem;
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
            'title' => $this->title,
            'category' => $this->category,
            'is_packed' => $this->is_packed,
            'quantity' => $this->quantity,
            'notes' => $this->notes,
            'photo_url' => $this->photo_url,
            'sort_order' => $this->sort_order,
            'packed_at' => $this->packed_at?->toIso8601String(),
            'version' => $this->version,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
