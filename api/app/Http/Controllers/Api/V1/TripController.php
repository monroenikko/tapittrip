<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Domain\Trips\Actions\CreateTrip;
use App\Domain\Trips\Actions\DeleteTrip;
use App\Domain\Trips\Actions\UpdateTrip;
use App\Domain\Trips\Data\CreateTripData;
use App\Domain\Trips\Data\UpdateTripData;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Trips\StoreTripRequest;
use App\Http\Requests\Api\V1\Trips\UpdateTripRequest;
use App\Http\Resources\Api\V1\TripResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

final class TripController extends Controller
{
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
    public function store(StoreTripRequest $request, CreateTrip $createTrip): JsonResponse
    {
        $trip = $createTrip->handle(
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
    public function update(UpdateTripRequest $request, Trip $trip, UpdateTrip $updateTrip): JsonResponse
    {
        Gate::authorize('update', $trip);

        $updated = $updateTrip->handle(
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
    public function destroy(Request $request, Trip $trip, DeleteTrip $deleteTrip): Response
    {
        Gate::authorize('delete', $trip);

        $deleteTrip->handle($trip);

        return response()->noContent();
    }
}
