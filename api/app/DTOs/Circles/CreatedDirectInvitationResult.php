<?php

declare(strict_types=1);

namespace App\DTOs\Circles;

use App\Models\TripInvitation;

final readonly class CreatedDirectInvitationResult
{
    public function __construct(
        public TripInvitation $invitation,
        public bool $alreadyPending = false,
    ) {}
}
