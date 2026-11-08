<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Data;

final readonly class GenerateAiItineraryData
{
    /**
     * @param  array<int, string>  $interests
     */
    public function __construct(
        public string $destination,
        public int $durationDays = 3,
        public string $budgetTier = 'moderate',
        public string $travelParty = 'couple',
        public string $pace = 'balanced',
        public array $interests = ['food', 'culture'],
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            destination: (string) ($data['destination'] ?? 'Tokyo, Japan'),
            durationDays: isset($data['duration_days']) ? (int) $data['duration_days'] : 3,
            budgetTier: (string) ($data['budget_tier'] ?? 'moderate'),
            travelParty: (string) ($data['travel_party'] ?? 'couple'),
            pace: (string) ($data['pace'] ?? 'balanced'),
            interests: isset($data['interests']) && is_array($data['interests'])
                ? array_values($data['interests'])
                : ['food', 'culture'],
        );
    }
}
