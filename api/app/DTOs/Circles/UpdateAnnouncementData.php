<?php

declare(strict_types=1);

namespace App\DTOs\Circles;

final readonly class UpdateAnnouncementData
{
    public function __construct(
        public ?string $title = null,
        public ?string $body = null,
        public ?bool $isPinned = null,
        public ?int $baseVersion = null,
    ) {}
}
