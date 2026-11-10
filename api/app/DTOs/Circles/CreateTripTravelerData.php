<?php

declare(strict_types=1);

namespace App\DTOs\Circles;

final readonly class CreateTripTravelerData
{
    public function __construct(
        public string $displayName,
        public string $travelerCategory = 'child',
        public ?string $restrictedNotes = null,
        public ?string $linkedMemberId = null,
    ) {}
}
