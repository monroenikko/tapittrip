<?php

declare(strict_types=1);

namespace App\DTOs\Expenses;

final readonly class UpdateExpenseData
{
    /**
     * @param  list<string>|null  $participantIds
     * @param  array<int, array<string, mixed>>|null  $splits
     */
    public function __construct(
        public ?string $payerId = null,
        public ?string $category = null,
        public ?string $title = null,
        public ?int $amountMinor = null,
        public ?string $currency = null,
        public ?float $exchangeRate = null,
        public bool $hasExchangeRate = false,
        public ?string $expenseDate = null,
        public ?string $itineraryItemId = null,
        public bool $hasItineraryItemId = false,
        public ?string $stayId = null,
        public bool $hasStayId = false,
        public ?string $splitType = null,
        public ?string $visibility = null,
        public ?array $participantIds = null,
        public bool $hasParticipantIds = false,
        public ?array $splits = null,
        public bool $hasSplits = false,
        public ?string $notes = null,
        public bool $hasNotes = false,
        public ?string $receiptUrl = null,
        public bool $hasReceiptUrl = false,
        public ?string $rateSource = null,
        public ?string $rateCapturedAt = null,
        public ?string $conversionStatus = null,
        public ?int $baseVersion = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            payerId: isset($data['payer_id']) ? (string) $data['payer_id'] : null,
            category: isset($data['category']) ? strtolower(trim((string) $data['category'])) : null,
            title: isset($data['title']) ? trim((string) $data['title']) : null,
            amountMinor: isset($data['amount_minor']) ? (int) $data['amount_minor'] : null,
            currency: isset($data['currency']) ? strtoupper(trim((string) $data['currency'])) : null,
            exchangeRate: isset($data['exchange_rate']) && is_numeric($data['exchange_rate']) ? (float) $data['exchange_rate'] : null,
            hasExchangeRate: array_key_exists('exchange_rate', $data),
            expenseDate: isset($data['expense_date']) ? (string) $data['expense_date'] : null,
            itineraryItemId: array_key_exists('itinerary_item_id', $data) ? ($data['itinerary_item_id'] ? (string) $data['itinerary_item_id'] : null) : null,
            hasItineraryItemId: array_key_exists('itinerary_item_id', $data),
            stayId: array_key_exists('stay_id', $data) ? ($data['stay_id'] ? (string) $data['stay_id'] : null) : null,
            hasStayId: array_key_exists('stay_id', $data),
            splitType: isset($data['split_type']) ? strtolower(trim((string) $data['split_type'])) : null,
            visibility: isset($data['visibility']) ? strtolower(trim((string) $data['visibility'])) : null,
            participantIds: array_key_exists('participant_ids', $data)
                ? (is_array($data['participant_ids']) ? array_values(array_map('strval', $data['participant_ids'])) : null)
                : null,
            hasParticipantIds: array_key_exists('participant_ids', $data),
            splits: array_key_exists('splits', $data) && is_array($data['splits']) ? $data['splits'] : null,
            hasSplits: array_key_exists('splits', $data),
            notes: array_key_exists('notes', $data) ? ($data['notes'] ? trim((string) $data['notes']) : null) : null,
            hasNotes: array_key_exists('notes', $data),
            receiptUrl: array_key_exists('receipt_url', $data) ? ($data['receipt_url'] ? trim((string) $data['receipt_url']) : null) : null,
            hasReceiptUrl: array_key_exists('receipt_url', $data),
            rateSource: isset($data['rate_source']) ? trim((string) $data['rate_source']) : null,
            rateCapturedAt: isset($data['rate_captured_at']) ? (string) $data['rate_captured_at'] : null,
            conversionStatus: isset($data['conversion_status']) ? strtolower(trim((string) $data['conversion_status'])) : null,
            baseVersion: isset($data['base_version']) ? (int) $data['base_version'] : null,
        );
    }
}
