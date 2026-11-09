<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Application\Weather\Data\TripWeatherData;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @property-read TripWeatherData $resource
 */
final class TripWeatherResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return $this->resource->toArray();
    }
}
