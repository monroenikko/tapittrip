<?php

declare(strict_types=1);

namespace App\Services\Itinerary;

use App\DTOs\Itinerary\CreateItineraryItemData;
use App\DTOs\Itinerary\CreatePlaceData;
use App\Http\Resources\Api\V1\ItineraryItemResource;
use App\Models\ItineraryItem;
use App\Models\Trip;
use App\Models\TripDay;
use App\Services\Notifications\NotificationService;
use Illuminate\Support\Facades\DB;

final class SmartReplanService
{
    public function __construct(
        private readonly ItineraryService $itineraryService,
    ) {}

    /**
     * Propose or apply a non-destructive in-trip itinerary replan while preserving all visited stops and memories.
     *
     * @param  array<string, mixed>  $options
     * @return array<string, mixed>
     */
    public function replan(Trip $trip, array $options): array
    {
        $triggerReason = (string) ($options['trigger_reason'] ?? 'rain_weather');
        $requestedDayId = isset($options['trip_day_id']) && is_string($options['trip_day_id']) && trim($options['trip_day_id']) !== ''
            ? trim($options['trip_day_id'])
            : null;
        $apply = (bool) ($options['apply'] ?? false);
        $delayMinutes = isset($options['delay_minutes']) ? (int) $options['delay_minutes'] : 120;

        $allItems = $this->itineraryService->getTripItems($trip, $requestedDayId);
        $targetDayId = $requestedDayId;

        if ($targetDayId === null) {
            $firstUnvisited = $allItems->first(static fn (ItineraryItem $it): bool => $it->status !== 'visited' && $it->trip_day_id !== null);
            if ($firstUnvisited !== null) {
                $targetDayId = $firstUnvisited->trip_day_id;
            } else {
                /** @var TripDay|null $firstDay */
                $firstDay = $trip->days()->orderBy('local_date')->first();
                $targetDayId = $firstDay?->id;
            }
        }

        $visitedItems = $allItems->filter(static fn (ItineraryItem $it): bool => $it->status === 'visited');
        $unvisitedItems = $allItems->filter(static fn (ItineraryItem $it): bool => $it->status !== 'visited');

        $proposedChanges = [];
        foreach ($visitedItems as $visited) {
            $proposedChanges[] = [
                'action' => 'keep_visited',
                'target_item_id' => $visited->id,
                'title' => $visited->title,
                'kind' => $visited->kind,
                'place_name' => $visited->place?->name,
                'notes' => $visited->notes,
                'reason' => 'Completed activity & past memory preserved untouched.',
                'starts_at_utc' => $visited->starts_at_utc?->toIso8601String(),
                'ends_at_utc' => $visited->ends_at_utc?->toIso8601String(),
            ];
        }

        $destination = trim($trip->title) !== '' ? trim($trip->title) : 'Destination';

        if ($triggerReason === 'rain_weather') {
            $summary = "Rainy-weather adjustment for {$destination}: preserved {$visitedItems->count()} visited stop(s) and added sheltered indoor cultural & dining alternatives.";
            $proposedChanges[] = [
                'action' => 'add_alternative',
                'target_item_id' => null,
                'title' => "Covered Arcade & Indoor Cultural Hall ({$destination})",
                'kind' => 'attraction',
                'place_name' => "{$destination} Covered Shopping Arcade & Food Hall",
                'notes' => 'Sheltered all-weather gallery, museum exhibition, and indoor food hall backup.',
                'reason' => 'All-weather indoor alternative for rain or storm forecast.',
                'starts_at_utc' => null,
                'ends_at_utc' => null,
            ];
        } elseif ($triggerReason === 'flight_delay') {
            $summary = "Flight-delay adjustment (+{$delayMinutes} min) for {$destination}: shifted timed upcoming activities forward while preserving {$visitedItems->count()} visited stop(s).";
            foreach ($unvisitedItems as $item) {
                if ($item->starts_at_utc !== null && ! in_array($item->kind, ['flight'], true)) {
                    $newStart = $item->starts_at_utc->copy()->addMinutes($delayMinutes);
                    $newEnd = $item->ends_at_utc?->copy()->addMinutes($delayMinutes);
                    $proposedChanges[] = [
                        'action' => 'shift_time',
                        'target_item_id' => $item->id,
                        'title' => $item->title,
                        'kind' => $item->kind,
                        'place_name' => $item->place?->name,
                        'notes' => $item->notes,
                        'reason' => "Shifted forward by {$delayMinutes} minutes due to arrival/transit delay.",
                        'starts_at_utc' => $newStart->toIso8601String(),
                        'ends_at_utc' => $newEnd?->toIso8601String(),
                    ];
                }
            }
            $proposedChanges[] = [
                'action' => 'add_alternative',
                'target_item_id' => null,
                'title' => 'Relaxed Late-Arrival Check-In & Nearby Supper',
                'kind' => 'meal',
                'place_name' => "Neighborhood Late Dining ({$destination})",
                'notes' => 'Low-stress arrival meal within walking distance of your accommodation.',
                'reason' => 'Replaces rushed arrival schedule after flight delay.',
                'starts_at_utc' => null,
                'ends_at_utc' => null,
            ];
        } elseif ($triggerReason === 'skipped_stop') {
            $skippedCount = $unvisitedItems->where('status', 'skipped')->count();
            $summary = "Open-window adjustment for {$destination}: filled time freed by {$skippedCount} skipped stop(s) while preserving {$visitedItems->count()} visited stop(s).";
            $proposedChanges[] = [
                'action' => 'add_alternative',
                'target_item_id' => null,
                'title' => "Flexible Neighborhood Cafe & Market Stroll ({$destination})",
                'kind' => 'custom',
                'place_name' => "{$destination} Local Artisanal District",
                'notes' => 'No reservation required; ideal for filling an open afternoon window.',
                'reason' => 'Replaces skipped stop with a low-friction nearby alternative.',
                'starts_at_utc' => null,
                'ends_at_utc' => null,
            ];
        } else {
            // tired_family_pacing
            $summary = "Family & toddler pacing adjustment for {$destination}: added a 2-hour midday recharge buffer while preserving {$visitedItems->count()} visited stop(s).";
            $proposedChanges[] = [
                'action' => 'add_alternative',
                'target_item_id' => null,
                'title' => 'Midday Hotel Rest & Toddler Recharge Buffer',
                'kind' => 'custom',
                'place_name' => $trip->stays()->value('name') ?? "{$destination} Quiet Park / Stay",
                'notes' => '2-hour quiet rest window (1:30 PM – 3:30 PM) to avoid afternoon transit fatigue.',
                'reason' => 'Reduces walking fatigue for families and young travelers.',
                'starts_at_utc' => null,
                'ends_at_utc' => null,
            ];
        }

        $applied = false;
        if ($apply) {
            DB::transaction(function () use ($trip, $targetDayId, $proposedChanges, &$applied): void {
                foreach ($proposedChanges as $change) {
                    if ($change['action'] === 'shift_time' && is_string($change['target_item_id'])) {
                        /** @var ItineraryItem|null $locked */
                        $locked = ItineraryItem::query()
                            ->where('trip_id', $trip->id)
                            ->where('id', $change['target_item_id'])
                            ->where('status', '!=', 'visited')
                            ->lockForUpdate()
                            ->first();

                        if ($locked !== null) {
                            $locked->update([
                                'starts_at_utc' => $change['starts_at_utc'],
                                'ends_at_utc' => $change['ends_at_utc'],
                                'version' => $locked->version + 1,
                            ]);
                            app(NotificationService::class)->syncRemindersForItineraryItem($locked);
                        }
                    } elseif ($change['action'] === 'add_alternative') {
                        $placeName = is_string($change['place_name'] ?? null) && trim($change['place_name']) !== ''
                            ? trim($change['place_name'])
                            : null;

                        $this->itineraryService->createItem(
                            $trip,
                            new CreateItineraryItemData(
                                title: (string) $change['title'],
                                kind: (string) ($change['kind'] ?? 'custom'),
                                tripDayId: $targetDayId,
                                placeId: null,
                                place: $placeName !== null
                                    ? new CreatePlaceData(
                                        name: $placeName,
                                        provider: 'manual',
                                    )
                                    : null,
                                notes: is_string($change['notes'] ?? null) ? $change['notes'] : null,
                                startsAtUtc: null,
                                endsAtUtc: null,
                                timezone: $trip->primary_timezone ?? 'UTC',
                                sortOrder: null,
                                status: 'planned',
                            ),
                        );
                    }
                }
                $applied = true;
            });
        }

        $updatedItems = $this->itineraryService->getTripItems($trip, $requestedDayId);

        return [
            'trip_id' => $trip->id,
            'trip_day_id' => $targetDayId,
            'trigger_reason' => $triggerReason,
            'applied' => $applied,
            'preserved_visited_count' => $visitedItems->count(),
            'summary' => $summary,
            'proposed_changes' => $proposedChanges,
            'items' => ItineraryItemResource::collection($updatedItems)->resolve(),
            'provider_attribution' => 'TapItTrip Smart Replanning Engine (Non-Destructive Advisory)',
            'verified' => false,
            'advisory_notice' => 'Replanning proposals never delete or overwrite visited stops or travel memories. Review proposed additions before applying.',
        ];
    }
}
