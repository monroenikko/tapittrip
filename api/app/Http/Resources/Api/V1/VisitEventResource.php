<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Itinerary\Models\VisitEvent;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin VisitEvent
 */
final class VisitEventResource extends JsonResource
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
            'itinerary_item_id' => $this->itinerary_item_id,
            'user_id' => $this->user_id,
            'event_type' => $this->event_type,
            'method' => $this->method,
            'detected_at' => $this->detected_at?->toIso8601String(),
            'accuracy_m' => $this->accuracy_m,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
