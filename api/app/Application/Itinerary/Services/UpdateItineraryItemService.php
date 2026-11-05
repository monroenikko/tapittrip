<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Services;

use App\Application\Itinerary\Data\UpdateItineraryItemData;
use App\Domain\Itinerary\Models\ItineraryItem;
use Illuminate\Support\Facades\DB;

final class UpdateItineraryItemService
{
    public function __construct(
        private CreatePlaceService $createPlaceService,
    ) {}

    public function handle(ItineraryItem $item, UpdateItineraryItemData $data): ItineraryItem
    {
        return DB::transaction(function () use ($item, $data): ItineraryItem {
            $updates = [];

            if ($data->title !== null) {
                $updates['title'] = $data->title;
            }

            if ($data->kind !== null) {
                $updates['kind'] = $data->kind;
            }

            if ($data->tripDayId !== null) {
                $updates['trip_day_id'] = $data->tripDayId;
            } elseif ($data->clearTripDay) {
                $updates['trip_day_id'] = null;
            }

            if ($data->place !== null) {
                $place = $this->createPlaceService->handle($data->place);
                $updates['place_id'] = $place->id;
            } elseif ($data->placeId !== null) {
                $updates['place_id'] = $data->placeId;
            } elseif ($data->clearPlace) {
                $updates['place_id'] = null;
            }

            if ($data->notes !== null) {
                $updates['notes'] = $data->notes;
            } elseif ($data->clearNotes) {
                $updates['notes'] = null;
            }

            if ($data->startsAtUtc !== null) {
                $updates['starts_at_utc'] = $data->startsAtUtc;
            } elseif ($data->clearStartsAtUtc) {
                $updates['starts_at_utc'] = null;
            }

            if ($data->endsAtUtc !== null) {
                $updates['ends_at_utc'] = $data->endsAtUtc;
            } elseif ($data->clearEndsAtUtc) {
                $updates['ends_at_utc'] = null;
            }

            if ($data->timezone !== null) {
                $updates['timezone'] = $data->timezone;
            }

            if ($data->sortOrder !== null) {
                $updates['sort_order'] = $data->sortOrder;
            }

            if ($data->status !== null) {
                $updates['status'] = $data->status;
            }

            if ($updates !== []) {
                $updates['version'] = $item->version + 1;
                $item->update($updates);
            }

            return $item->load(['place', 'day']);
        });
    }
}
