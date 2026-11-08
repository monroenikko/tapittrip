<?php

declare(strict_types=1);

namespace App\Application\Sync\Data;

final readonly class SyncOperationItemData
{
    /**
     * @param  array<string, mixed>|null  $payload
     */
    public function __construct(
        public string $operationId,
        public ?string $tripId,
        public string $entityType,
        public string $entityId,
        public string $operationType,
        public ?array $payload = null,
        public int $baseVersion = 1,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            operationId: (string) $data['operation_id'],
            tripId: isset($data['trip_id']) ? (string) $data['trip_id'] : null,
            entityType: (string) $data['entity_type'],
            entityId: (string) $data['entity_id'],
            operationType: (string) $data['operation_type'],
            payload: isset($data['payload']) && is_array($data['payload']) ? $data['payload'] : null,
            baseVersion: isset($data['base_version']) ? (int) $data['base_version'] : 1,
        );
    }
}
