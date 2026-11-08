<?php

declare(strict_types=1);

namespace App\Application\Sync\Data;

final readonly class PullSyncResult
{
    /**
     * @param  array<int, array<string, mixed>>  $operations
     */
    public function __construct(
        public int $cursor,
        public array $operations,
        public bool $hasMore,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'cursor' => $this->cursor,
            'operations' => $this->operations,
            'has_more' => $this->hasMore,
        ];
    }
}
