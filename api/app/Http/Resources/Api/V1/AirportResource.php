<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Lounges\Models\Airport;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Airport
 */
final class AirportResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'iata_code' => $this->iata_code,
            'name' => $this->name,
            'city' => $this->city,
            'country' => $this->country,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'timezone' => $this->timezone,
            'terminals' => AirportTerminalResource::collection($this->whenLoaded('terminals')),
        ];
    }
}
