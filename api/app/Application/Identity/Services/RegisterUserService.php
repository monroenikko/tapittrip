<?php

declare(strict_types=1);

namespace App\Application\Identity\Services;

use App\Application\Identity\Data\AccessTokenResult;
use App\Application\Identity\Data\RegisterUserData;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

final class RegisterUserService
{
    public function handle(RegisterUserData $data): AccessTokenResult
    {
        return DB::transaction(function () use ($data): AccessTokenResult {
            /** @var User $user */
            $user = User::query()->create([
                'name' => $data->name,
                'display_name' => $data->displayName ?? $data->name,
                'email' => $data->email,
                'password' => Hash::make($data->password),
                'locale' => $data->locale ?? 'en',
                'home_timezone' => $data->homeTimezone ?? 'UTC',
            ]);

            $plainTextToken = $user->createToken($data->deviceName ?? 'mobile')->plainTextToken;

            return new AccessTokenResult(
                user: $user,
                plainTextToken: $plainTextToken,
            );
        });
    }
}
