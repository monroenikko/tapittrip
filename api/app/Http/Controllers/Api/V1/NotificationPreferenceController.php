<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Notifications\UpdateNotificationPreferencesData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Notifications\UpdateNotificationPreferencesRequest;
use App\Http\Resources\Api\V1\NotificationPreferenceResource;
use App\Services\Notifications\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class NotificationPreferenceController extends Controller
{
    public function __construct(
        private readonly NotificationService $notificationService,
    ) {}

    /**
     * Show notification preferences for the authenticated user.
     */
    public function show(Request $request): JsonResponse
    {
        $preferences = $this->notificationService->getPreferences($request->user());

        return (new NotificationPreferenceResource($preferences))
            ->response()
            ->setStatusCode(200);
    }

    /**
     * Update notification preferences for the authenticated user.
     */
    public function update(UpdateNotificationPreferencesRequest $request): JsonResponse
    {
        $preferences = $this->notificationService->updatePreferences(
            $request->user(),
            UpdateNotificationPreferencesData::from($request->validated()),
        );

        return (new NotificationPreferenceResource($preferences))
            ->response()
            ->setStatusCode(200);
    }
}
