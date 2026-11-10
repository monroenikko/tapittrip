<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\TodaySummaryResource;
use App\Models\Trip;
use App\Services\Trip\TripService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

final class TripTodayController extends Controller
{
    public function __construct(
        private readonly TripService $tripService,
    ) {}

    /**
     * Get the live "Today" dashboard summary for a trip.
     */
    public function show(Request $request, Trip $trip): JsonResponse
    {
        Gate::authorize('view', $trip);

        $result = $this->tripService->getTodaySummary($trip, null, $request->user());

        return (new TodaySummaryResource($result))
            ->response()
            ->setStatusCode(200);
    }
}
