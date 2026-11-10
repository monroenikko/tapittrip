<?php

declare(strict_types=1);

namespace App\DTOs\Circles;

final readonly class CreateDirectInvitationData
{
    public function __construct(
        public string $friendCode,
        public string $proposedRole = 'viewer',
        public int $expiresInDays = 7,
    ) {}
}
