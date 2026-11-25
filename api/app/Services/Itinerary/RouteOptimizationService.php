<?php

declare(strict_types=1);

namespace App\Services\Itinerary;

use App\Domain\Stays\StayPrivacy;
use App\Http\Resources\Api\V1\ItineraryItemResource;
use App\Models\ItineraryItem;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;

final class RouteOptimizationService
{
    private const EARTH_RADIUS_METERS = 6371000.0;

    private const URBAN_DETOUR_FACTOR = 1.3;

    public function __construct(
        private readonly ItineraryService $itineraryService,
    ) {}

    /**
     * Evaluate stop-to-stop transit segments and optionally optimize itinerary route order with constraints.
     *
     * @param  array<string, mixed>  $options
     * @return array<string, mixed>
     */
    public function optimize(Trip $trip, array $options = [], ?User $viewer = null): array
    {
        $tripDayId = isset($options['trip_day_id']) && is_string($options['trip_day_id']) && trim($options['trip_day_id']) !== ''
            ? trim($options['trip_day_id'])
            : null;
        $apply = (bool) ($options['apply'] ?? false);
        $preserveFixedTimes = (bool) ($options['preserve_fixed_times'] ?? true);
        $maxWalkingMeters = (int) ($options['max_walking_meters_per_leg'] ?? 1500);
        /** @var array<string, int> $expectedVersions */
        $expectedVersions = is_array($options['expected_versions'] ?? null) ? $options['expected_versions'] : [];

        $items = $this->itineraryService->getTripItems($trip, $tripDayId);

        /** @var Stay|null $primaryStay */
        $primaryStay = $trip->stays()
            ->orderBy('check_in_at')
            ->first();

        $hideStayCoords = $primaryStay !== null && $viewer !== null && StayPrivacy::hidesPrivateAddress($primaryStay, $viewer);
        $anchorCoords = ($primaryStay !== null && ! $hideStayCoords && $primaryStay->latitude !== null && $primaryStay->longitude !== null)
            ? ['lat' => (float) $primaryStay->latitude, 'lng' => (float) $primaryStay->longitude, 'name' => $primaryStay->name]
            : null;

        // Group items by trip_day_id (preserving day order) so items never jump across calendar days.
        /** @var array<string, list<ItineraryItem>> $groupedByDay */
        $groupedByDay = [];
        foreach ($items as $item) {
            $dayKey = $item->trip_day_id ?? '__unscheduled__';
            $groupedByDay[$dayKey][] = $item;
        }

        $currentOrdered = [];
        $proposedOrdered = [];
        $pinnedItemIds = [];
        $currentDistanceMeters = 0.0;
        $optimizedDistanceMeters = 0.0;

        foreach ($groupedByDay as $dayItems) {
            foreach ($dayItems as $item) {
                $currentOrdered[] = $item;
                if ($this->isFixedAnchor($item, $preserveFixedTimes)) {
                    $pinnedItemIds[] = $item->id;
                }
            }

            $currentDistanceMeters += $this->calculateGroupDistanceMeters($dayItems, $anchorCoords);

            $optimizedDayItems = $this->optimizeDayGroup($dayItems, $preserveFixedTimes, $anchorCoords);
            $optimizedDistanceMeters += $this->calculateGroupDistanceMeters($optimizedDayItems, $anchorCoords);

            foreach ($optimizedDayItems as $optItem) {
                $proposedOrdered[] = $optItem;
            }
        }

        $currentItemIds = array_map(static fn (ItineraryItem $it): string => $it->id, $currentOrdered);
        $proposedItemIds = array_map(static fn (ItineraryItem $it): string => $it->id, $proposedOrdered);
        $isAlreadyOptimal = $currentItemIds === $proposedItemIds;

        $applied = false;
        $activeItems = $proposedOrdered;

        if ($apply && ! $isAlreadyOptimal && $proposedItemIds !== []) {
            $reorderedCollection = $this->itineraryService->reorderItems(
                $trip,
                $proposedItemIds,
                [],
                $expectedVersions,
            );
            $applied = true;
            $activeItems = $this->sortItemsByProposedOrder($reorderedCollection, $proposedItemIds);
        } elseif (! $apply) {
            // In preview mode, segments reflect the proposed order so travelers can inspect the route legs.
            $activeItems = $proposedOrdered;
        }

        $currentKm = round($currentDistanceMeters / 1000.0, 2);
        $optimizedKm = round($optimizedDistanceMeters / 1000.0, 2);
        $savedKm = max(0.0, round($currentKm - $optimizedKm, 2));
        // Transparent advisory estimate: ~0.12 kg CO2 per km of avoided motorized urban backtracking
        $co2SavedKg = round($savedKm * 0.12, 2);

        $segments = $this->buildTransitSegments($activeItems, $maxWalkingMeters, $trip->title);

        return [
            'trip_id' => $trip->id,
            'trip_day_id' => $tripDayId,
            'applied' => $applied,
            'is_already_optimal' => $isAlreadyOptimal,
            'current_item_ids' => $currentItemIds,
            'proposed_item_ids' => $proposedItemIds,
            'pinned_item_ids' => array_values(array_unique($pinnedItemIds)),
            'current_total_distance_km' => $currentKm,
            'optimized_total_distance_km' => $optimizedKm,
            'distance_saved_km' => $savedKm,
            'estimated_co2_saved_kg' => $co2SavedKg,
            'constraints_applied' => [
                'preserve_fixed_times' => $preserveFixedTimes,
                'max_walking_meters_per_leg' => $maxWalkingMeters,
                'anchor_stay_name' => $anchorCoords['name'] ?? null,
            ],
            'segments' => $segments,
            'items' => ItineraryItemResource::collection(new Collection($activeItems))->resolve(),
            'provider_attribution' => 'TapItTrip Geometric Route Optimizer & Google Maps Directions',
            'verified' => false,
            'advisory_notice' => 'Distances and durations use Haversine geometry with a 1.3x urban route factor. Live traffic, transit schedules, and fares are not verified. Confirm final directions in your maps app.',
        ];
    }

    /**
     * Optimize a single day's items while respecting fixed-time or hotel/flight anchors.
     *
     * @param  list<ItineraryItem>  $dayItems
     * @param  array{lat: float, lng: float, name: string}|null  $anchorCoords
     * @return list<ItineraryItem>
     */
    private function optimizeDayGroup(array $dayItems, bool $preserveFixedTimes, ?array $anchorCoords): array
    {
        if (count($dayItems) <= 1) {
            return $dayItems;
        }

        // Identify fixed index positions vs flexible items
        /** @var array<int, ItineraryItem> $fixedBySlot */
        $fixedBySlot = [];
        /** @var list<ItineraryItem> $flexibleWithCoords */
        $flexibleWithCoords = [];
        /** @var list<ItineraryItem> $flexibleWithoutCoords */
        $flexibleWithoutCoords = [];

        foreach ($dayItems as $index => $item) {
            if ($this->isFixedAnchor($item, $preserveFixedTimes)) {
                $fixedBySlot[$index] = $item;
            } elseif ($this->hasCoordinates($item)) {
                $flexibleWithCoords[] = $item;
            } else {
                $flexibleWithoutCoords[] = $item;
            }
        }

        if (count($flexibleWithCoords) <= 1) {
            return $dayItems;
        }

        // If no stay anchor exists and slot 0 is flexible with coordinates, keep the user's first chosen stop
        // as the starting anchor of the day unless a stay coordinate anchor is available.
        $currentCursor = $anchorCoords;
        if ($currentCursor === null && ! isset($fixedBySlot[0]) && $this->hasCoordinates($dayItems[0])) {
            $fixedBySlot[0] = $dayItems[0];
            $flexibleWithCoords = array_values(array_filter(
                $flexibleWithCoords,
                static fn (ItineraryItem $it): bool => $it->id !== $dayItems[0]->id,
            ));
        }

        $result = [];
        $remainingGeocoded = $flexibleWithCoords;
        $remainingUngeocoded = $flexibleWithoutCoords;
        $totalSlots = count($dayItems);

        for ($slot = 0; $slot < $totalSlots; $slot++) {
            if (isset($fixedBySlot[$slot])) {
                $fixedItem = $fixedBySlot[$slot];
                $result[] = $fixedItem;
                if ($this->hasCoordinates($fixedItem)) {
                    $currentCursor = [
                        'lat' => (float) $fixedItem->place->latitude,
                        'lng' => (float) $fixedItem->place->longitude,
                        'name' => $fixedItem->title,
                    ];
                }

                continue;
            }

            if ($remainingGeocoded !== []) {
                if ($currentCursor === null) {
                    $chosen = array_shift($remainingGeocoded);
                } else {
                    $nearestIndex = $this->findNearestIndex($currentCursor['lat'], $currentCursor['lng'], $remainingGeocoded);
                    $chosen = $remainingGeocoded[$nearestIndex];
                    array_splice($remainingGeocoded, $nearestIndex, 1);
                }

                $result[] = $chosen;
                $currentCursor = [
                    'lat' => (float) $chosen->place->latitude,
                    'lng' => (float) $chosen->place->longitude,
                    'name' => $chosen->title,
                ];

                continue;
            }

            if ($remainingUngeocoded !== []) {
                $result[] = array_shift($remainingUngeocoded);
            }
        }

        return $result;
    }

    private function isFixedAnchor(ItineraryItem $item, bool $preserveFixedTimes): bool
    {
        if (in_array($item->kind, ['flight', 'hotel'], true)) {
            return true;
        }

        if ($preserveFixedTimes && $item->starts_at_utc !== null) {
            return true;
        }

        return false;
    }

    private function hasCoordinates(ItineraryItem $item): bool
    {
        return $item->place !== null
            && $item->place->latitude !== null
            && $item->place->longitude !== null;
    }

    /**
     * @param  list<ItineraryItem>  $candidates
     */
    private function findNearestIndex(float $fromLat, float $fromLng, array $candidates): int
    {
        $bestIndex = 0;
        $bestDistance = PHP_FLOAT_MAX;

        foreach ($candidates as $idx => $candidate) {
            $dist = $this->haversineMeters(
                $fromLat,
                $fromLng,
                (float) $candidate->place->latitude,
                (float) $candidate->place->longitude,
            );
            if ($dist < $bestDistance) {
                $bestDistance = $dist;
                $bestIndex = $idx;
            }
        }

        return $bestIndex;
    }

    /**
     * @param  list<ItineraryItem>  $dayItems
     * @param  array{lat: float, lng: float, name: string}|null  $anchorCoords
     */
    private function calculateGroupDistanceMeters(array $dayItems, ?array $anchorCoords): float
    {
        $geocoded = array_values(array_filter(
            $dayItems,
            fn (ItineraryItem $it): bool => $this->hasCoordinates($it),
        ));

        if ($geocoded === []) {
            return 0.0;
        }

        $total = 0.0;

        if ($anchorCoords !== null) {
            $first = $geocoded[0];
            $total += $this->urbanDistanceMeters(
                $anchorCoords['lat'],
                $anchorCoords['lng'],
                (float) $first->place->latitude,
                (float) $first->place->longitude,
            );
        }

        for ($i = 0; $i < count($geocoded) - 1; $i++) {
            $from = $geocoded[$i];
            $to = $geocoded[$i + 1];
            $total += $this->urbanDistanceMeters(
                (float) $from->place->latitude,
                (float) $from->place->longitude,
                (float) $to->place->latitude,
                (float) $to->place->longitude,
            );
        }

        return $total;
    }

    /**
     * Build stop-to-stop transit mode comparison segments between consecutive items within the same day.
     *
     * @param  list<ItineraryItem>  $items
     * @return list<array<string, mixed>>
     */
    private function buildTransitSegments(array $items, int $maxWalkingMeters, string $tripDestination): array
    {
        $segments = [];

        for ($i = 0; $i < count($items) - 1; $i++) {
            $from = $items[$i];
            $to = $items[$i + 1];

            // Only connect stops within the same day group
            if (($from->trip_day_id ?? null) !== ($to->trip_day_id ?? null)) {
                continue;
            }

            $fromPlaceName = $from->place?->name ?? $from->title;
            $toPlaceName = $to->place?->name ?? $to->title;

            if ($this->hasCoordinates($from) && $this->hasCoordinates($to)) {
                $distanceMeters = (int) round($this->urbanDistanceMeters(
                    (float) $from->place->latitude,
                    (float) $from->place->longitude,
                    (float) $to->place->latitude,
                    (float) $to->place->longitude,
                ));
                $distanceKm = round($distanceMeters / 1000.0, 2);
                $exceedsWalk = $distanceMeters > $maxWalkingMeters;

                if (! $exceedsWalk) {
                    $recommendedMode = 'walk';
                } elseif ($distanceMeters <= 8000) {
                    $recommendedMode = 'public_transit';
                } else {
                    $recommendedMode = 'taxi_rideshare';
                }

                // Walk @ 75 m/min (4.5 km/h), Public transit @ 300 m/min (18 km/h) + 6 min wait/access, Taxi @ 400 m/min (24 km/h) + 4 min pickup
                $walkMinutes = max(2, (int) round($distanceMeters / 75.0));
                $transitMinutes = max(8, (int) round(($distanceMeters / 300.0) + 6));
                $rideMinutes = max(5, (int) round(($distanceMeters / 400.0) + 4));

                $originParam = $from->place->latitude.','.$from->place->longitude;
                $destParam = $to->place->latitude.','.$to->place->longitude;

                $modeComparisons = [
                    [
                        'mode' => 'walk',
                        'label' => 'Walk',
                        'estimated_duration_minutes' => $walkMinutes,
                        'suitability' => ! $exceedsWalk ? 'recommended' : 'long_walk',
                        'advisory_note' => ! $exceedsWalk
                            ? 'Within your comfortable walking threshold.'
                            : "Exceeds {$maxWalkingMeters} m walking threshold; consider transit or ride.",
                        'google_maps_directions_url' => $this->buildDirectionsUrl($originParam, $destParam, 'walking'),
                    ],
                    [
                        'mode' => 'public_transit',
                        'label' => 'Public Transit (Metro / Bus)',
                        'estimated_duration_minutes' => $transitMinutes,
                        'suitability' => $recommendedMode === 'public_transit' ? 'recommended' : 'alternative',
                        'advisory_note' => 'Includes ~6 min station walk and transfer buffer. Check local transit horarios in Maps.',
                        'google_maps_directions_url' => $this->buildDirectionsUrl($originParam, $destParam, 'transit'),
                    ],
                    [
                        'mode' => 'taxi_rideshare',
                        'label' => 'Taxi / Rideshare',
                        'estimated_duration_minutes' => $rideMinutes,
                        'suitability' => $recommendedMode === 'taxi_rideshare' ? 'recommended' : 'alternative',
                        'advisory_note' => 'Direct point-to-point ride; duration varies with traffic.',
                        'google_maps_directions_url' => $this->buildDirectionsUrl($originParam, $destParam, 'driving'),
                    ],
                ];

                $recommendedDuration = match ($recommendedMode) {
                    'walk' => $walkMinutes,
                    'public_transit' => $transitMinutes,
                    default => $rideMinutes,
                };
            } else {
                $distanceMeters = null;
                $distanceKm = null;
                $exceedsWalk = false;
                $recommendedMode = 'unknown_coordinates';
                $recommendedDuration = null;

                $originQuery = trim($fromPlaceName.', '.$tripDestination);
                $destQuery = trim($toPlaceName.', '.$tripDestination);

                $modeComparisons = [
                    [
                        'mode' => 'walk',
                        'label' => 'Walk',
                        'estimated_duration_minutes' => null,
                        'suitability' => 'unknown',
                        'advisory_note' => 'Saved stop coordinates are unavailable; open Google Maps for live walking route.',
                        'google_maps_directions_url' => $this->buildDirectionsUrl($originQuery, $destQuery, 'walking'),
                    ],
                    [
                        'mode' => 'public_transit',
                        'label' => 'Public Transit (Metro / Bus)',
                        'estimated_duration_minutes' => null,
                        'suitability' => 'unknown',
                        'advisory_note' => 'Saved stop coordinates are unavailable; open Google Maps for live transit route.',
                        'google_maps_directions_url' => $this->buildDirectionsUrl($originQuery, $destQuery, 'transit'),
                    ],
                    [
                        'mode' => 'taxi_rideshare',
                        'label' => 'Taxi / Rideshare',
                        'estimated_duration_minutes' => null,
                        'suitability' => 'unknown',
                        'advisory_note' => 'Saved stop coordinates are unavailable; open Google Maps for live driving route.',
                        'google_maps_directions_url' => $this->buildDirectionsUrl($originQuery, $destQuery, 'driving'),
                    ],
                ];
            }

            $segments[] = [
                'from_item_id' => $from->id,
                'from_title' => $from->title,
                'from_place_name' => $fromPlaceName,
                'to_item_id' => $to->id,
                'to_title' => $to->title,
                'to_place_name' => $toPlaceName,
                'trip_day_id' => $from->trip_day_id,
                'distance_meters' => $distanceMeters,
                'distance_km' => $distanceKm,
                'recommended_mode' => $recommendedMode,
                'estimated_duration_minutes' => $recommendedDuration,
                'exceeds_walking_limit' => $exceedsWalk,
                'mode_comparisons' => $modeComparisons,
                'provider_attribution' => 'Haversine geometric estimate & Google Maps deep link',
                'verified' => false,
                'limitation_notice' => $distanceMeters !== null
                    ? 'Estimated from straight-line coordinates with 1.3x urban route factor; live transit schedules and fares are not verified.'
                    : 'One or both stops lack saved coordinates; distance and duration cannot be estimated locally.',
            ];
        }

        return $segments;
    }

    private function buildDirectionsUrl(string $origin, string $destination, string $travelMode): string
    {
        return 'https://www.google.com/maps/dir/?'.http_build_query([
            'api' => '1',
            'origin' => $origin,
            'destination' => $destination,
            'travelmode' => $travelMode,
        ], '', '&', PHP_QUERY_RFC3986);
    }

    private function urbanDistanceMeters(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        return $this->haversineMeters($lat1, $lng1, $lat2, $lng2) * self::URBAN_DETOUR_FACTOR;
    }

    private function haversineMeters(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) * sin($dLat / 2)
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
            * sin($dLng / 2) * sin($dLng / 2);

        $c = 2 * atan2(sqrt($a), sqrt(max(0.0, 1.0 - $a)));

        return self::EARTH_RADIUS_METERS * $c;
    }

    /**
     * @param  Collection<int, ItineraryItem>  $collection
     * @param  list<string>  $orderedIds
     * @return list<ItineraryItem>
     */
    private function sortItemsByProposedOrder(Collection $collection, array $orderedIds): array
    {
        $byId = $collection->keyBy('id');
        $sorted = [];
        foreach ($orderedIds as $id) {
            $item = $byId->get($id);
            if ($item !== null) {
                $sorted[] = $item;
            }
        }

        return $sorted;
    }
}
