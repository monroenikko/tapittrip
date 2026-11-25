<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\DTOs\Itinerary\TripAssistantResult;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin TripAssistantResult */
final class StayRecommendationResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return $this->resource->toArray();
    }
}
