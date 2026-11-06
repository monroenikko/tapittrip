<?php

declare(strict_types=1);

namespace App\Application\Checklists\Data;

final readonly class CreateChecklistItemData
{
    public function __construct(
        public string $title,
        public string $category = 'other',
        public int $quantity = 1,
        public ?string $notes = null,
        public ?string $photoUrl = null,
        public int $sortOrder = 0,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data): self
    {
        return new self(
            title: (string) $data['title'],
            category: (string) ($data['category'] ?? 'other'),
            quantity: (int) ($data['quantity'] ?? 1),
            notes: isset($data['notes']) ? (string) $data['notes'] : null,
            photoUrl: isset($data['photo_url']) ? (string) $data['photo_url'] : null,
            sortOrder: (int) ($data['sort_order'] ?? 0),
        );
    }
}
