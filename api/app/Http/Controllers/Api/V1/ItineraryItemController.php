<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Itinerary\Data\CreateItineraryItemData;
use App\Application\Itinerary\Data\UpdateItineraryItemData;
use App\Application\Itinerary\Services\CreateItineraryItemService;
use App\Application\Itinerary\Services\DeleteItineraryItemService;
use App\Application\Itinerary\Services\ReorderItineraryItemsService;
use App\Application\Itinerary\Services\UpdateItineraryItemService;
use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Itinerary\ReorderItineraryItemsRequest;
use App\Http\Requests\Api\V1\Itinerary\StoreItineraryItemRequest;
use App\Http\Requests\Api\V1\Itinerary\UpdateItineraryItemRequest;
use App\Http\Resources\Api\V1\ItineraryItemResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

final class ItineraryItemController extends Controller
{
    /**
     * List all itinerary items for a trip.
     */
    public function index(Request $request, Trip $trip): AnonymousResourceCollection
    {
        Gate::authorize('view', $trip);

        $query = $trip->itineraryItems()->with(['place', 'day']);

        if ($request->has('trip_day_id')) {
            $query->where('trip_day_id', $request->query('trip_day_id'));
        }

        return ItineraryItemResource::collection($query->get());
    }

    /**
     * Store a newly created itinerary item.
     */
    public function store(
        StoreItineraryItemRequest $request,
        Trip $trip,
        CreateItineraryItemService $service,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $item = $service->handle(
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
    public function update(
        UpdateItineraryItemRequest $request,
        ItineraryItem $item,
        UpdateItineraryItemService $service,
    ): JsonResponse {
        Gate::authorize('update', $item->trip);

        $updated = $service->handle(
            $item,
            UpdateItineraryItemData::from($request->validated()),
        );

        return (new ItineraryItemResource($updated))
            ->response();
    }

    /**
     * Remove the specified itinerary item.
     */
    public function destroy(
        Request $request,
        ItineraryItem $item,
        DeleteItineraryItemService $service,
    ): Response {
        Gate::authorize('update', $item->trip);

        $service->handle($item);

        return response()->noContent();
    }

    /**
     * Reorder itinerary items for a trip.
     */
    public function reorder(
        ReorderItineraryItemsRequest $request,
        Trip $trip,
        ReorderItineraryItemsService $service,
    ): AnonymousResourceCollection {
        Gate::authorize('update', $trip);

        /** @var array<int, string> $itemIds */
        $itemIds = $request->validated('item_ids');

        $reordered = $service->handle($trip, $itemIds);

        return ItineraryItemResource::collection($reordered);
    }
}
