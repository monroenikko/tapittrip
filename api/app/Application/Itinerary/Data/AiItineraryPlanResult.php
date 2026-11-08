<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Data;

final readonly class AiItineraryPlanResult
{
    /**
     * @param  array<int, AiDaySuggestionData>  $days
     * @param  array<string, mixed>|null  $totalEstimatedBudget
     */
    public function __construct(
        public string $destination,
        public string $summary,
        public string $travelParty,
        public string $pace,
        public array $days,
        public ?array $totalEstimatedBudget = null,
        public ?string $weatherAlternativeNote = null,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'destination' => $this->destination,
            'summary' => $this->summary,
            'travel_party' => $this->travelParty,
            'pace' => $this->pace,
            'days' => array_map(static fn (AiDaySuggestionData $d) => $d->toArray(), $this->days),
            'total_estimated_budget' => $this->totalEstimatedBudget,
            'weather_alternative_note' => $this->weatherAlternativeNote,
        ];
    }
}
