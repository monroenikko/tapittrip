<?php

declare(strict_types=1);

namespace App\DTOs\Circles;

final readonly class UpdateTripTravelerData
{
    public function __construct(
        public ?string $displayName = null,
        public ?string $travelerCategory = null,
        public ?string $restrictedNotes = null,
        public bool $clearRestrictedNotes = false,
        public ?int $baseVersion = null,
    ) {}
}
