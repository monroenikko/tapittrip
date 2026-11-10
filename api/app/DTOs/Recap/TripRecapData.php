<?php

declare(strict_types=1);

namespace App\DTOs\Recap;

final readonly class TripRecapData
{
    /**
     * @param  array{
     *     id: string,
     *     title: string,
     *     destination: string,
     *     start_date: ?string,
     *     end_date: ?string,
     *     duration_days: ?int,
     *     status: string
     * }  $trip
     * @param  array{
     *     total_places_visited: int,
     *     total_places_planned: int,
     *     completion_rate_percentage: int,
     *     total_stays: int,
     *     total_nights: int,
     *     total_companions: int
     * }  $highlights
     * @param  array{
     *     total_photos: int,
     *     photos: list<array{
     *         url: string,
     *         caption: string,
     *         date: ?string,
     *         author_name: string,
     *         mood: ?string,
     *         location_name: ?string
     *     }>,
     *     moments: list<array{
     *         id: string,
     *         title: string,
     *         content: string,
     *         author_name: string,
     *         author_avatar_url: ?string,
     *         entry_date: ?string,
     *         mood: ?string,
     *         mood_emoji: ?string,
     *         weather: ?string,
     *         location_name: ?string,
     *         cover_photo: ?string,
     *         is_shared: bool
     *     }>,
     *     mood_breakdown: array<string, int>,
     *     top_mood: ?string
     * }  $storyAlbum
     * @param  array{
     *     currency: string,
     *     total_spent_minor: int,
     *     formatted_total_spent: string,
     *     expenses_count: int,
     *     top_category: ?string,
     *     has_budget: bool,
     *     budget_utilization_percent: ?float
     * }  $expenseSummary
     */
    public function __construct(
        public array $trip,
        public array $highlights,
        public array $storyAlbum,
        public array $expenseSummary,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'trip' => $this->trip,
            'highlights' => $this->highlights,
            'story_album' => $this->storyAlbum,
            'expense_summary' => $this->expenseSummary,
        ];
    }
}
