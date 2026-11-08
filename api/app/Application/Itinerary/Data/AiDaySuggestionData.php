<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Data;

final readonly class AiDaySuggestionData
{
    /**
     * @param  array<int, AiActivitySuggestionData>  $activities
     * @param  array<string, mixed>|null  $budgetEstimate
     */
    public function __construct(
        public int $dayNumber,
        public string $title,
        public string $theme,
        public string $primaryNeighborhood,
        public array $activities,
        public ?array $budgetEstimate = null,
        public ?string $familyTip = null,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'day_number' => $this->dayNumber,
            'title' => $this->title,
            'theme' => $this->theme,
            'primary_neighborhood' => $this->primaryNeighborhood,
            'activities' => array_map(static fn (AiActivitySuggestionData $a) => $a->toArray(), $this->activities),
            'budget_estimate' => $this->budgetEstimate,
            'family_tip' => $this->familyTip,
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        $activities = array_map(
            static fn (array $a) => AiActivitySuggestionData::fromArray($a),
            $data['activities'] ?? []
        );

        return new self(
            dayNumber: (int) ($data['day_number'] ?? 1),
            title: (string) ($data['title'] ?? 'Day 1'),
            theme: (string) ($data['theme'] ?? 'Exploration'),
            primaryNeighborhood: (string) ($data['primary_neighborhood'] ?? 'City Center'),
            activities: $activities,
            budgetEstimate: isset($data['budget_estimate']) && is_array($data['budget_estimate']) ? $data['budget_estimate'] : null,
            familyTip: isset($data['family_tip']) ? (string) $data['family_tip'] : null,
        );
    }
}
