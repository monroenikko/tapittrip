<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Itinerary\StoreTripDayRequest;
use App\Http\Resources\Api\V1\TripDayResource;
use App\Models\Trip;
use App\Services\Itinerary\ItineraryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;

final class TripDayController extends Controller
{
    public function __construct(
        private readonly ItineraryService $itineraryService,
    ) {}

    /**
     * List all days for a trip.
     */
    public function index(Request $request, Trip $trip): AnonymousResourceCollection
    {
        Gate::authorize('view', $trip);

        $days = $trip->days()->get();

        return TripDayResource::collection($days);
    }

    /**
     * Create or retrieve a trip day by local date.
     */
    public function store(StoreTripDayRequest $request, Trip $trip): JsonResponse
    {
        Gate::authorize('update', $trip);

        $day = $this->itineraryService->ensureTripDay(
            $trip,
            (string) $request->validated('local_date'),
            $request->validated('notes') ? (string) $request->validated('notes') : null,
        );

        return (new TripDayResource($day))
            ->response()
            ->setStatusCode(201);
    }
}
