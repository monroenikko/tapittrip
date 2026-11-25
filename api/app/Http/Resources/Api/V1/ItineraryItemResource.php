<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\ItineraryItem;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ItineraryItem
 */
final class ItineraryItemResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $votes = $this->relationLoaded('votes')
            ? $this->votes
            : $this->votes()->get();

        $viewerId = $request->user()?->id;
        $upvotesCount = $votes->where('vote', 'up')->count();
        $downvotesCount = $votes->where('vote', 'down')->count();
        $viewerVote = $viewerId !== null
            ? $votes->firstWhere('user_id', $viewerId)?->vote
            : null;

        return [
            'id' => $this->id,
            'trip_id' => $this->trip_id,
            'trip_day_id' => $this->trip_day_id,
            'place_id' => $this->place_id,
            'kind' => $this->kind,
            'title' => $this->title,
            'notes' => $this->notes,
            'starts_at_utc' => $this->starts_at_utc?->toIso8601String(),
            'ends_at_utc' => $this->ends_at_utc?->toIso8601String(),
            'timezone' => $this->timezone,
            'sort_order' => $this->sort_order,
            'status' => $this->status,
            'version' => $this->version,
            'upvotes_count' => $upvotesCount,
            'downvotes_count' => $downvotesCount,
            'viewer_vote' => $viewerVote,
            'place' => new PlaceResource($this->whenLoaded('place')),
            'day' => new TripDayResource($this->whenLoaded('day')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
