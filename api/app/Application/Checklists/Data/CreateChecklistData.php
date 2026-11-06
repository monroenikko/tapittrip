<?php

declare(strict_types=1);

namespace App\Application\Checklists\Data;

final readonly class CreateChecklistData
{
    public function __construct(
        public string $title,
        public string $type = 'packing',
        public ?string $description = null,
        public int $sortOrder = 0,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data): self
    {
        return new self(
            title: (string) $data['title'],
            type: (string) ($data['type'] ?? 'packing'),
            description: isset($data['description']) ? (string) $data['description'] : null,
            sortOrder: (int) ($data['sort_order'] ?? 0),
        );
    }
}
