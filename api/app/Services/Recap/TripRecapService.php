<?php

declare(strict_types=1);

namespace App\Services\Recap;

use App\DTOs\Recap\TripRecapData;
use App\Models\JournalEntry;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\User;
use App\Services\Expenses\CountryCurrencyResolver;
use App\Services\Expenses\ExpenseService;
use Illuminate\Auth\Access\AuthorizationException;

final class TripRecapService
{
    public function __construct(
        private readonly ExpenseService $expenseService,
    ) {}

    /**
     * Aggregate the trip highlights, photo story album, and expense recap for an authorized traveler.
     *
     * @throws AuthorizationException
     */
    public function getRecap(Trip $trip, User $user): TripRecapData
    {
        if (! $trip->hasMember($user->id) && $trip->owner_id !== $user->id) {
            throw new AuthorizationException('You are not authorized to view this trip recap.');
        }

        // 1. Trip Metadata
        $durationDays = null;
        if ($trip->start_date !== null && $trip->end_date !== null) {
            $durationDays = max(1, (int) $trip->start_date->diffInDays($trip->end_date) + 1);
        } else {
            $dayCount = $trip->days()->count();
            if ($dayCount > 0) {
                $durationDays = $dayCount;
            }
        }

        $tripMeta = [
            'id' => (string) $trip->id,
            'title' => (string) $trip->title,
            'destination' => (string) ($trip->destination_country ?? $trip->title),
            'start_date' => $trip->start_date?->toDateString(),
            'end_date' => $trip->end_date?->toDateString(),
            'duration_days' => $durationDays,
            'status' => (string) $trip->status,
        ];

        // 2. Highlights
        $totalVisited = $trip->itineraryItems()->where('status', 'visited')->count();
        $totalPlanned = $trip->itineraryItems()->count();
        $completionRate = $totalPlanned > 0
            ? (int) round(($totalVisited / $totalPlanned) * 100)
            : 0;

        $stays = $trip->stays()->get();
        $totalNights = 0;
        foreach ($stays as $stay) {
            /** @var Stay $stay */
            if ($stay->check_in_at !== null && $stay->check_out_at !== null) {
                $in = $stay->check_in_at->copy()->startOfDay();
                $out = $stay->check_out_at->copy()->startOfDay();
                if ($out->greaterThan($in)) {
                    $totalNights += (int) $in->diffInDays($out);
                } else {
                    $totalNights += 1;
                }
            } elseif ($stay->check_in_at !== null) {
                $totalNights += 1;
            }
        }

        $memberCount = $trip->members()->where('invitation_status', 'accepted')->count();
        $totalCompanions = max(1, $memberCount);

        $highlights = [
            'total_places_visited' => $totalVisited,
            'total_places_planned' => $totalPlanned,
            'completion_rate_percentage' => $completionRate,
            'total_stays' => $stays->count(),
            'total_nights' => $totalNights,
            'total_companions' => $totalCompanions,
        ];

        // 3. Story Album (Only accessible entries: own entries + shared circle reflections, TC-8.1)
        $accessibleEntries = JournalEntry::query()
            ->where('trip_id', $trip->id)
            ->where(function ($q) use ($user): void {
                $q->where('user_id', $user->id)
                    ->orWhere('is_shared', true);
            })
            ->with(['author'])
            ->orderBy('entry_date', 'asc')
            ->orderBy('created_at', 'asc')
            ->get();

        $photos = [];
        $moments = [];
        $moodBreakdown = [];

        foreach ($accessibleEntries as $entry) {
            $authorName = (string) ($entry->author?->display_name ?? $entry->author?->name ?? 'Traveler');

            if (! empty($entry->photos) && is_array($entry->photos)) {
                foreach ($entry->photos as $photoUrl) {
                    $photos[] = [
                        'url' => (string) $photoUrl,
                        'caption' => (string) $entry->title,
                        'date' => $entry->entry_date?->toDateString(),
                        'author_name' => $authorName,
                        'mood' => $entry->mood,
                        'location_name' => $entry->location_name,
                    ];
                }
            }

            $moments[] = [
                'id' => (string) $entry->id,
                'title' => (string) $entry->title,
                'content' => (string) $entry->content,
                'author_name' => $authorName,
                'author_avatar_url' => $entry->author?->avatar_url,
                'entry_date' => $entry->entry_date?->toDateString(),
                'mood' => $entry->mood,
                'mood_emoji' => self::resolveMoodEmoji($entry->mood),
                'weather' => $entry->weather,
                'location_name' => $entry->location_name,
                'cover_photo' => ! empty($entry->photos) && is_array($entry->photos) ? (string) $entry->photos[0] : null,
                'is_shared' => (bool) $entry->is_shared,
            ];

            if ($entry->mood !== null && trim($entry->mood) !== '') {
                $moodKey = strtolower(trim($entry->mood));
                $moodBreakdown[$moodKey] = ($moodBreakdown[$moodKey] ?? 0) + 1;
            }
        }

        arsort($moodBreakdown);
        $topMood = ! empty($moodBreakdown) ? (string) array_key_first($moodBreakdown) : null;

        $storyAlbum = [
            'total_photos' => count($photos),
            'photos' => $photos,
            'moments' => $moments,
            'mood_breakdown' => $moodBreakdown,
            'top_mood' => $topMood,
        ];

        // 4. Expense Summary
        $expenseResult = $this->expenseService->getExpensesSummary($trip, $user);
        $topCategory = null;
        if (! empty($expenseResult->categoryBreakdown)) {
            $sortedCategories = $expenseResult->categoryBreakdown;
            usort($sortedCategories, fn ($a, $b) => $b['amount_minor'] <=> $a['amount_minor']);
            $topCategory = $sortedCategories[0]['category'] ?? null;
        }

        $expenseSummary = [
            'currency' => $expenseResult->baseCurrency,
            'total_spent_minor' => $expenseResult->totalSpentBaseMinor,
            'formatted_total_spent' => self::formatMoney($expenseResult->totalSpentBaseMinor, $expenseResult->baseCurrency),
            'expenses_count' => $expenseResult->expensesCount,
            'top_category' => $topCategory,
            'has_budget' => $expenseResult->totalBudgetMinor !== null,
            'budget_utilization_percent' => $expenseResult->budgetUtilizationPercent,
        ];

        return new TripRecapData(
            trip: $tripMeta,
            highlights: $highlights,
            storyAlbum: $storyAlbum,
            expenseSummary: $expenseSummary,
        );
    }

    /**
     * Resolve emoji for a given mood identifier.
     */
    public static function resolveMoodEmoji(?string $mood): ?string
    {
        if ($mood === null || trim($mood) === '') {
            return null;
        }

        return match (strtolower(trim($mood))) {
            'amazed' => '🤩',
            'happy' => '😊',
            'peaceful' => '😌',
            'excited' => '🎉',
            'tired' => '😴',
            'grateful' => '🙏',
            'adventurous' => '🏔️',
            default => '✨',
        };
    }

    /**
     * Format a monetary amount in minor units with appropriate currency symbol.
     */
    public static function formatMoney(int $amountMinor, string $currency): string
    {
        $currUpper = strtoupper(trim($currency));
        $isZeroDecimal = CountryCurrencyResolver::isZeroDecimal($currUpper);

        $symbols = [
            'USD' => '$',
            'PHP' => '₱',
            'JPY' => '¥',
            'EUR' => '€',
            'GBP' => '£',
            'KRW' => '₩',
            'SGD' => 'S$',
            'HKD' => 'HK$',
            'AUD' => 'A$',
            'CAD' => 'CA$',
            'CHF' => 'CHF ',
        ];

        $sym = $symbols[$currUpper] ?? ($currUpper.' ');

        if ($isZeroDecimal) {
            return $sym.number_format($amountMinor);
        }

        return $sym.number_format($amountMinor / 100, 2);
    }
}
