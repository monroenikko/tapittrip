<?php

declare(strict_types=1);

namespace App\DTOs\Circles;

use App\Models\Trip;
use App\Models\TripMember;

final readonly class AcceptTripInvitationResult
{
    public function __construct(
        public Trip $trip,
        public TripMember $member,
        public bool $alreadyMember = false,
    ) {}
}

