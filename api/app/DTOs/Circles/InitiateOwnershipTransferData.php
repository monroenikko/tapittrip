<?php

declare(strict_types=1);

namespace App\DTOs\Circles;

final readonly class InitiateOwnershipTransferData
{
    public function __construct(
        public string $targetMemberId,
        public string $formerOwnerRole = 'editor',
    ) {}
}
