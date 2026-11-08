<?php

declare(strict_types=1);

namespace App\Application\Notifications\Services;

use App\Application\Notifications\Data\RegisterDeviceData;
use App\Domain\Notifications\Models\UserDevice;
use App\Models\User;

final class RegisterDeviceService
{
    /**
     * Register or update a user's mobile or web device.
     */
    public function execute(User $user, RegisterDeviceData $data): UserDevice
    {
        return UserDevice::updateOrCreate(
            [
                'user_id' => $user->id,
                'device_key' => $data->deviceKey,
            ],
            [
                'platform' => $data->platform,
                'push_token' => $data->pushToken,
                'last_seen_at' => now(),
            ]
        );
    }
}

