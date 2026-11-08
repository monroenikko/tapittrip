<?php

declare(strict_types=1);

namespace App\Application\Expenses\Data;

final readonly class RecordSettlementData
{
    public function __construct(
        public string $payerId,
        public string $payeeId,
        public int $amountMinor,
        public string $currency,
        public string $settledAt,
        public ?string $notes = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            payerId: (string) $data['payer_id'],
            payeeId: (string) $data['payee_id'],
            amountMinor: (int) $data['amount_minor'],
            currency: strtoupper(trim((string) $data['currency'])),
            settledAt: (string) ($data['settled_at'] ?? now()->toIso8601String()),
            notes: isset($data['notes']) ? trim((string) $data['notes']) : null,
        );
    }
}
