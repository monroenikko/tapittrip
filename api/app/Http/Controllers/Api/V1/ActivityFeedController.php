<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ActivityEventResource;
use App\Models\Trip;
use App\Services\Activity\ActivityService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class ActivityFeedController extends Controller
{
    public function __construct(
        private readonly ActivityService $activityService,
        private readonly ApiResponse $response,
    ) {}

    public function index(Trip $trip, Request $request): JsonResponse
    {
        $limit = $request->query('limit');
        $before = $request->query('before');

        $events = $this->activityService->getTripFeed(
            trip: $trip,
            user: $request->user(),
            limit: is_numeric($limit) ? (int) $limit : 30,
            beforeId: is_string($before) ? $before : null,
        );

        return $this->response->success(ActivityEventResource::collection($events));
    }
}
