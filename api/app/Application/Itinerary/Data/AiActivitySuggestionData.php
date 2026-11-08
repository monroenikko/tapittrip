<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Data;

final readonly class AiActivitySuggestionData
{
    /**
     * @param  array<string, mixed>|null  $costEstimate
     */
    public function __construct(
        public string $title,
        public string $kind, // activity, dining, sightseeing, transit
        public string $neighborhood,
        public ?string $description = null,
        public ?string $plannedStartTime = null,
        public ?string $plannedEndTime = null,
        public ?string $placeName = null,
        public ?string $placeAddress = null,
        public ?float $latitude = null,
        public ?float $longitude = null,
        public ?array $costEstimate = null,
        public ?string $accessibilityNote = null,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'title' => $this->title,
            'kind' => $this->kind,
            'neighborhood' => $this->neighborhood,
            'description' => $this->description,
            'planned_start_time' => $this->plannedStartTime,
            'planned_end_time' => $this->plannedEndTime,
            'place_name' => $this->placeName,
            'place_address' => $this->placeAddress,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'cost_estimate' => $this->costEstimate,
            'accessibility_note' => $this->accessibilityNote,
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            title: (string) $data['title'],
            kind: (string) ($data['kind'] ?? 'sightseeing'),
            neighborhood: (string) ($data['neighborhood'] ?? 'Downtown'),
            description: isset($data['description']) ? (string) $data['description'] : null,
            plannedStartTime: isset($data['planned_start_time']) ? (string) $data['planned_start_time'] : null,
            plannedEndTime: isset($data['planned_end_time']) ? (string) $data['planned_end_time'] : null,
            placeName: isset($data['place_name']) ? (string) $data['place_name'] : null,
            placeAddress: isset($data['place_address']) ? (string) $data['place_address'] : null,
            latitude: isset($data['latitude']) ? (float) $data['latitude'] : null,
            longitude: isset($data['longitude']) ? (float) $data['longitude'] : null,
            costEstimate: isset($data['cost_estimate']) && is_array($data['cost_estimate']) ? $data['cost_estimate'] : null,
            accessibilityNote: isset($data['accessibility_note']) ? (string) $data['accessibility_note'] : null,
        );
    }
}
