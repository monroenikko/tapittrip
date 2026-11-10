<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\DTOs\Notifications\RegisterDeviceData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Notifications\RegisterDeviceRequest;
use App\Http\Resources\Api\V1\UserDeviceResource;
use App\Services\Notifications\NotificationService;
use Illuminate\Http\JsonResponse;

final class DeviceController extends Controller
{
    public function __construct(
        private readonly NotificationService $notificationService,
    ) {}

    /**
     * Register or update a user device for push notifications.
     */
    public function register(RegisterDeviceRequest $request): JsonResponse
    {
        $device = $this->notificationService->registerDevice(
            $request->user(),
            RegisterDeviceData::from($request->validated()),
        );

        return (new UserDeviceResource($device))
            ->response()
            ->setStatusCode(200);
    }
}
