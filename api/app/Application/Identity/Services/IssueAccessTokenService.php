<?php

declare(strict_types=1);

namespace App\Application\Identity\Services;

use App\Application\Identity\Data\AccessTokenResult;
use App\Application\Identity\Exceptions\InvalidCredentials;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

final class IssueAccessTokenService
{
    public function handle(string $email, string $password, ?string $deviceName): AccessTokenResult
    {
        /** @var User|null $user */
        $user = User::query()->where('email', $email)->first();

        if (! $user || ! $user->password || ! Hash::check($password, $user->password)) {
            throw new InvalidCredentials;
        }

        return new AccessTokenResult(
            user: $user,
            plainTextToken: $user->createToken($deviceName ?? 'mobile')->plainTextToken,
        );
    }
}
