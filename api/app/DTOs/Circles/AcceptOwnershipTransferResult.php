<?php

declare(strict_types=1);

namespace App\DTOs\Circles;

use App\Models\Trip;
use App\Models\TripOwnershipTransfer;

final readonly class AcceptOwnershipTransferResult
{
    public function __construct(
        public Trip $trip,
        public TripOwnershipTransfer $transfer,
    ) {}
}
