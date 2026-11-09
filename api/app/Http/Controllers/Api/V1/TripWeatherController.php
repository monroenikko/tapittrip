<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Weather\Services\GetTripWeatherService;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\TripWeatherResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

final class TripWeatherController extends Controller
{
    /**
     * Get live and forecasted weather for the trip's destination.
     */
    public function show(Trip $trip, GetTripWeatherService $service): JsonResponse
    {
        Gate::authorize('view', $trip);

        $weather = $service->getWeather($trip);

        return (new TripWeatherResource($weather))
            ->response()
            ->setStatusCode(200);
    }
}
