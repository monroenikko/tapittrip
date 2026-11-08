<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Data;

final readonly class ApplyAiItineraryData
{
    /**
     * @param  array<int, array<string, mixed>>  $days
     */
    public function __construct(
        public string $tripId,
        public array $days,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(string $tripId, array $data): self
    {
        return new self(
            tripId: $tripId,
            days: $data['days'] ?? [],
        );
    }
}
