<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Application\Trips\Data\TodaySummaryResult;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @property-read TodaySummaryResult $resource
 */
final class TodaySummaryResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'trip' => new TripResource($this->resource->trip),
            'trip_status' => $this->resource->tripStatus,
            'days_until_start' => $this->resource->daysUntilStart,
            'active_day' => $this->resource->activeDay,
            'today_items' => ItineraryItemResource::collection($this->resource->todayItems),
            'next_upcoming_item' => $this->resource->nextUpcomingItem
                ? new ItineraryItemResource($this->resource->nextUpcomingItem)
                : null,
            'current_stay' => $this->resource->currentStay
                ? new StayResource($this->resource->currentStay)
                : null,
            'metrics' => $this->resource->metrics,
            'budget_pacing' => $this->resource->budgetPacing,
            'weather' => $this->resource->weather?->toArray(),
            'timezone' => $this->resource->timezone,
            'local_time' => $this->resource->localTime,
        ];
    }
}
