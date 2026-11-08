<?php

declare(strict_types=1);

namespace App\Application\Sync\Data;

final readonly class PullSyncChangesData
{
    public function __construct(
        public string $userId,
        public string $deviceKey,
        public int $cursor = 0,
        public ?string $tripId = null,
        public int $limit = 50,
    ) {}
}
