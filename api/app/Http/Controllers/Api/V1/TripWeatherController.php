<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Weather\Services\GetTripWeatherService;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\TripWeatherResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

final class TripWeatherController extends Controller
{
    /**
     * Get live and forecasted weather for the trip's destination or specific location coordinates.
     */
    public function show(Request $request, Trip $trip, GetTripWeatherService $service): JsonResponse
    {
        Gate::authorize('view', $trip);

        $latitude = $request->query('latitude') !== null ? (float) $request->query('latitude') : null;
        $longitude = $request->query('longitude') !== null ? (float) $request->query('longitude') : null;
        $location = $request->query('location') ? (string) $request->query('location') : null;

        $weather = $service->getWeather($trip, $latitude, $longitude, $location);

        return (new TripWeatherResource($weather))
            ->response()
            ->setStatusCode(200);
    }
}
