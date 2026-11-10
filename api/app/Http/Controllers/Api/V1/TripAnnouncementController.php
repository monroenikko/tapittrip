<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Circles\CreateAnnouncementData;
use App\DTOs\Circles\UpdateAnnouncementData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Circles\StoreAnnouncementRequest;
use App\Http\Requests\Api\V1\Circles\UpdateAnnouncementRequest;
use App\Http\Resources\Api\V1\TripAnnouncementResource;
use App\Models\Trip;
use App\Models\TripAnnouncement;
use App\Services\Circles\TripAnnouncementService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class TripAnnouncementController extends Controller
{
    public function __construct(
        private readonly TripAnnouncementService $announcementService,
        private readonly ApiResponse $response,
    ) {}

    public function index(Trip $trip, Request $request): JsonResponse
    {
        $announcements = $this->announcementService->listForTrip($trip, $request->user());

        return $this->response->success(TripAnnouncementResource::collection($announcements));
    }

    public function store(Trip $trip, StoreAnnouncementRequest $request): JsonResponse
    {
        $announcement = $this->announcementService->create(
            $trip,
            $request->user(),
            new CreateAnnouncementData(
                title: (string) $request->validated('title'),
                body: (string) $request->validated('body'),
                isPinned: (bool) $request->validated('is_pinned', false),
                clientOperationId: $request->validated('client_operation_id'),
            ),
        );

        return $this->response->success(new TripAnnouncementResource($announcement), 201);
    }

    public function update(TripAnnouncement $announcement, UpdateAnnouncementRequest $request): JsonResponse
    {
        $updated = $this->announcementService->update(
            $announcement,
            $request->user(),
            new UpdateAnnouncementData(
                title: $request->validated('title'),
                body: $request->validated('body'),
                isPinned: $request->has('is_pinned') ? (bool) $request->validated('is_pinned') : null,
                baseVersion: $request->validated('base_version') !== null
                    ? (int) $request->validated('base_version')
                    : null,
            ),
        );

        return $this->response->success(new TripAnnouncementResource($updated));
    }

    public function destroy(TripAnnouncement $announcement, Request $request): Response
    {
        $this->announcementService->delete($announcement, $request->user());

        return $this->response->noContent();
    }
}

