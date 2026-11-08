<?php

declare(strict_types=1);

namespace App\Application\Sync\Data;

final readonly class PushSyncOperationsData
{
    /**
     * @param  array<int, SyncOperationItemData>  $operations
     */
    public function __construct(
        public string $userId,
        public string $deviceKey,
        public array $operations,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(string $userId, array $data): self
    {
        $operations = array_map(
            static fn (array $item): SyncOperationItemData => SyncOperationItemData::fromArray($item),
            $data['operations'] ?? []
        );

        return new self(
            userId: $userId,
            deviceKey: (string) ($data['device_key'] ?? ''),
            operations: $operations,
        );
    }
}
