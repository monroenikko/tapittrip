<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Lounges\Models\AirportLounge;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AirportLounge
 */
final class AirportLoungeResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'airport_id' => $this->airport_id,
            'terminal_id' => $this->terminal_id,
            'name' => $this->name,
            'operator' => $this->operator,
            'location_description' => $this->location_description,
            'is_airside' => $this->is_airside,
            'opening_hours' => $this->opening_hours,
            'amenities' => $this->amenities,
            'access_methods' => $this->access_methods,
            'estimated_price' => $this->estimated_price,
            'booking_url' => $this->booking_url,
            'transit_warning' => $this->transit_warning,
            'disclaimer' => $this->disclaimer,
            'terminal' => new AirportTerminalResource($this->whenLoaded('terminal')),
            'airport' => new AirportResource($this->whenLoaded('airport')),
        ];
    }
}
