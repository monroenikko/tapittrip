<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Itinerary\ListFoodSuggestionsRequest;
use App\Models\Trip;
use App\Services\Itinerary\FoodSuggestionService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

final class FoodSuggestionController extends Controller
{
    public function __construct(
        private readonly FoodSuggestionService $foodSuggestionService,
        private readonly ApiResponse $response,
    ) {}

    /**
     * List curated restaurant and food discovery suggestions for a trip.
     */
    public function index(ListFoodSuggestionsRequest $request, Trip $trip): JsonResponse
    {
        Gate::authorize('view', $trip);

        $result = $this->foodSuggestionService->suggestForTrip($trip, $request->validated());

        return $this->response->success($result);
    }
}
