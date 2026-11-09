<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Services;

use App\Application\Itinerary\Data\TripAssistantResult;
use App\Domain\Lounges\Models\AirportLounge;
use App\Domain\Trips\Models\Trip;

final class AskTapItTripService
{
    public function __construct(
        private readonly GeminiAssistantService $geminiService,
    ) {}

    /**
     * Ask TapItTrip contextual assistant about an active trip.
     */
    public function ask(
        Trip $trip,
        string $query,
        ?string $contextDate = null,
        ?string $terminalCode = null,
    ): TripAssistantResult {
        $normalizedQuery = mb_strtolower(trim($query));
        $stay = $trip->stays()->first();
        $daysCount = $trip->days()->count();
        $destination = $trip->destination_country ? "{$trip->title} ({$trip->destination_country})" : $trip->title;

        // Context summary for caller
        $contextSummary = [
            'trip_id' => $trip->id,
            'destination' => $destination,
            'has_stay' => $stay !== null,
            'stay_name' => $stay?->name,
            'context_date' => $contextDate,
            'days_count' => $daysCount,
        ];

        // 1. Live Google Gemini AI Assistant with Travel Scoping & Suggestions
        $aiResult = $this->geminiService->ask($trip, $query, $contextSummary);
        if ($aiResult !== null) {
            return $aiResult;
        }

        // 2. Offline / Local Heuristic Fallback
        // Airport Lounge / Terminal query
        if (
            str_contains($normalizedQuery, 'lounge') ||
            str_contains($normalizedQuery, 'terminal') ||
            str_contains($normalizedQuery, 'airport') ||
            str_contains($normalizedQuery, 'priority pass')
        ) {
            return $this->handleLoungeQuery($trip, $normalizedQuery, $terminalCode, $contextSummary);
        }

        // Toddler / Family / Pacing query
        if (
            str_contains($normalizedQuery, 'toddler') ||
            str_contains($normalizedQuery, 'kid') ||
            str_contains($normalizedQuery, 'child') ||
            str_contains($normalizedQuery, 'baby') ||
            str_contains($normalizedQuery, 'stroller') ||
            str_contains($normalizedQuery, 'easier') ||
            str_contains($normalizedQuery, 'slow') ||
            str_contains($normalizedQuery, 'rest')
        ) {
            return $this->handleToddlerAndPacingQuery($trip, $normalizedQuery, $contextSummary);
        }

        // Hotel / Accommodation proximity / Dining
        if (
            str_contains($normalizedQuery, 'hotel') ||
            str_contains($normalizedQuery, 'stay') ||
            str_contains($normalizedQuery, 'near') ||
            str_contains($normalizedQuery, 'eat') ||
            str_contains($normalizedQuery, 'dinner') ||
            str_contains($normalizedQuery, 'breakfast') ||
            str_contains($normalizedQuery, 'lunch') ||
            str_contains($normalizedQuery, 'restaurant') ||
            str_contains($normalizedQuery, 'food')
        ) {
            return $this->handleStayAndDiningQuery($trip, $stay, $contextSummary);
        }

        // Weather / Rain query
        if (
            str_contains($normalizedQuery, 'rain') ||
            str_contains($normalizedQuery, 'weather') ||
            str_contains($normalizedQuery, 'storm') ||
            str_contains($normalizedQuery, 'indoor') ||
            str_contains($normalizedQuery, 'umbrella')
        ) {
            return $this->handleWeatherQuery($trip, $contextSummary);
        }

        // General contextual fallback
        return $this->handleGeneralQuery($trip, $contextSummary);
    }

    /**
     * @param  array<string, mixed>  $contextSummary
     */
    private function handleLoungeQuery(
        Trip $trip,
        string $query,
        ?string $terminalCode,
        array $contextSummary,
    ): TripAssistantResult {
        // Detect terminal from query if not explicitly passed
        $detectedTerminal = $terminalCode;
        if (! $detectedTerminal) {
            if (preg_match('/terminal\s*(\d+|[a-z0-9]+)/i', $query, $matches)) {
                $detectedTerminal = 'T'.strtoupper($matches[1]);
            } elseif (preg_match('/\b(t\d+)\b/i', $query, $matches)) {
                $detectedTerminal = strtoupper($matches[1]);
            }
        }

        $contextSummary['detected_terminal'] = $detectedTerminal;

        // Query database for airport lounges matching terminal
        $loungesQuery = AirportLounge::query()->with(['terminal', 'airport']);
        if ($detectedTerminal) {
            $code = ltrim($detectedTerminal, 'Tt');
            $loungesQuery->whereHas('terminal', function ($q) use ($code, $detectedTerminal) {
                $q->where('code', $detectedTerminal)
                    ->orWhere('code', 'T'.$code)
                    ->orWhere('name', 'like', "%Terminal {$code}%");
            });
        }

        $lounges = $loungesQuery->take(3)->get();

        if ($lounges->isNotEmpty()) {
            $loungeLines = [];
            foreach ($lounges as $lounge) {
                $zone = $lounge->is_airside ? 'Airside (After security)' : 'Landside (Before security)';
                $access = is_array($lounge->access_methods) ? implode(', ', $lounge->access_methods) : 'Pass / Airline Status';
                $loungeLines[] = "• **{$lounge->name}** ({$zone})\n  Operator: {$lounge->operator}\n  Access: {$access}\n  Location: {$lounge->location_description}";
            }

            $listStr = implode("\n\n", $loungeLines);
            $reply = "Here are accessible lounges in {$detectedTerminal} for your trip:\n\n{$listStr}\n\n⚠️ **Gate Reminder**: Lounges are often 10–20 minutes away from departure gates. Allow at least 25 minutes to clear boarding security and reach your gate on time.";

            return new TripAssistantResult(
                reply: $reply,
                category: 'lounge',
                contextSummary: $contextSummary,
                suggestedActions: [
                    [
                        'label' => 'Open Lounge Finder',
                        'kind' => 'navigate_lounge_finder',
                        'payload' => ['terminal' => $detectedTerminal],
                    ],
                ],
            );
        }

        $termStr = $detectedTerminal ? "in {$detectedTerminal}" : 'at the airport';
        $reply = "For lounges {$termStr}, options typically include airline alliance business lounges and independent network lounges (such as Priority Pass, LoungeKey, and DragonPass). Most are located airside after international security.\n\n⚠️ **Gate Reminder**: Allow at least 30 minutes before boarding to leave the lounge and walk to your departure gate.";

        return new TripAssistantResult(
            reply: $reply,
            category: 'lounge',
            contextSummary: $contextSummary,
            suggestedActions: [
                [
                    'label' => 'Browse Airport Lounges',
                    'kind' => 'navigate_lounge_finder',
                    'payload' => ['terminal' => $detectedTerminal],
                ],
            ],
        );
    }

    /**
     * @param  array<string, mixed>  $contextSummary
     */
    private function handleToddlerAndPacingQuery(Trip $trip, string $query, array $contextSummary): TripAssistantResult
    {
        $reply = "Here is how to make your trip much easier and more enjoyable with a toddler or young children:\n\n"
            ."1. **Midday Nap / Quiet Buffer**: Keep 1:30 PM – 3:30 PM open for hotel rest or quiet stroller nap in a nearby shaded park.\n"
            ."2. **Transit Pacing**: Limit consecutive walking to 15–20 minutes and avoid rush-hour transit (7:30–9:00 AM and 5:30–7:00 PM).\n"
            ."3. **Stroller & Elevator Awareness**: Major metro stations have dedicated elevator exits—look for the yellow stroller symbols on platform signage.\n"
            .'4. **Kid-Friendly Pit Stops**: We recommend interspersing cultural sites with open grassy parks or hands-on play spaces.';

        return new TripAssistantResult(
            reply: $reply,
            category: 'toddler_friendly',
            contextSummary: $contextSummary,
            suggestedActions: [
                [
                    'label' => 'Add 2-Hour Rest Buffer',
                    'kind' => 'add_activity',
                    'payload' => [
                        'title' => 'Afternoon Rest & Toddler Recharge',
                        'kind' => 'attraction',
                        'notes' => 'Quiet buffer at hotel or shaded park.',
                    ],
                ],
            ],
        );
    }

    /**
     * @param  array<string, mixed>  $contextSummary
     */
    private function handleStayAndDiningQuery(Trip $trip, mixed $stay, array $contextSummary): TripAssistantResult
    {
        if ($stay) {
            $stayName = $stay->name;
            $address = $stay->address ?? 'your hotel location';
            $reply = "Since you're staying at **{$stayName}** ({$address}), here are curated dining suggestions within a 5–10 minute stroll:\n\n"
                ."• **Morning Bakery / Cafe**: Local artisanal roasters with fresh pastries and espresso for a quick start.\n"
                ."• **Casual Neighborhood Lunch**: Authentic neighborhood noodle or bistro spot with fast seating and vegetarian options.\n"
                ."• **Relaxed Dinner**: Quiet local eatery with family-friendly booths, welcoming staff, and English photo menus.\n\n"
                .'💡 *Tip*: Stays often have convenience stores and 24h pharmacies within 2 blocks for emergency snacks and water.';

            return new TripAssistantResult(
                reply: $reply,
                category: 'dining',
                contextSummary: $contextSummary,
                suggestedActions: [
                    [
                        'label' => "Add Dinner near {$stayName}",
                        'kind' => 'add_activity',
                        'payload' => [
                            'title' => "Dinner near {$stayName}",
                            'kind' => 'meal',
                            'place_name' => "Local Restaurant near {$stayName}",
                            'place_address' => $address,
                        ],
                    ],
                ],
            );
        }

        $reply = "You don't have an accommodation saved yet for **{$trip->title}**. "
            ."Once you add your hotel or apartment under the Stays tab, TapItTrip will automatically recommend top-rated dining spots, cafes, and bakeries within walking distance!\n\n"
            .'In the meantime, central neighborhoods typically have a wide variety of casual bistros and food markets.';

        return new TripAssistantResult(
            reply: $reply,
            category: 'dining',
            contextSummary: $contextSummary,
            suggestedActions: [
                [
                    'label' => 'Add Accommodation',
                    'kind' => 'navigate_stays',
                    'payload' => [],
                ],
            ],
        );
    }

    /**
     * @param  array<string, mixed>  $contextSummary
     */
    private function handleWeatherQuery(Trip $trip, array $contextSummary): TripAssistantResult
    {
        $destination = $trip->title;
        $reply = "If rain or stormy weather is forecast during your trip to **{$destination}**, here are recommended all-weather indoor alternatives:\n\n"
            ."• **Covered Shopping Arcades & Food Halls**: Walk, shop, and sample local street food completely sheltered from the elements.\n"
            ."• **Interactive Museums & Art Galleries**: Immersive digital art installations or science centers with coat-check and stroller parking.\n"
            ."• **Public Aquariums & Observation Decks**: High-rise glass observatories or marine exhibits with indoor cafes.\n\n"
            .'💡 *Tip*: Most convenience stores sell durable clear vinyl umbrellas for under $5.';

        return new TripAssistantResult(
            reply: $reply,
            category: 'weather',
            contextSummary: $contextSummary,
            suggestedActions: [
                [
                    'label' => 'Plan Indoor Activity',
                    'kind' => 'add_activity',
                    'payload' => [
                        'title' => 'Indoor Cultural Experience & Food Hall',
                        'kind' => 'attraction',
                        'notes' => 'Rainy-day backup stop.',
                    ],
                ],
            ],
        );
    }

    /**
     * @param  array<string, mixed>  $contextSummary
     */
    private function handleGeneralQuery(Trip $trip, array $contextSummary): TripAssistantResult
    {
        $destination = $trip->title;
        $reply = "TapItTrip is ready to assist with your trip to **{$destination}**! "
            ."You can ask about:\n\n"
            ."• **Dining near your stay**: \"Where can we eat near our hotel?\"\n"
            ."• **Airport lounges**: \"Which lounge can I use in Terminal 3?\"\n"
            ."• **Family & toddler adjustments**: \"Can you make Day 2 easier for our toddler?\"\n"
            ."• **Weather planning**: \"What should we do if it rains?\"\n\n"
            .'All suggestions are advisory—you stay in full control of your itinerary.';

        return new TripAssistantResult(
            reply: $reply,
            category: 'general',
            contextSummary: $contextSummary,
            suggestedActions: [],
        );
    }
}
