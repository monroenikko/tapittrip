<?php

declare(strict_types=1);

namespace App\DTOs\Circles;

use App\Models\TripOwnershipTransfer;

final readonly class InitiateOwnershipTransferResult
{
    public function __construct(
        public TripOwnershipTransfer $transfer,
        public bool $alreadyPending = false,
    ) {}
}
