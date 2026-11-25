<?php

declare(strict_types=1);

namespace App\Services\Trip;

use App\DTOs\Trip\CreateTripData;
use App\DTOs\Trip\TodaySummaryResult;
use App\DTOs\Trip\UpdateTripData;
use App\Models\ItineraryItem;
use App\Models\Reminder;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\TripNotification;
use App\Models\User;
use App\Services\Expenses\CountryCurrencyResolver;
use App\Services\Itinerary\ItineraryService;
use App\Services\Notifications\NotificationService;
use App\Services\Weather\WeatherService;
use Carbon\CarbonImmutable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

final class TripService
{
    public function __construct(
        private readonly WeatherService $weatherService,
        private readonly ItineraryService $itineraryService,
    ) {}

    /**
     * List all trips the user is a member of.
     *
     * @return Collection<int, Trip>
     */
    public function getUserTrips(User $user): Collection
    {
        return $user->trips()
            ->with(['members'])
            ->orderByDesc('created_at')
            ->get();
    }

    /**
     * Create a new trip and assign the creator as the owner.
     */
    public function create(User $owner, CreateTripData $data): Trip
    {
        return DB::transaction(function () use ($owner, $data): Trip {
            /** @var Trip $trip */
            $trip = Trip::query()->create([
                'owner_id' => $owner->id,
                'title' => $data->title,
                'start_date' => $data->startDate,
                'end_date' => $data->endDate,
                'primary_timezone' => $data->primaryTimezone,
                'origin_country' => $data->originCountry,
                'destination_country' => $data->destinationCountry,
                'trip_type' => $data->tripType,
                'planning_mode' => $data->planningMode,
                'status' => 'planned',
                'version' => 1,
            ]);

            $trip->members()->create([
                'user_id' => $owner->id,
                'role' => 'owner',
                'invitation_status' => 'accepted',
            ]);

            if ($trip->start_date !== null && $trip->end_date !== null) {
                $this->itineraryService->ensureDaysForTrip($trip);
            }

            return $trip;
        });
    }

    /**
     * Update an existing trip.
     *
     * @param  array<string, mixed>  $rawPayload
     */
    public function update(Trip $trip, UpdateTripData $data, array $rawPayload): Trip
    {
        return DB::transaction(function () use ($trip, $data, $rawPayload): Trip {
            $updates = $data->toUpdatePayload($rawPayload);
            $updates['version'] = $trip->version + 1;

            $trip->update($updates);

            $refreshed = $trip->fresh();

            if ($refreshed->start_date !== null && $refreshed->end_date !== null) {
                $this->itineraryService->ensureDaysForTrip($refreshed);
            }

            if (
                $refreshed->owner !== null &&
                (
                    array_key_exists('primary_timezone', $updates) ||
                    array_key_exists('start_date', $updates) ||
                    array_key_exists('title', $updates)
                ) &&
                Reminder::query()->where('trip_id', $refreshed->id)->where('status', 'scheduled')->exists()
            ) {
                app(NotificationService::class)->scheduleTripReminders($refreshed, $refreshed->owner);
            }

            return $refreshed;
        });
    }

    /**
     * Delete an existing trip.
     */
    public function delete(Trip $trip): void
    {
        DB::transaction(function () use ($trip): void {
            Reminder::query()
                ->where('trip_id', $trip->id)
                ->where('status', 'scheduled')
                ->update(['status' => 'cancelled']);

            TripNotification::query()
                ->where('trip_id', $trip->id)
                ->whereIn('status', ['pending', 'suppressed_quiet_hours'])
                ->update(['status' => 'cancelled']);

            $trip->delete();
        });
    }

    /**
     * Compute today's dashboard summary for the given trip.
     */
    public function getTodaySummary(Trip $trip, ?CarbonImmutable $overrideNow = null, ?User $viewer = null): TodaySummaryResult
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

        // Budget pacing (exclude other travelers' private personal expenses)
        $budgetPacing = null;
        $budget = $trip->budget;
        $hasExpenses = $trip->expenses()->visibleTo($viewer)->exists();

        if ($budget !== null || $hasExpenses) {
            $currency = $budget?->currency ?? $trip->destination_currency ?? CountryCurrencyResolver::resolve($trip->destination_country ?? $trip->title);

            $spentTodayMinor = (int) $trip->expenses()
                ->visibleTo($viewer)
                ->whereDate('expense_date', $todayDate)
                ->sum('base_amount_minor');

            $totalSpentMinor = (int) $trip->expenses()
                ->visibleTo($viewer)
                ->sum('base_amount_minor');
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

        $weather = $this->weatherService->getCurrentWeather($trip);

        // Flights (ordered by earliest segment departure)
        $flights = $trip->flights()
            ->with(['segments', 'trip'])
            ->get()
            ->sortBy(fn ($flight) => $flight->segments->first()?->scheduled_departure_utc?->timestamp ?? PHP_INT_MAX)
            ->values();

        $cutoffUtc = $now->utc()->subHours(6);
        $upcomingFlight = $flights->first(function ($flight) use ($cutoffUtc): bool {
            return $flight->segments->contains(
                fn ($seg) => $seg->scheduled_departure_utc !== null && $seg->scheduled_departure_utc->greaterThanOrEqualTo($cutoffUtc)
            );
        }) ?? $flights->first();

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
            upcomingFlight: $upcomingFlight,
            flights: $flights,
        );
    }
}
