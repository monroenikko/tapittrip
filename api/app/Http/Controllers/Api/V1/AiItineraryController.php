<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Itinerary\ApplyAiItineraryData;
use App\DTOs\Itinerary\AskTripAssistantData;
use App\DTOs\Itinerary\GenerateAiItineraryData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Itinerary\ApplyAiItineraryRequest;
use App\Http\Requests\Api\V1\Itinerary\AskTripAssistantRequest;
use App\Http\Requests\Api\V1\Itinerary\GenerateAiItineraryRequest;
use App\Http\Resources\Api\V1\ItineraryItemResource;
use App\Models\Trip;
use App\Services\Itinerary\ApplyAiItineraryService;
use App\Services\Itinerary\AskTapItTripService;
use App\Services\Itinerary\GenerateAiItineraryService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;

final class AiItineraryController extends Controller
{
    public function __construct(
        private readonly GenerateAiItineraryService $generateService,
        private readonly ApplyAiItineraryService $applyService,
        private readonly AskTapItTripService $assistantService,
        private readonly ApiResponse $response,
    ) {}

    /**
     * Generate an AI-assisted itinerary suggestion staging plan.
     */
    public function generate(
        Trip $trip,
        GenerateAiItineraryRequest $request,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $data = GenerateAiItineraryData::fromArray($request->validated());
        $plan = $this->generateService->execute($trip, $data);

        return $this->response->success($plan->toArray());
    }

    /**
     * Apply approved itinerary suggestion days to the trip's itinerary.
     */
    public function apply(
        Trip $trip,
        ApplyAiItineraryRequest $request,
    ): AnonymousResourceCollection {
        Gate::authorize('update', $trip);

        $data = ApplyAiItineraryData::fromArray($trip->id, $request->validated());
        $items = $this->applyService->execute($trip, $data);

        return ItineraryItemResource::collection($items);
    }

    /**
     * Ask TapItTrip contextual in-trip assistant.
     */
    public function ask(
        Trip $trip,
        AskTripAssistantRequest $request,
    ): JsonResponse {
        Gate::authorize('view', $trip);

        $data = AskTripAssistantData::from($request->validated());
        $result = $this->assistantService->ask($trip, $data);

        return $this->response->success($result->toArray());
    }
}
