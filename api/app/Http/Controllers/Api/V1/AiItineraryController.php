<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Itinerary\Data\ApplyAiItineraryData;
use App\Application\Itinerary\Data\GenerateAiItineraryData;
use App\Application\Itinerary\Services\ApplyAiItineraryService;
use App\Application\Itinerary\Services\AskTapItTripService;
use App\Application\Itinerary\Services\GenerateAiItineraryService;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Itinerary\ApplyAiItineraryRequest;
use App\Http\Requests\Api\V1\Itinerary\AskTripAssistantRequest;
use App\Http\Requests\Api\V1\Itinerary\GenerateAiItineraryRequest;
use App\Http\Resources\Api\V1\ItineraryItemResource;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;

final class AiItineraryController extends Controller
{
    /**
     * Generate an AI-assisted itinerary suggestion staging plan.
     */
    public function generate(
        Trip $trip,
        GenerateAiItineraryRequest $request,
        GenerateAiItineraryService $service,
        ApiResponse $response,
    ): JsonResponse {
        Gate::authorize('update', $trip);

        $data = GenerateAiItineraryData::fromArray($request->validated());
        $plan = $service->execute($trip, $data);

        return $response->success($plan->toArray());
    }

    /**
     * Apply approved itinerary suggestion days to the trip's itinerary.
     */
    public function apply(
        Trip $trip,
        ApplyAiItineraryRequest $request,
        ApplyAiItineraryService $service,
    ): AnonymousResourceCollection {
        Gate::authorize('update', $trip);

        $data = ApplyAiItineraryData::fromArray($trip->id, $request->validated());
        $items = $service->execute($trip, $data);

        return ItineraryItemResource::collection($items);
    }

    /**
     * Ask TapItTrip contextual in-trip assistant.
     */
    public function ask(
        Trip $trip,
        AskTripAssistantRequest $request,
        AskTapItTripService $service,
        ApiResponse $response,
    ): JsonResponse {
        Gate::authorize('view', $trip);

        $validated = $request->validated();
        $result = $service->ask(
            trip: $trip,
            query: $validated['query'],
            contextDate: $validated['context_date'] ?? null,
            terminalCode: $validated['terminal_code'] ?? null,
        );

        return $response->success($result->toArray());
    }
}
