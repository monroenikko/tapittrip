<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\Flight;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Flight */
final class FlightResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $isOwner = $this->trip?->owner_id === $request->user()?->id;

        return [
            'id' => (string) $this->id,
            'trip_id' => (string) $this->trip_id,
            'airline' => $this->airline,
            'booking_reference' => $isOwner ? $this->booking_reference : null,
            'version' => $this->version,
            'segments' => $this->whenLoaded('segments', fn () => $this->segments->map(fn ($segment) => [
                'id' => (string) $segment->id, 'flight_number' => $segment->flight_number,
                'origin_airport' => $segment->origin_airport, 'destination_airport' => $segment->destination_airport,
                'scheduled_departure_utc' => $segment->scheduled_departure_utc?->toIso8601String(),
                'scheduled_arrival_utc' => $segment->scheduled_arrival_utc?->toIso8601String(),
                'origin_timezone' => $segment->origin_timezone, 'destination_timezone' => $segment->destination_timezone,
                'terminal' => $segment->terminal,
                'gate' => $segment->gate,
            ])),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
