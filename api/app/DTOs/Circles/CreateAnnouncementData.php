<?php

declare(strict_types=1);

namespace App\DTOs\Circles;

final readonly class CreateAnnouncementData
{
    public function __construct(
        public string $title,
        public string $body,
        public bool $isPinned = false,
        public ?string $clientOperationId = null,
    ) {}
}

