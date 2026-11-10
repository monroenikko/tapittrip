<?php

declare(strict_types=1);

namespace App\DTOs\Circles;

use App\Models\TripInvitation;

final readonly class CreatedTripInvitationResult
{
    public function __construct(
        public TripInvitation $invitation,
        public string $rawToken,
        public string $shareUrl,
    ) {}
}
