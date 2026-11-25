<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\DestinationSafetyResource;
use App\Models\Trip;
use App\Services\Safety\DestinationSafetyService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

final class DestinationSafetyController extends Controller
{
    public function __construct(
        private readonly DestinationSafetyService $safetyService,
        private readonly ApiResponse $response,
    ) {}

    /**
     * List curated destination safety profiles.
     */
    public function index(Request $request): JsonResponse
    {
        $q = $request->query('q');
        $profiles = $this->safetyService->listCuratedProfiles(is_string($q) ? $q : null);

        return $this->response->success(DestinationSafetyResource::collection($profiles));
    }

    /**
     * Get safety profile for a specific country code or name.
     */
    public function showCountry(string $country): JsonResponse
    {
        $profile = $this->safetyService->getByCountry($country);

        return $this->response->success(new DestinationSafetyResource($profile));
    }

    /**
     * Get safety profile for a trip's destination country (with optional ?country= override).
     */
    public function showTrip(Request $request, Trip $trip): JsonResponse
    {
        Gate::authorize('view', $trip);

        $countryOverride = $request->query('country');
        $profile = $this->safetyService->getForTrip(
            $trip,
            is_string($countryOverride) ? $countryOverride : null
        );

        return $this->response->success(new DestinationSafetyResource($profile));
    }
}
