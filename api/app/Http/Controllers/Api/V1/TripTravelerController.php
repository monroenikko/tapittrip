<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Circles\CreateTripTravelerData;
use App\DTOs\Circles\UpdateTripTravelerData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Circles\StoreTripTravelerRequest;
use App\Http\Requests\Api\V1\Circles\UpdateTripTravelerRequest;
use App\Http\Resources\Api\V1\TripTravelerResource;
use App\Models\Trip;
use App\Models\TripTraveler;
use App\Services\Circles\TripTravelerService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class TripTravelerController extends Controller
{
    public function __construct(
        private readonly TripTravelerService $travelerService,
        private readonly ApiResponse $response,
    ) {}

    public function index(Trip $trip, Request $request): JsonResponse
    {
        $travelers = $this->travelerService->listForTrip($trip, $request->user());

        return $this->response->success(TripTravelerResource::collection($travelers));
    }

    public function store(Trip $trip, StoreTripTravelerRequest $request): JsonResponse
    {
        $traveler = $this->travelerService->create(
            $trip,
            $request->user(),
            new CreateTripTravelerData(
                displayName: (string) $request->validated('display_name'),
                travelerCategory: (string) $request->validated('traveler_category', 'child'),
                restrictedNotes: $request->validated('restricted_notes'),
                linkedMemberId: $request->validated('linked_member_id'),
            ),
        );

        return $this->response->success(new TripTravelerResource($traveler), 201);
    }

    public function update(TripTraveler $traveler, UpdateTripTravelerRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $updated = $this->travelerService->update(
            $traveler,
            $request->user(),
            new UpdateTripTravelerData(
                displayName: $validated['display_name'] ?? null,
                travelerCategory: $validated['traveler_category'] ?? null,
                restrictedNotes: $validated['restricted_notes'] ?? null,
                clearRestrictedNotes: array_key_exists('restricted_notes', $validated)
                    && $validated['restricted_notes'] === null,
                baseVersion: isset($validated['base_version'])
                    ? (int) $validated['base_version']
                    : null,
            ),
        );

        return $this->response->success(new TripTravelerResource($updated));
    }

    public function destroy(TripTraveler $traveler, Request $request): Response
    {
        $this->travelerService->delete($traveler, $request->user());

        return $this->response->noContent();
    }
}
