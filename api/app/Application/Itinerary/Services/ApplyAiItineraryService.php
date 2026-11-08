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

        DB::transaction(function () use ($trip, $data, $startDate, &$createdItems): void {
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
                        $place = Place::create([
                            'name' => (string) $placeName,
                            'formatted_address' => (string) ($activity['place_address'] ?? $placeName),
                            'latitude' => isset($activity['latitude']) ? (float) $activity['latitude'] : 35.6762,
                            'longitude' => isset($activity['longitude']) ? (float) $activity['longitude'] : 139.6503,
                            'google_place_id' => 'place_'.Str::random(16),
                            'source' => 'ai_planner',
                        ]);
                        $placeId = $place->id;
                    }

                    $currentMaxOrder++;

                    $item = ItineraryItem::create([
                        'trip_id' => $trip->id,
                        'trip_day_id' => $tripDay->id,
                        'place_id' => $placeId,
                        'title' => (string) $activity['title'],
                        'kind' => (string) ($activity['kind'] ?? 'sightseeing'),
                        'status' => 'planned',
                        'notes' => isset($activity['description']) ? (string) $activity['description'] : null,
                        'planned_start_time' => $activity['planned_start_time'] ?? null,
                        'planned_end_time' => $activity['planned_end_time'] ?? null,
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
