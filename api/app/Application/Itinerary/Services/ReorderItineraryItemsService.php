<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Services;

use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Trips\Models\Trip;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class ReorderItineraryItemsService
{
    /**
     * @param  array<int, string>  $orderedItemIds
     * @return Collection<int, ItineraryItem>
     */
    public function handle(Trip $trip, array $orderedItemIds): Collection
    {
        return DB::transaction(function () use ($trip, $orderedItemIds): Collection {
            /** @var Collection<int, ItineraryItem> $items */
            $items = ItineraryItem::query()
                ->where('trip_id', $trip->id)
                ->whereIn('id', $orderedItemIds)
                ->get()
                ->keyBy('id');

            if ($items->count() !== count($orderedItemIds)) {
                throw ValidationException::withMessages([
                    'item_ids' => ['One or more itinerary item IDs do not belong to this trip.'],
                ]);
            }

            foreach ($orderedItemIds as $index => $id) {
                $item = $items->get($id);
                if ($item !== null && $item->sort_order !== $index) {
                    $item->update([
                        'sort_order' => $index,
                        'version' => $item->version + 1,
                    ]);
                }
            }

            return ItineraryItem::query()
                ->where('trip_id', $trip->id)
                ->whereIn('id', $orderedItemIds)
                ->with(['place', 'day'])
                ->orderBy('sort_order')
                ->get();
        });
    }
}
