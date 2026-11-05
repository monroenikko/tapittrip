<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Services;

use App\Application\Itinerary\Data\CreateItineraryItemData;
use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Facades\DB;

final class CreateItineraryItemService
{
    public function __construct(
        private CreatePlaceService $createPlaceService,
    ) {}

    public function handle(Trip $trip, CreateItineraryItemData $data): ItineraryItem
    {
        return DB::transaction(function () use ($trip, $data): ItineraryItem {
            $placeId = $data->placeId;

            if ($data->place !== null) {
                $place = $this->createPlaceService->handle($data->place);
                $placeId = $place->id;
            }

            $sortOrder = $data->sortOrder;
            if ($sortOrder === null) {
                $maxSort = ItineraryItem::query()
                    ->where('trip_id', $trip->id)
                    ->when($data->tripDayId !== null, fn ($q) => $q->where('trip_day_id', $data->tripDayId))
                    ->max('sort_order');

                $sortOrder = $maxSort !== null ? ((int) $maxSort) + 1 : 0;
            }

            /** @var ItineraryItem $item */
            $item = ItineraryItem::query()->create([
                'trip_id' => $trip->id,
                'trip_day_id' => $data->tripDayId,
                'place_id' => $placeId,
                'kind' => $data->kind,
                'title' => $data->title,
                'notes' => $data->notes,
                'starts_at_utc' => $data->startsAtUtc,
                'ends_at_utc' => $data->endsAtUtc,
                'timezone' => $data->timezone,
                'sort_order' => $sortOrder,
                'status' => $data->status,
                'version' => 1,
            ]);

            return $item->load(['place', 'day']);
        });
    }
}
