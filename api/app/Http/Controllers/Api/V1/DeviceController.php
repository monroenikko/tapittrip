<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Notifications\Data\RegisterDeviceData;
use App\Application\Notifications\Services\RegisterDeviceService;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Notifications\RegisterDeviceRequest;
use App\Http\Resources\Api\V1\UserDeviceResource;
use Illuminate\Http\JsonResponse;

final class DeviceController extends Controller
{
    /**
     * Register or update a user device for push notifications.
     */
    public function register(
        RegisterDeviceRequest $request,
        RegisterDeviceService $service,
    ): JsonResponse {
        $device = $service->execute(
            $request->user(),
            RegisterDeviceData::from($request->validated()),
        );

        return (new UserDeviceResource($device))
            ->response()
            ->setStatusCode(200);
    }
}
