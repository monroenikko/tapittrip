<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\DTOs\Recap\TripRecapData;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripRecapData
 */
final class TripRecapResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $data = $this->resource instanceof TripRecapData
            ? $this->resource->toArray()
            : (array) $this->resource;

        if (isset($data['story_album']['mood_breakdown']) && empty($data['story_album']['mood_breakdown'])) {
            $data['story_album']['mood_breakdown'] = (object) [];
        }

        return $data;
    }
}
