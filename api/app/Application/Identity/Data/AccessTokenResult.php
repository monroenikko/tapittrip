<?php

declare(strict_types=1);

namespace App\Application\Identity\Data;

use App\Models\User;

final readonly class AccessTokenResult
{
    public function __construct(
        public User $user,
        public string $plainTextToken,
    ) {}
}
