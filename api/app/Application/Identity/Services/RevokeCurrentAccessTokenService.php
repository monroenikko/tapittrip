<?php

declare(strict_types=1);

namespace App\Application\Identity\Services;

use App\Models\User;
use Laravel\Sanctum\PersonalAccessToken;

final class RevokeCurrentAccessTokenService
{
    public function handle(User $user): void
    {
        $accessToken = $user->currentAccessToken();

        if ($accessToken instanceof PersonalAccessToken) {
            $accessToken->delete();
        }
    }
}
