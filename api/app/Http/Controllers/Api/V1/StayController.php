<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Stays\CreateStayData;
use App\DTOs\Stays\UpdateStayData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Stays\StoreStayRequest;
use App\Http\Requests\Api\V1\Stays\UpdateStayRequest;
use App\Http\Resources\Api\V1\StayResource;
use App\Models\Stay;
use App\Models\Trip;
use App\Services\Stays\StayService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

final class StayController extends Controller
{
    public function __construct(
        private readonly StayService $stayService,
    ) {}

    /**
     * List all stays for a trip.
     */
    public function index(Request $request, Trip $trip): AnonymousResourceCollection
    {
        Gate::authorize('view', $trip);

        $stays = $this->stayService->getTripStays($trip);

        return StayResource::collection($stays);
    }

    /**
     * Store a newly created stay for a trip.
     */
    public function store(StoreStayRequest $request, Trip $trip): JsonResponse
    {
        Gate::authorize('update', $trip);

        $stay = $this->stayService->create(
            $trip,
            CreateStayData::from($request->validated(), $trip->primary_timezone),
        );

        return (new StayResource($stay))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Display the specified stay.
     */
    public function show(Request $request, Stay $stay): JsonResponse
    {
        Gate::authorize('view', $stay->trip);

        return (new StayResource($stay->load(['place', 'itineraryItems'])))
            ->response();
    }

    /**
     * Update the specified stay.
     */
    public function update(UpdateStayRequest $request, Stay $stay): JsonResponse
    {
        Gate::authorize('update', $stay->trip);

        $updated = $this->stayService->update(
            $stay,
            UpdateStayData::from($request->validated()),
        );

        return (new StayResource($updated))
            ->response();
    }

    /**
     * Remove the specified stay without deleting linked itinerary items.
     */
    public function destroy(Request $request, Stay $stay): Response
    {
        Gate::authorize('update', $stay->trip);

        $this->stayService->delete($stay);

        return response()->noContent();
    }
}
