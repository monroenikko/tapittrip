<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Itinerary\Data\CreatePlaceData;
use App\Application\Itinerary\Services\CreatePlaceService;
use App\Application\Itinerary\Services\PlaceSearchService;
use App\Domain\Itinerary\Models\Place;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Itinerary\StorePlaceRequest;
use App\Http\Resources\Api\V1\PlaceResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

final class PlaceController extends Controller
{
    /**
     * Search places by query string with 3rd-party provider fallback.
     */
    public function search(Request $request, PlaceSearchService $searchService): AnonymousResourceCollection
    {
        $query = (string) $request->query('q', '');

        $places = $searchService->search($query);

        return PlaceResource::collection($places);
    }

    /**
     * Store a new place or return existing.
     */
    public function store(StorePlaceRequest $request, CreatePlaceService $service): JsonResponse
    {
        $place = $service->handle(CreatePlaceData::from($request->validated()));

        return (new PlaceResource($place))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Display the specified place.
     */
    public function show(Place $place): JsonResponse
    {
        return (new PlaceResource($place))
            ->response();
    }
}
