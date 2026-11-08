<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Notifications\Data\UpdateNotificationPreferencesData;
use App\Application\Notifications\Services\GetNotificationPreferencesService;
use App\Application\Notifications\Services\UpdateNotificationPreferencesService;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Notifications\UpdateNotificationPreferencesRequest;
use App\Http\Resources\Api\V1\NotificationPreferenceResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class NotificationPreferenceController extends Controller
{
    /**
     * Show notification preferences for the authenticated user.
     */
    public function show(
        Request $request,
        GetNotificationPreferencesService $service,
    ): JsonResponse {
        $preferences = $service->execute($request->user());

        return (new NotificationPreferenceResource($preferences))
            ->response()
            ->setStatusCode(200);
    }

    /**
     * Update notification preferences for the authenticated user.
     */
    public function update(
        UpdateNotificationPreferencesRequest $request,
        UpdateNotificationPreferencesService $service,
    ): JsonResponse {
        $preferences = $service->execute(
            $request->user(),
            UpdateNotificationPreferencesData::from($request->validated()),
        );

        return (new NotificationPreferenceResource($preferences))
            ->response()
            ->setStatusCode(200);
    }
}

