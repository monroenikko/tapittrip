<?php

declare(strict_types=1);

namespace App\Application\Trips\Services;

use App\Application\Expenses\Services\CountryCurrencyResolver;
use App\Application\Trips\Data\TodaySummaryResult;
use App\Application\Weather\Services\GetTripWeatherService;
use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
use Carbon\CarbonImmutable;
use Illuminate\Support\Collection;

final class GetTodaySummaryService
{
    public function __construct(
        private readonly GetTripWeatherService $weatherService,
    ) {}

    /**
     * Compute today's dashboard summary for the given trip.
     */
    public function handle(Trip $trip, ?CarbonImmutable $overrideNow = null): TodaySummaryResult
    {
        $timezone = $trip->primary_timezone ?: 'UTC';
        $now = $overrideNow ?: CarbonImmutable::now($timezone);
        $todayDate = $now->toDateString();
        $todayStart = $now->startOfDay();

        $startDate = $trip->start_date
            ? CarbonImmutable::parse($trip->start_date->format('Y-m-d'), $timezone)->startOfDay()
            : null;
        $endDate = $trip->end_date
            ? CarbonImmutable::parse($trip->end_date->format('Y-m-d'), $timezone)->startOfDay()
            : null;

        $tripStatus = 'active';
        $daysUntilStart = null;
        $activeDay = null;

        if ($startDate !== null && $todayStart->lessThan($startDate)) {
            $tripStatus = 'pre_trip';
            $daysUntilStart = (int) $todayStart->diffInDays($startDate, false);
        } elseif ($endDate !== null && $todayStart->greaterThan($endDate)) {
            $tripStatus = 'post_trip';
        } else {
            $tripStatus = 'active';
            $dayNumber = $startDate ? (int) $startDate->diffInDays($todayStart) + 1 : 1;

            $totalDays = $startDate && $endDate
                ? (int) $startDate->diffInDays($endDate) + 1
                : max(1, $trip->days()->count());

            $activeTripDay = $trip->days()->where('local_date', $todayDate)->first();

            $activeDay = [
                'day_number' => $dayNumber,
                'total_days' => $totalDays,
                'date' => $todayDate,
                'notes' => $activeTripDay?->notes,
            ];
        }

        // Today's Itinerary Items
        /** @var Collection<int, ItineraryItem> $todayItems */
        $todayItems = collect();
        if ($tripStatus === 'active') {
            $activeTripDay = $trip->days()->where('local_date', $todayDate)->first();
            if ($activeTripDay !== null) {
                $todayItems = $trip->itineraryItems()
                    ->where('trip_day_id', $activeTripDay->id)
                    ->with('place')
                    ->orderBy('sort_order')
                    ->get();
            } else {
                $todayItems = $trip->itineraryItems()
                    ->whereDate('starts_at_utc', $todayDate)
                    ->with('place')
                    ->orderBy('sort_order')
                    ->get();
            }
        }

        // Next Upcoming Unvisited Item
        /** @var ItineraryItem|null $nextUpcomingItem */
        $nextUpcomingItem = $todayItems->first(fn (ItineraryItem $item): bool => $item->status !== 'visited');
        if ($nextUpcomingItem === null) {
            $nextUpcomingItem = $trip->itineraryItems()
                ->where('status', '!=', 'visited')
                ->with('place')
                ->orderBy('sort_order')
                ->first();
        }

        // Current or Next Stay
        /** @var Stay|null $currentStay */
        $currentStay = $trip->stays()
            ->where(function ($query) use ($todayDate): void {
                $query->whereDate('check_in_at', '<=', $todayDate)
                    ->whereDate('check_out_at', '>=', $todayDate);
            })
            ->with('place')
            ->first();

        if ($currentStay === null) {
            $currentStay = $trip->stays()
                ->whereDate('check_in_at', '>=', $todayDate)
                ->with('place')
                ->orderBy('check_in_at')
                ->first();
        }

        if ($currentStay === null) {
            $currentStay = $trip->stays()->with('place')->first();
        }

        // Metrics
        $totalActivities = $trip->itineraryItems()->count();
        $completedActivities = $trip->itineraryItems()->where('status', 'visited')->count();
        $progressPercentage = $totalActivities > 0
            ? (int) round(($completedActivities / $totalActivities) * 100)
            : 0;

        $metrics = [
            'total_activities' => $totalActivities,
            'completed_activities' => $completedActivities,
            'progress_percentage' => $progressPercentage,
        ];

        // Budget pacing
        $budgetPacing = null;
        $budget = $trip->budget;
        $hasExpenses = $trip->expenses()->exists();

        if ($budget !== null || $hasExpenses) {
            $currency = $budget?->currency ?? $trip->destination_currency ?? CountryCurrencyResolver::resolve($trip->destination_country ?? $trip->title);

            $spentTodayMinor = (int) $trip->expenses()
                ->whereDate('expense_date', $todayDate)
                ->sum('base_amount_minor');

            $totalSpentMinor = (int) $trip->expenses()->sum('base_amount_minor');
            $remainingBudgetMinor = $budget !== null
                ? ($budget->total_budget_minor - $totalSpentMinor)
                : 0;
            $dailyBudgetMinor = $budget?->daily_budget_minor;

            $dailyUtilizationPercent = ($dailyBudgetMinor !== null && $dailyBudgetMinor > 0)
                ? round(($spentTodayMinor / $dailyBudgetMinor) * 100, 1)
                : null;

            $budgetPacing = [
                'currency' => $currency,
                'total_budget_minor' => $budget?->total_budget_minor ?? 0,
                'daily_budget_minor' => $dailyBudgetMinor,
                'spent_today_minor' => $spentTodayMinor,
                'total_spent_minor' => $totalSpentMinor,
                'remaining_budget_minor' => $remainingBudgetMinor,
                'daily_utilization_percent' => $dailyUtilizationPercent,
            ];
        }

        $weather = $this->weatherService?->getCurrentWeather($trip);

        return new TodaySummaryResult(
            trip: $trip,
            tripStatus: $tripStatus,
            daysUntilStart: $daysUntilStart,
            activeDay: $activeDay,
            todayItems: $todayItems,
            nextUpcomingItem: $nextUpcomingItem,
            currentStay: $currentStay,
            metrics: $metrics,
            timezone: $timezone,
            localTime: $now->toIso8601String(),
            budgetPacing: $budgetPacing,
            weather: $weather,
        );
    }
}
