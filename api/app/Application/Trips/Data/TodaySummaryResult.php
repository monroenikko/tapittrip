<?php

declare(strict_types=1);

namespace App\Application\Trips\Data;

use App\Application\Weather\Data\WeatherConditionData;
use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Collection;

final readonly class TodaySummaryResult
{
    /**
     * @param  Collection<int, ItineraryItem>  $todayItems
     * @param  array{day_number: int, total_days: int, date: string, title: ?string}|null  $activeDay
     * @param  array{total_activities: int, completed_activities: int, progress_percentage: int}  $metrics
     */
    public function __construct(
        public Trip $trip,
        public string $tripStatus,
        public ?int $daysUntilStart,
        public ?array $activeDay,
        public Collection $todayItems,
        public ?ItineraryItem $nextUpcomingItem,
        public ?Stay $currentStay,
        public array $metrics,
        public string $timezone,
        public string $localTime,
        public ?array $budgetPacing = null,
        public ?WeatherConditionData $weather = null,
    ) {}
}
