<?php

declare(strict_types=1);

namespace App\Application\Journal\Data;

final class CreateJournalEntryData
{
    /**
     * @param  array<int, string>  $photos
     */
    public function __construct(
        public string $title,
        public string $content,
        public string $entryDate,
        public ?string $locationName = null,
        public ?string $weather = null,
        public ?string $mood = null,
        public bool $isShared = false,
        public ?string $itineraryItemId = null,
        public array $photos = [],
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            title: trim((string) $data['title']),
            content: trim((string) $data['content']),
            entryDate: (string) ($data['entry_date'] ?? date('Y-m-d')),
            locationName: isset($data['location_name']) && ! empty($data['location_name'])
                ? trim((string) $data['location_name'])
                : null,
            weather: isset($data['weather']) && ! empty($data['weather'])
                ? trim((string) $data['weather'])
                : null,
            mood: isset($data['mood']) && ! empty($data['mood'])
                ? trim((string) $data['mood'])
                : null,
            isShared: (bool) ($data['is_shared'] ?? false),
            itineraryItemId: isset($data['itinerary_item_id']) && ! empty($data['itinerary_item_id'])
                ? (string) $data['itinerary_item_id']
                : null,
            photos: isset($data['photos']) && is_array($data['photos'])
                ? array_values(array_map('strval', $data['photos']))
                : [],
        );
    }
}
