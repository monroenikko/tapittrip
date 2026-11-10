<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Domain\Stays\StayPrivacy;
use App\Models\Stay;
use App\Services\Stays\StayTransitService;
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
        $viewer = $request->user();
        $isOwner = StayPrivacy::isOwner($this->resource, $viewer);
        $hidePrivateLocation = StayPrivacy::hidesPrivateAddress($this->resource, $viewer);

        return [
            'id' => $this->id,
            'trip_id' => $this->trip_id,
            'place_id' => $this->place_id,
            'name' => $this->name,
            'stay_type' => $this->stay_type,
            'address' => $hidePrivateLocation ? null : $this->address,
            'latitude' => $hidePrivateLocation ? null : $this->latitude,
            'longitude' => $hidePrivateLocation ? null : $this->longitude,
            'check_in_at' => $this->check_in_at?->toIso8601String(),
            'check_out_at' => $this->check_out_at?->toIso8601String(),
            'timezone' => $this->timezone,
            'phone' => $isOwner ? $this->phone : null,
            'booking_reference' => $isOwner ? $this->booking_reference : null,
            'notes' => $hidePrivateLocation ? null : $this->notes,
            'luggage_profile' => $this->luggage_profile,
            'version' => $this->version,
            'google_maps_url' => $hidePrivateLocation ? null : $this->google_maps_url,
            'google_maps_directions_url' => $hidePrivateLocation ? null : $this->google_maps_directions_url,
            'nearest_transit' => $hidePrivateLocation ? null : (new StayTransitService)->resolve($this->resource),
            'place' => new PlaceResource($this->whenLoaded('place')),
            'itinerary_items' => ItineraryItemResource::collection($this->whenLoaded('itineraryItems')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
