<?php

declare(strict_types=1);

namespace App\Application\Checklists\Data;

final readonly class UpdateChecklistItemData
{
    public function __construct(
        public ?string $title = null,
        public ?string $category = null,
        public ?bool $isPacked = null,
        public ?int $quantity = null,
        public ?string $notes = null,
        public ?string $photoUrl = null,
        public ?int $sortOrder = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data): self
    {
        return new self(
            title: isset($data['title']) ? (string) $data['title'] : null,
            category: isset($data['category']) ? (string) $data['category'] : null,
            isPacked: isset($data['is_packed']) ? (bool) $data['is_packed'] : null,
            quantity: isset($data['quantity']) ? (int) $data['quantity'] : null,
            notes: array_key_exists('notes', $data) ? ($data['notes'] !== null ? (string) $data['notes'] : null) : null,
            photoUrl: array_key_exists('photo_url', $data) ? ($data['photo_url'] !== null ? (string) $data['photo_url'] : null) : null,
            sortOrder: isset($data['sort_order']) ? (int) $data['sort_order'] : null,
        );
    }
}
