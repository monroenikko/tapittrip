<?php

declare(strict_types=1);

namespace App\Application\Expenses\Data;

final readonly class UpdateExpenseData
{
    public function __construct(
        public ?string $payerId = null,
        public ?string $category = null,
        public ?string $title = null,
        public ?int $amountMinor = null,
        public ?string $currency = null,
        public ?float $exchangeRate = null,
        public ?string $expenseDate = null,
        public ?string $itineraryItemId = null,
        public ?string $stayId = null,
        public ?string $splitType = null,
        public ?string $notes = null,
        public ?string $receiptUrl = null,
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
            exchangeRate: isset($data['exchange_rate']) ? (float) $data['exchange_rate'] : null,
            expenseDate: isset($data['expense_date']) ? (string) $data['expense_date'] : null,
            itineraryItemId: array_key_exists('itinerary_item_id', $data) ? ($data['itinerary_item_id'] ? (string) $data['itinerary_item_id'] : null) : null,
            stayId: array_key_exists('stay_id', $data) ? ($data['stay_id'] ? (string) $data['stay_id'] : null) : null,
            splitType: isset($data['split_type']) ? strtolower(trim((string) $data['split_type'])) : null,
            notes: array_key_exists('notes', $data) ? ($data['notes'] ? trim((string) $data['notes']) : null) : null,
            receiptUrl: array_key_exists('receipt_url', $data) ? ($data['receipt_url'] ? trim((string) $data['receipt_url']) : null) : null,
        );
    }
}
