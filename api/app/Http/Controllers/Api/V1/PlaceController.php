<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Itinerary\CreatePlaceData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Itinerary\StorePlaceRequest;
use App\Http\Resources\Api\V1\PlaceResource;
use App\Models\Place;
use App\Services\Itinerary\PlaceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

final class PlaceController extends Controller
{
    public function __construct(
        private readonly PlaceService $placeService,
    ) {}

    /**
     * Search places by query string with 3rd-party provider fallback.
     */
    public function search(Request $request): AnonymousResourceCollection
    {
        $query = (string) $request->query('q', '');

        $places = $this->placeService->search($query);

        return PlaceResource::collection($places);
    }

    /**
     * Store a new place or return existing.
     */
    public function store(StorePlaceRequest $request): JsonResponse
    {
        $place = $this->placeService->createPlace(CreatePlaceData::from($request->validated()));

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
