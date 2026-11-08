<?php

declare(strict_types=1);

namespace App\Application\Expenses\Data;

final readonly class CreateExpenseData
{
    public function __construct(
        public string $payerId,
        public string $category,
        public string $title,
        public int $amountMinor,
        public string $currency,
        public float $exchangeRate,
        public string $expenseDate,
        public ?string $itineraryItemId = null,
        public ?string $stayId = null,
        public string $splitType = 'single',
        public ?string $notes = null,
        public ?string $receiptUrl = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data, string $defaultPayerId): self
    {
        return new self(
            payerId: (string) ($data['payer_id'] ?? $defaultPayerId),
            category: strtolower(trim((string) $data['category'])),
            title: trim((string) $data['title']),
            amountMinor: (int) $data['amount_minor'],
            currency: strtoupper(trim((string) $data['currency'])),
            exchangeRate: isset($data['exchange_rate']) ? (float) $data['exchange_rate'] : 1.0,
            expenseDate: (string) ($data['expense_date'] ?? now()->toDateString()),
            itineraryItemId: isset($data['itinerary_item_id']) ? (string) $data['itinerary_item_id'] : null,
            stayId: isset($data['stay_id']) ? (string) $data['stay_id'] : null,
            splitType: strtolower(trim((string) ($data['split_type'] ?? 'single'))),
            notes: isset($data['notes']) ? trim((string) $data['notes']) : null,
            receiptUrl: isset($data['receipt_url']) ? trim((string) $data['receipt_url']) : null,
        );
    }
}
