<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Itinerary\CreateItineraryItemData;
use App\DTOs\Itinerary\UpdateItineraryItemData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Itinerary\ReorderItineraryItemsRequest;
use App\Http\Requests\Api\V1\Itinerary\StoreItineraryItemRequest;
use App\Http\Requests\Api\V1\Itinerary\UpdateItineraryItemRequest;
use App\Http\Resources\Api\V1\ItineraryItemResource;
use App\Models\ItineraryItem;
use App\Models\Trip;
use App\Services\Itinerary\ItineraryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

final class ItineraryItemController extends Controller
{
    public function __construct(
        private readonly ItineraryService $itineraryService,
    ) {}

    /**
     * List all itinerary items for a trip.
     */
    public function index(Request $request, Trip $trip): AnonymousResourceCollection
    {
        Gate::authorize('view', $trip);

        $tripDayId = $request->query('trip_day_id');
        $items = $this->itineraryService->getTripItems($trip, is_string($tripDayId) ? $tripDayId : null);

        return ItineraryItemResource::collection($items);
    }

    /**
     * Store a newly created itinerary item.
     */
    public function store(StoreItineraryItemRequest $request, Trip $trip): JsonResponse
    {
        Gate::authorize('update', $trip);

        $item = $this->itineraryService->createItem(
            $trip,
            CreateItineraryItemData::from($request->validated(), $trip->primary_timezone),
        );

        return (new ItineraryItemResource($item))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Display the specified itinerary item.
     */
    public function show(Request $request, ItineraryItem $item): JsonResponse
    {
        Gate::authorize('view', $item->trip);

        return (new ItineraryItemResource($item->load(['place', 'day'])))
            ->response();
    }

    /**
     * Update the specified itinerary item.
     */
    public function update(UpdateItineraryItemRequest $request, ItineraryItem $item): JsonResponse
    {
        Gate::authorize('update', $item->trip);

        $updated = $this->itineraryService->updateItem(
            $item,
            UpdateItineraryItemData::from($request->validated()),
        );

        return (new ItineraryItemResource($updated))
            ->response();
    }

    /**
     * Remove the specified itinerary item.
     */
    public function destroy(Request $request, ItineraryItem $item): Response
    {
        Gate::authorize('update', $item->trip);

        $this->itineraryService->deleteItem($item);

        return response()->noContent();
    }

    /**
     * Reorder itinerary items for a trip.
     */
    public function reorder(ReorderItineraryItemsRequest $request, Trip $trip): AnonymousResourceCollection
    {
        Gate::authorize('update', $trip);

        /** @var array<int, string> $itemIds */
        $itemIds = $request->validated('item_ids');

        $reordered = $this->itineraryService->reorderItems($trip, $itemIds);

        return ItineraryItemResource::collection($reordered);
    }
}
