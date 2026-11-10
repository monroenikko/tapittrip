<?php

declare(strict_types=1);

namespace App\DTOs\Expenses;

final readonly class CreateExpenseData
{
    /**
     * @param  list<string>|null  $participantIds
     * @param  array<int, array<string, mixed>>|null  $splits
     */
    public function __construct(
        public string $payerId,
        public string $createdByUserId,
        public string $category,
        public string $title,
        public int $amountMinor,
        public string $currency,
        public ?float $exchangeRate,
        public string $expenseDate,
        public ?string $itineraryItemId = null,
        public ?string $stayId = null,
        public string $splitType = 'single',
        public ?string $visibility = null,
        public ?array $participantIds = null,
        public ?array $splits = null,
        public ?string $notes = null,
        public ?string $receiptUrl = null,
        public ?string $rateSource = null,
        public ?string $rateCapturedAt = null,
        public ?string $conversionStatus = null,
        public ?string $clientOperationId = null,
        public ?string $id = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data, string $defaultPayerId, ?string $actorId = null): self
    {
        return new self(
            payerId: (string) ($data['payer_id'] ?? $defaultPayerId),
            createdByUserId: $actorId ?? $defaultPayerId,
            category: strtolower(trim((string) $data['category'])),
            title: trim((string) $data['title']),
            amountMinor: (int) $data['amount_minor'],
            currency: strtoupper(trim((string) $data['currency'])),
            exchangeRate: isset($data['exchange_rate']) && is_numeric($data['exchange_rate']) ? (float) $data['exchange_rate'] : null,
            expenseDate: (string) ($data['expense_date'] ?? now()->toDateString()),
            itineraryItemId: isset($data['itinerary_item_id']) ? (string) $data['itinerary_item_id'] : null,
            stayId: isset($data['stay_id']) ? (string) $data['stay_id'] : null,
            splitType: strtolower(trim((string) ($data['split_type'] ?? 'single'))),
            visibility: isset($data['visibility']) ? strtolower(trim((string) $data['visibility'])) : null,
            participantIds: isset($data['participant_ids']) && is_array($data['participant_ids'])
                ? array_values(array_map('strval', $data['participant_ids']))
                : null,
            splits: isset($data['splits']) && is_array($data['splits']) ? $data['splits'] : null,
            notes: isset($data['notes']) ? trim((string) $data['notes']) : null,
            receiptUrl: isset($data['receipt_url']) ? trim((string) $data['receipt_url']) : null,
            rateSource: isset($data['rate_source']) ? trim((string) $data['rate_source']) : null,
            rateCapturedAt: isset($data['rate_captured_at']) ? (string) $data['rate_captured_at'] : null,
            conversionStatus: isset($data['conversion_status']) ? strtolower(trim((string) $data['conversion_status'])) : null,
            clientOperationId: isset($data['client_operation_id']) ? (string) $data['client_operation_id'] : null,
            id: isset($data['id']) ? (string) $data['id'] : null,
        );
    }
}
