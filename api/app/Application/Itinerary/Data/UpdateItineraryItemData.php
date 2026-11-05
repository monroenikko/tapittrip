<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Data;

use Carbon\Carbon;
use Carbon\CarbonInterface;

final readonly class UpdateItineraryItemData
{
    public function __construct(
        public ?string $title = null,
        public ?string $kind = null,
        public ?string $tripDayId = null,
        public bool $clearTripDay = false,
        public ?string $placeId = null,
        public bool $clearPlace = false,
        public ?CreatePlaceData $place = null,
        public ?string $notes = null,
        public bool $clearNotes = false,
        public ?CarbonInterface $startsAtUtc = null,
        public bool $clearStartsAtUtc = false,
        public ?CarbonInterface $endsAtUtc = null,
        public bool $clearEndsAtUtc = false,
        public ?string $timezone = null,
        public ?int $sortOrder = null,
        public ?string $status = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data): self
    {
        return new self(
            title: isset($data['title']) ? (string) $data['title'] : null,
            kind: isset($data['kind']) ? (string) $data['kind'] : null,
            tripDayId: isset($data['trip_day_id']) ? (string) $data['trip_day_id'] : null,
            clearTripDay: array_key_exists('trip_day_id', $data) && $data['trip_day_id'] === null,
            placeId: isset($data['place_id']) ? (string) $data['place_id'] : null,
            clearPlace: array_key_exists('place_id', $data) && $data['place_id'] === null,
            place: isset($data['place']) && is_array($data['place']) ? CreatePlaceData::from($data['place']) : null,
            notes: isset($data['notes']) ? (string) $data['notes'] : null,
            clearNotes: array_key_exists('notes', $data) && $data['notes'] === null,
            startsAtUtc: isset($data['starts_at_utc']) && $data['starts_at_utc'] !== null
                ? Carbon::parse((string) $data['starts_at_utc'])->utc()
                : null,
            clearStartsAtUtc: array_key_exists('starts_at_utc', $data) && $data['starts_at_utc'] === null,
            endsAtUtc: isset($data['ends_at_utc']) && $data['ends_at_utc'] !== null
                ? Carbon::parse((string) $data['ends_at_utc'])->utc()
                : null,
            clearEndsAtUtc: array_key_exists('ends_at_utc', $data) && $data['ends_at_utc'] === null,
            timezone: isset($data['timezone']) ? (string) $data['timezone'] : null,
            sortOrder: isset($data['sort_order']) && $data['sort_order'] !== null ? (int) $data['sort_order'] : null,
            status: isset($data['status']) ? (string) $data['status'] : null,
        );
    }
}
