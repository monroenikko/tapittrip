<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Stays\Data\CreateStayData;
use App\Application\Stays\Data\UpdateStayData;
use App\Application\Stays\Services\CreateStayService;
use App\Application\Stays\Services\DeleteStayService;
use App\Application\Stays\Services\UpdateStayService;
use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Stays\StoreStayRequest;
use App\Http\Requests\Api\V1\Stays\UpdateStayRequest;
use App\Http\Resources\Api\V1\StayResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

final class StayController extends Controller
{
    /**
     * List all stays for a trip.
     */
    public function index(Request $request, Trip $trip): AnonymousResourceCollection
    {
        Gate::authorize('view', $trip);

        $stays = $trip->stays()->with(['place', 'itineraryItems'])->get();

        return StayResource::collection($stays);
    }

    /**
     * Store a newly created stay for a trip.
     */
    public function store(
        StoreStayRequest $request,
        Trip $trip,
        CreateStayService $service,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $stay = $service->handle(
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
    public function update(
        UpdateStayRequest $request,
        Stay $stay,
        UpdateStayService $service,
    ): JsonResponse {
        Gate::authorize('update', $stay->trip);

        $updated = $service->handle(
            $stay,
            UpdateStayData::from($request->validated()),
        );

        return (new StayResource($updated))
            ->response();
    }

    /**
     * Remove the specified stay without deleting linked itinerary items.
     */
    public function destroy(
        Request $request,
        Stay $stay,
        DeleteStayService $service,
    ): Response {
        Gate::authorize('update', $stay->trip);

        $service->handle($stay);

        return response()->noContent();
    }
}
