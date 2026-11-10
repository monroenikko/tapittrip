<?php

declare(strict_types=1);

namespace App\DTOs\Expenses;

final readonly class RecordSettlementData
{
    public function __construct(
        public string $payerId,
        public string $payeeId,
        public int $amountMinor,
        public string $currency,
        public string $settledAt,
        public ?string $notes = null,
        public ?float $exchangeRate = null,
        public ?string $rateSource = null,
        public ?string $rateCapturedAt = null,
        public ?string $clientOperationId = null,
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
            exchangeRate: isset($data['exchange_rate']) && is_numeric($data['exchange_rate']) ? (float) $data['exchange_rate'] : null,
            rateSource: isset($data['rate_source']) ? trim((string) $data['rate_source']) : null,
            rateCapturedAt: isset($data['rate_captured_at']) ? (string) $data['rate_captured_at'] : null,
            clientOperationId: isset($data['client_operation_id']) ? (string) $data['client_operation_id'] : null,
        );
    }
}
