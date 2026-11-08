<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Data;

final readonly class TripAssistantResult
{
    /**
     * @param  array<string, mixed>  $contextSummary
     * @param  list<array<string, mixed>>  $suggestedActions
     */
    public function __construct(
        public string $reply,
        public string $category,
        public array $contextSummary = [],
        public array $suggestedActions = [],
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'reply' => $this->reply,
            'category' => $this->category,
            'context_summary' => $this->contextSummary,
            'suggested_actions' => $this->suggestedActions,
        ];
    }
}
