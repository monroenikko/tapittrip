<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Data;

use Carbon\Carbon;
use Carbon\CarbonInterface;

final readonly class CreateItineraryItemData
{
    public function __construct(
        public string $title,
        public string $kind = 'attraction',
        public ?string $tripDayId = null,
        public ?string $placeId = null,
        public ?CreatePlaceData $place = null,
        public ?string $notes = null,
        public ?CarbonInterface $startsAtUtc = null,
        public ?CarbonInterface $endsAtUtc = null,
        public string $timezone = 'UTC',
        public ?int $sortOrder = null,
        public string $status = 'planned',
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data, ?string $defaultTimezone = 'UTC'): self
    {
        $timezone = (string) ($data['timezone'] ?? $defaultTimezone ?? 'UTC');

        return new self(
            title: (string) $data['title'],
            kind: (string) ($data['kind'] ?? 'attraction'),
            tripDayId: isset($data['trip_day_id']) ? (string) $data['trip_day_id'] : null,
            placeId: isset($data['place_id']) ? (string) $data['place_id'] : null,
            place: isset($data['place']) && is_array($data['place']) ? CreatePlaceData::from($data['place']) : null,
            notes: isset($data['notes']) ? (string) $data['notes'] : null,
            startsAtUtc: isset($data['starts_at_utc']) && $data['starts_at_utc'] !== null
                ? Carbon::parse((string) $data['starts_at_utc'])->utc()
                : null,
            endsAtUtc: isset($data['ends_at_utc']) && $data['ends_at_utc'] !== null
                ? Carbon::parse((string) $data['ends_at_utc'])->utc()
                : null,
            timezone: $timezone,
            sortOrder: isset($data['sort_order']) && $data['sort_order'] !== null ? (int) $data['sort_order'] : null,
            status: (string) ($data['status'] ?? 'planned'),
        );
    }
}
