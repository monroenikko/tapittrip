<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Checklists\Models\Checklist;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Checklist
 */
final class ChecklistResource extends JsonResource
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
            'trip_id' => $this->trip_id,
            'title' => $this->title,
            'type' => $this->type,
            'description' => $this->description,
            'sort_order' => $this->sort_order,
            'total_items_count' => $this->total_items_count,
            'packed_items_count' => $this->packed_items_count,
            'progress_percentage' => $this->progress_percentage,
            'items' => ChecklistItemResource::collection($this->whenLoaded('items')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
