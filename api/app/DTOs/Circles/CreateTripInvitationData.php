<?php

declare(strict_types=1);

namespace App\DTOs\Circles;

final readonly class CreateTripInvitationData
{
    public function __construct(
        public string $proposedRole = 'viewer',
        public int $maxUses = 1,
        public int $expiresInDays = 7,
    ) {}
}

