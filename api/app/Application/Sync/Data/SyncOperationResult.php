<?php

declare(strict_types=1);

namespace App\Application\Sync\Data;

final readonly class SyncOperationResult
{
    /**
     * @param  array<string, mixed>|null  $conflictDetails
     */
    public function __construct(
        public string $operationId,
        public string $status,
        public ?int $serverSequence = null,
        public ?int $currentVersion = null,
        public ?array $conflictDetails = null,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'operation_id' => $this->operationId,
            'status' => $this->status,
            'server_sequence' => $this->serverSequence,
            'current_version' => $this->currentVersion,
            'conflict_details' => $this->conflictDetails,
        ];
    }
}
