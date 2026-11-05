<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Itinerary\Models\Place;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Place
 */
final class PlaceResource extends JsonResource
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
            'provider' => $this->provider,
            'provider_place_id' => $this->provider_place_id,
            'name' => $this->name,
            'formatted_address' => $this->formatted_address,
            'country_code' => $this->country_code,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'photo_reference' => $this->photo_reference,
            'attribution' => $this->attribution,
            'google_maps_url' => $this->google_maps_url,
            'last_refreshed_at' => $this->last_refreshed_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
