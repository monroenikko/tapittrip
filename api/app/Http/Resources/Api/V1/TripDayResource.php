<?php

declare(strict_types=1);

namespace App\Http\Resources\Api\V1;

use App\Models\TripDay;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripDay
 */
final class TripDayResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $dayNumber = 1;
        $trip = $this->trip;
        if ($trip !== null && $trip->start_date !== null && $this->local_date !== null) {
            $startDate = CarbonImmutable::parse($trip->start_date);
            $currentDate = CarbonImmutable::parse($this->local_date);
            $diff = $startDate->diffInDays($currentDate, false);
            $dayNumber = max(1, (int) $diff + 1);
        }

        return [
            'id' => $this->id,
            'trip_id' => $this->trip_id,
            'day_number' => $dayNumber,
            'title' => $this->notes ?: "Day {$dayNumber}",
            'local_date' => $this->local_date?->format('Y-m-d'),
            'notes' => $this->notes,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
