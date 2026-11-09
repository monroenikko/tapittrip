<?php

declare(strict_types=1);

namespace App\Application\Journal\Data;

final class UpdateJournalEntryData
{
    /**
     * @param  array<int, string>|null  $photos
     */
    public function __construct(
        public ?string $title = null,
        public ?string $content = null,
        public ?string $entryDate = null,
        public ?string $locationName = null,
        public ?string $weather = null,
        public ?string $mood = null,
        public ?bool $isShared = null,
        public ?string $itineraryItemId = null,
        public ?array $photos = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            title: isset($data['title']) ? trim((string) $data['title']) : null,
            content: isset($data['content']) ? trim((string) $data['content']) : null,
            entryDate: isset($data['entry_date']) ? (string) $data['entry_date'] : null,
            locationName: array_key_exists('location_name', $data)
                ? ($data['location_name'] ? trim((string) $data['location_name']) : null)
                : null,
            weather: array_key_exists('weather', $data)
                ? ($data['weather'] ? trim((string) $data['weather']) : null)
                : null,
            mood: array_key_exists('mood', $data)
                ? ($data['mood'] ? trim((string) $data['mood']) : null)
                : null,
            isShared: isset($data['is_shared']) ? (bool) $data['is_shared'] : null,
            itineraryItemId: array_key_exists('itinerary_item_id', $data)
                ? ($data['itinerary_item_id'] ? (string) $data['itinerary_item_id'] : null)
                : null,
            photos: isset($data['photos']) && is_array($data['photos'])
                ? array_values(array_map('strval', $data['photos']))
                : null,
        );
    }
}
