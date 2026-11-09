<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Services;

use App\Application\Itinerary\Data\ApplyAiItineraryData;
use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Itinerary\Models\Place;
use App\Domain\Itinerary\Models\TripDay;
use App\Domain\Trips\Models\Trip;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class ApplyAiItineraryService
{
    /**
     * @return Collection<int, ItineraryItem>
     */
    public function execute(Trip $trip, ApplyAiItineraryData $data): Collection
    {
        $createdItems = new Collection;
        $startDate = $trip->start_date ? Carbon::parse($trip->start_date) : Carbon::today();
        $timezone = $trip->primary_timezone ?: 'UTC';

        DB::transaction(function () use ($trip, $data, $startDate, $timezone, &$createdItems): void {
            foreach ($data->days as $dayData) {
                $dayNumber = (int) ($dayData['day_number'] ?? 1);
                $localDate = $startDate->copy()->addDays($dayNumber - 1)->toDateString();
                $dayTitle = (string) ($dayData['title'] ?? "Day {$dayNumber}");

                $tripDay = TripDay::firstOrCreate(
                    [
                        'trip_id' => $trip->id,
                        'local_date' => $localDate,
                    ],
                    [
                        'notes' => $dayTitle,
                    ]
                );

                $currentMaxOrder = (int) ItineraryItem::where('trip_day_id', $tripDay->id)->max('sort_order');
                $activities = $dayData['activities'] ?? [];

                foreach ($activities as $activity) {
                    $placeId = null;
                    $placeName = $activity['place_name'] ?? null;

                    if ($placeName !== null && $placeName !== '') {
                        $lat = isset($activity['latitude']) && $activity['latitude'] !== null ? (float) $activity['latitude'] : null;
                        $lng = isset($activity['longitude']) && $activity['longitude'] !== null ? (float) $activity['longitude'] : null;

                        $place = Place::create([
                            'name' => (string) $placeName,
                            'formatted_address' => (string) ($activity['place_address'] ?? $placeName),
                            'latitude' => $lat,
                            'longitude' => $lng,
                            'provider' => 'ai_planner',
                            'provider_place_id' => 'place_'.Str::random(16),
                        ]);
                        $placeId = $place->id;
                    }

                    $currentMaxOrder++;

                    $startsAtUtc = null;
                    if (! empty($activity['planned_start_time'])) {
                        try {
                            if (preg_match('/^\d{1,2}:\d{2}/', (string) $activity['planned_start_time'])) {
                                $startsAtUtc = Carbon::parse("{$localDate} {$activity['planned_start_time']}", $timezone)->utc()->toIso8601String();
                            } else {
                                $startsAtUtc = Carbon::parse($activity['planned_start_time'], $timezone)->utc()->toIso8601String();
                            }
                        } catch (\Throwable) {
                            $startsAtUtc = null;
                        }
                    }

                    $endsAtUtc = null;
                    if (! empty($activity['planned_end_time'])) {
                        try {
                            if (preg_match('/^\d{1,2}:\d{2}/', (string) $activity['planned_end_time'])) {
                                $endsAtUtc = Carbon::parse("{$localDate} {$activity['planned_end_time']}", $timezone)->utc()->toIso8601String();
                            } else {
                                $endsAtUtc = Carbon::parse($activity['planned_end_time'], $timezone)->utc()->toIso8601String();
                            }
                        } catch (\Throwable) {
                            $endsAtUtc = null;
                        }
                    }

                    $item = ItineraryItem::create([
                        'trip_id' => $trip->id,
                        'trip_day_id' => $tripDay->id,
                        'place_id' => $placeId,
                        'title' => (string) $activity['title'],
                        'kind' => substr((string) ($activity['kind'] ?? 'sightseeing'), 0, 32),
                        'status' => 'planned',
                        'notes' => isset($activity['description']) ? (string) $activity['description'] : null,
                        'starts_at_utc' => $startsAtUtc,
                        'ends_at_utc' => $endsAtUtc,
                        'timezone' => $timezone,
                        'sort_order' => $currentMaxOrder,
                        'version' => 1,
                    ]);

                    $createdItems->push($item->load(['place', 'day']));
                }
            }

            // Bump trip version
            $trip->increment('version');
        });

        return $createdItems;
    }
}
