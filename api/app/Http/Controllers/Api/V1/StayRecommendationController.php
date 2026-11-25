<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\StayRecommendationResource;
use App\Models\Trip;
use App\Services\Stays\GenerateStayRecommendationsService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

final class StayRecommendationController extends Controller
{
    public function __invoke(Trip $trip, GenerateStayRecommendationsService $service, ApiResponse $response): JsonResponse
    {
        Gate::authorize('view', $trip);

        return $response->success((new StayRecommendationResource($service->execute($trip)))->resolve(), headers: ['Cache-Control' => 'no-store']);
    }
}
