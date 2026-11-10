<?php

declare(strict_types=1);

namespace App\DTOs\Activity;

use Carbon\CarbonImmutable;

final readonly class RecordActivityEventData
{
    /**
     * @param  array<string, mixed>|null  $metadata
     */
    public function __construct(
        public string $eventType,
        public string $title,
        public ?string $summary = null,
        public ?string $entityType = null,
        public ?string $entityId = null,
        public ?array $metadata = null,
        public ?CarbonImmutable $occurredAt = null,
    ) {}
}
