<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Trip\CreateTripData;
use App\DTOs\Trip\UpdateTripData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Trips\StoreTripRequest;
use App\Http\Requests\Api\V1\Trips\UpdateTripRequest;
use App\Http\Resources\Api\V1\TripResource;
use App\Models\Trip;
use App\Services\Trip\TripService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

final class TripController extends Controller
{
    public function __construct(
        private readonly TripService $tripService,
    ) {}

    /**
     * Display a listing of trips the user is a member of.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $trips = $request->user()
            ->trips()
            ->with(['members'])
            ->orderByDesc('created_at')
            ->get();

        return TripResource::collection($trips);
    }

    /**
     * Store a newly created trip.
     */
    public function store(StoreTripRequest $request): JsonResponse
    {
        $trip = $this->tripService->create(
            $request->user(),
            CreateTripData::from($request->validated()),
        );

        return (new TripResource($trip))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Display the specified trip.
     */
    public function show(Request $request, Trip $trip): JsonResponse
    {
        Gate::authorize('view', $trip);

        return (new TripResource($trip))
            ->response();
    }

    /**
     * Update the specified trip.
     */
    public function update(UpdateTripRequest $request, Trip $trip): JsonResponse
    {
        Gate::authorize('update', $trip);

        $updated = $this->tripService->update(
            $trip,
            UpdateTripData::from($request->validated()),
            $request->validated(),
        );

        return (new TripResource($updated))
            ->response();
    }

    /**
     * Remove the specified trip.
     */
    public function destroy(Request $request, Trip $trip): Response
    {
        Gate::authorize('delete', $trip);

        $this->tripService->delete($trip);

        return response()->noContent();
    }
}
