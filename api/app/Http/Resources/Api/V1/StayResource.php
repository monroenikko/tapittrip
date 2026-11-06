<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Application\Stays\Services\StayTransitService;
use App\Domain\Stays\Models\Stay;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Stay
 */
final class StayResource extends JsonResource
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
            'place_id' => $this->place_id,
            'name' => $this->name,
            'stay_type' => $this->stay_type,
            'address' => $this->address,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'check_in_at' => $this->check_in_at?->toIso8601String(),
            'check_out_at' => $this->check_out_at?->toIso8601String(),
            'timezone' => $this->timezone,
            'phone' => $this->phone,
            'booking_reference' => $this->booking_reference,
            'notes' => $this->notes,
            'luggage_profile' => $this->luggage_profile,
            'version' => $this->version,
            'google_maps_url' => $this->google_maps_url,
            'google_maps_directions_url' => $this->google_maps_directions_url,
            'nearest_transit' => (new StayTransitService)->resolve($this->resource),
            'place' => new PlaceResource($this->whenLoaded('place')),
            'itinerary_items' => ItineraryItemResource::collection($this->whenLoaded('itineraryItems')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
