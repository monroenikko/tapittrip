<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\TripNotificationResource;
use App\Models\TripNotification;
use App\Services\Notifications\NotificationService;
use App\Support\Http\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class TripNotificationController extends Controller
{
    public function __construct(
        private readonly NotificationService $notificationService,
        private readonly ApiResponse $response,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $notifications = $this->notificationService->listUserNotifications($request->user());

        return $this->response->success(TripNotificationResource::collection($notifications));
    }

    public function markRead(TripNotification $notification, Request $request): JsonResponse
    {
        $updated = $this->notificationService->markNotificationRead($notification, $request->user());

        return $this->response->success(new TripNotificationResource($updated));
    }
}
