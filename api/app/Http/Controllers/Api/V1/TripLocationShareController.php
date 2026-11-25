<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Circles\StoreTripLocationShareRequest;
use App\Http\Requests\Api\V1\Circles\UpdateTripLocationShareRequest;
use App\Http\Resources\Api\V1\TripLocationShareResource;
use App\Models\Trip;
use App\Services\Circles\TripLocationShareService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class TripLocationShareController extends Controller
{
    public function __construct(
        private readonly TripLocationShareService $service,
        private readonly ApiResponse $response,
    ) {}

    /**
     * Show current user's location sharing status for a trip.
     */
    public function show(Trip $trip, Request $request): JsonResponse
    {
        $share = $this->service->getForUser($trip, $request->user());

        if ($share === null) {
            return $this->response->success([
                'enabled' => false,
                'is_active' => false,
                'is_stale' => true,
                'duration_minutes' => 60,
                'expires_at' => null,
                'audience' => 'circle',
                'latitude' => null,
                'longitude' => null,
                'last_shared_at' => null,
            ]);
        }

        return $this->response->success(new TripLocationShareResource($share));
    }

    /**
     * List active circle members sharing location on this trip.
     */
    public function index(Trip $trip, Request $request): JsonResponse
    {
        $shares = $this->service->listActiveForTrip($trip, $request->user());

        return $this->response->success(TripLocationShareResource::collection($shares));
    }

    /**
     * Enable or initialize location sharing.
     */
    public function store(Trip $trip, StoreTripLocationShareRequest $request): JsonResponse
    {
        $duration = (int) $request->validated('duration_minutes');
        $audience = (string) $request->validated('audience');
        $lat = (float) $request->validated('latitude');
        $lng = (float) $request->validated('longitude');

        $share = $this->service->enable($trip, $request->user(), $duration, $audience, $lat, $lng);

        return $this->response->success(new TripLocationShareResource($share), 201);
    }

    /**
     * Update location share state or update coordinates.
     */
    public function update(Trip $trip, UpdateTripLocationShareRequest $request): JsonResponse
    {
        $user = $request->user();

        if ($request->has('enabled') && ! $request->boolean('enabled')) {
            $share = $this->service->disable($trip, $user);

            return $this->response->success(new TripLocationShareResource($share));
        }

        if ($request->has('latitude') && $request->has('longitude') && ! $request->has('duration_minutes') && ! $request->has('audience') && ! $request->has('enabled')) {
            $share = $this->service->updateCoordinates(
                $trip,
                $user,
                (float) $request->validated('latitude'),
                (float) $request->validated('longitude'),
            );

            return $this->response->success(new TripLocationShareResource($share));
        }

        $existing = $this->service->getForUser($trip, $user);
        $duration = (int) $request->validated('duration_minutes', $existing?->duration_minutes ?? 60);
        $audience = (string) $request->validated('audience', $existing?->audience ?? 'circle');
        $lat = $request->filled('latitude') ? (float) $request->validated('latitude') : null;
        $lng = $request->filled('longitude') ? (float) $request->validated('longitude') : null;

        if ($lat === null || $lng === null) {
            $lat = $existing?->latitude;
            $lng = $existing?->longitude;
        }

        $share = $this->service->enable($trip, $user, $duration, $audience, $lat, $lng);

        return $this->response->success(new TripLocationShareResource($share));
    }
}
