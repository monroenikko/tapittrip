<?php

declare(strict_types=1);

namespace App\Services\Itinerary;

use App\DTOs\Itinerary\CreateItineraryItemData;
use App\DTOs\Itinerary\RecordVisitEventData;
use App\DTOs\Itinerary\UpdateItineraryItemData;
use App\Models\ItineraryItem;
use App\Models\Trip;
use App\Models\TripDay;
use App\Models\User;
use App\Models\VisitEvent;
use Carbon\Carbon;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class ItineraryService
{
    public function __construct(
        private readonly PlaceService $placeService,
    ) {}

    /**
     * List itinerary items for a trip with optional day filter.
     *
     * @return Collection<int, ItineraryItem>
     */
    public function getTripItems(Trip $trip, ?string $tripDayId = null): Collection
    {
        $query = $trip->itineraryItems()->with(['place', 'day']);

        if ($tripDayId !== null && trim($tripDayId) !== '') {
            $query->where('trip_day_id', $tripDayId);
        }

        return $query->get();
    }

    /**
     * List all days for a trip, auto-populating missing days from start_date to end_date.
     *
     * @return Collection<int, TripDay>
     */
    public function getTripDays(Trip $trip): Collection
    {
        if ($trip->start_date !== null && $trip->end_date !== null) {
            return $this->ensureDaysForTrip($trip);
        }

        return $trip->days()->orderBy('local_date')->get();
    }

    /**
     * Ensure all days between trip start_date and end_date are populated.
     *
     * @return Collection<int, TripDay>
     */
    public function ensureDaysForTrip(Trip $trip): Collection
    {
        if ($trip->start_date === null || $trip->end_date === null) {
            return $trip->days()->orderBy('local_date')->get();
        }

        $start = CarbonImmutable::parse($trip->start_date);
        $end = CarbonImmutable::parse($trip->end_date);

        if ($end->lessThan($start)) {
            $end = $start;
        }

        $current = $start;
        $dayNumber = 1;

        while ($current->lessThanOrEqualTo($end)) {
            $dateString = $current->format('Y-m-d');

            /** @var TripDay|null $existing */
            $existing = TripDay::withTrashed()
                ->where('trip_id', $trip->id)
                ->where('local_date', $dateString)
                ->first();

            if ($existing !== null) {
                if ($existing->trashed()) {
                    $existing->restore();
                }
                if ($existing->notes === null || trim($existing->notes) === '') {
                    $existing->update(['notes' => "Day {$dayNumber}"]);
                }
            } else {
                TripDay::create([
                    'trip_id' => $trip->id,
                    'local_date' => $dateString,
                    'notes' => "Day {$dayNumber}",
                ]);
            }

            $current = $current->addDay();
            $dayNumber++;
        }

        return $trip->days()->orderBy('local_date')->get();
    }

    /**
     * Create a new itinerary item / activity.
     */
    public function createItem(Trip $trip, CreateItineraryItemData $data): ItineraryItem
    {
        return DB::transaction(function () use ($trip, $data): ItineraryItem {
            $placeId = $data->placeId;

            if ($data->place !== null) {
                $place = $this->placeService->createPlace($data->place);
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

    /**
     * Update an itinerary item.
     */
    public function updateItem(ItineraryItem $item, UpdateItineraryItemData $data): ItineraryItem
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
                $place = $this->placeService->createPlace($data->place);
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

    /**
     * Delete an itinerary item.
     */
    public function deleteItem(ItineraryItem $item): void
    {
        DB::transaction(function () use ($item): void {
            $item->delete();
        });
    }

    /**
     * Reorder itinerary items by their IDs and optional day reassignments.
     *
     * @param  array<int, string>  $orderedItemIds
     * @param  array<string, string|null>  $dayAssignments
     * @return Collection<int, ItineraryItem>
     */
    public function reorderItems(Trip $trip, array $orderedItemIds, array $dayAssignments = []): Collection
    {
        return DB::transaction(function () use ($trip, $orderedItemIds, $dayAssignments): Collection {
            /** @var Collection<string, ItineraryItem> $items */
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

            if ($dayAssignments !== []) {
                foreach ($dayAssignments as $itemId => $dayId) {
                    if (! $items->has((string) $itemId)) {
                        throw ValidationException::withMessages([
                            'day_assignments' => ['Day assignments must reference items included in the reorder list.'],
                        ]);
                    }
                }

                $nonNullDayIds = array_values(array_unique(array_filter(
                    $dayAssignments,
                    static fn (?string $dayId): bool => $dayId !== null && $dayId !== '',
                )));

                if ($nonNullDayIds !== []) {
                    $validDayCount = TripDay::query()
                        ->where('trip_id', $trip->id)
                        ->whereIn('id', $nonNullDayIds)
                        ->count();

                    if ($validDayCount !== count($nonNullDayIds)) {
                        throw ValidationException::withMessages([
                            'day_assignments' => ['One or more target trip days do not belong to this trip.'],
                        ]);
                    }
                }
            }

            foreach ($orderedItemIds as $index => $id) {
                $item = $items->get($id);
                if ($item === null) {
                    continue;
                }

                $updates = [];
                if ($item->sort_order !== $index) {
                    $updates['sort_order'] = $index;
                }

                if (array_key_exists($id, $dayAssignments)) {
                    $targetDayId = $dayAssignments[$id] !== '' ? $dayAssignments[$id] : null;
                    if ($item->trip_day_id !== $targetDayId) {
                        $updates['trip_day_id'] = $targetDayId;
                    }
                }

                if ($updates !== []) {
                    $updates['version'] = $item->version + 1;
                    $item->update($updates);
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

    /**
     * Ensure a trip day exists for a given local date.
     */
    public function ensureTripDay(Trip $trip, string $localDate, ?string $notes = null): TripDay
    {
        return DB::transaction(function () use ($trip, $localDate, $notes): TripDay {
            /** @var TripDay $day */
            $day = TripDay::query()->firstOrCreate(
                [
                    'trip_id' => $trip->id,
                    'local_date' => $localDate,
                ],
                [
                    'notes' => $notes,
                ]
            );

            if ($notes !== null && $day->notes !== $notes) {
                $day->update(['notes' => $notes]);
            }

            return $day;
        });
    }

    /**
     * Record a visit event (suggested, confirmed, revoked) for an itinerary item.
     */
    public function recordVisitEvent(ItineraryItem $item, User $user, RecordVisitEventData $data): VisitEvent
    {
        $detectedAt = $data->detectedAt ? Carbon::parse($data->detectedAt) : now();

        $event = VisitEvent::create([
            'itinerary_item_id' => $item->id,
            'user_id' => $user->id,
            'event_type' => $data->eventType,
            'method' => $data->method,
            'detected_at' => $detectedAt,
            'accuracy_m' => $data->accuracyM,
        ]);

        if ($data->eventType === 'confirmed') {
            $item->update(['status' => 'visited']);
        } elseif ($data->eventType === 'revoked') {
            $item->update(['status' => 'planned']);
        }

        return $event;
    }
}
