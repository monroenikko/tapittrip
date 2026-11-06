<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Trips\Services\GetTodaySummaryService;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\TodaySummaryResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

final class TripTodayController extends Controller
{
    /**
     * Get the live "Today" dashboard summary for a trip.
     */
    public function show(Trip $trip, GetTodaySummaryService $service): JsonResponse
    {
        Gate::authorize('view', $trip);

        $result = $service->handle($trip);

        return (new TodaySummaryResource($result))
            ->response()
            ->setStatusCode(200);
    }
}
