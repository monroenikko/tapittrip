<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Services;

use App\Application\Itinerary\Data\TripAssistantResult;
use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

final class GeminiAssistantService
{
    /**
     * Query Google Gemini live internet AI for contextual travel assistant guidance.
     */
    public function ask(
        Trip $trip,
        string $query,
        array $contextSummary = [],
    ): ?TripAssistantResult {
        $apiKey = (string) config('services.gemini.api_key');
        if (trim($apiKey) === '') {
            return null;
        }

        $model = (string) config('services.gemini.model', 'gemini-flash-lite-latest');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key=".urlencode($apiKey);

        $prompt = $this->buildPrompt($trip, $query, $contextSummary);

        try {
            $response = Http::timeout(15)
                ->retry(2, 100)
                ->post($url, [
                    'contents' => [
                        [
                            'parts' => [
                                ['text' => $prompt],
                            ],
                        ],
                    ],
                    'generationConfig' => [
                        'responseMimeType' => 'application/json',
                        'temperature' => 0.4,
                    ],
                ]);

            if (! $response->successful()) {
                Log::warning('GeminiAssistantService HTTP error: '.$response->status().' '.$response->body());

                return null;
            }

            $rawText = (string) $response->json('candidates.0.content.parts.0.text');
            if (trim($rawText) === '') {
                return null;
            }

            $decoded = json_decode($rawText, true);
            if (! is_array($decoded) || ! isset($decoded['reply'])) {
                return null;
            }

            return $this->parseResponse($decoded, $contextSummary);
        } catch (\Throwable $e) {
            Log::warning('GeminiAssistantService exception: '.$e->getMessage());

            return null;
        }
    }

    /**
     * @param  array<string, mixed>  $contextSummary
     */
    private function buildPrompt(Trip $trip, string $query, array $contextSummary): string
    {
        $destination = $trip->destination_country ? "{$trip->title} ({$trip->destination_country})" : $trip->title;
        $stay = $trip->stays()->first();
        $stayInfo = $stay ? "{$stay->name} at {$stay->address}" : 'None added yet';
        $dates = ($trip->start_date && $trip->end_date)
            ? "From {$trip->start_date->toDateString()} to {$trip->end_date->toDateString()}"
            : 'Dates flexible';
        $style = $trip->trip_type ?? 'leisure';

        $plannedItems = $trip->itineraryItems()->take(6)->pluck('title')->all();
        $itinerarySummary = count($plannedItems) > 0 ? implode(', ', $plannedItems) : 'None planned yet';

        return <<<PROMPT
You are "TapItTrip Assistant", an expert AI travel concierge and companion dedicated exclusively to helping travelers plan, navigate, and enjoy their trips.

TRIP CONTEXT:
- Destination: {$destination}
- Travel Dates: {$dates}
- Trip Style: {$style}
- Accommodation: {$stayInfo}
- Currently Planned Stops: {$itinerarySummary}

TRAVELER INQUIRY:
"{$query}"

STRICT BEHAVIOR & SCOPE RULES:
1. TRAVEL SCOPE ONLY:
   You ONLY assist with travel-related topics:
   - Trip planning, itineraries, pacing, and scheduling
   - Packing lists, climate, seasonal advice, and gear
   - Local dining, cafes, specialties, and street food
   - Sights, attractions, neighborhood walks, and hidden gems
   - Local etiquette, tipping customs, payment culture (cash vs card/transit IC cards)
   - Ground transit, airport navigation, train/bus directions, and rideshares
   - Traveler safety, emergency phrases, and cultural norms
   - Family, kid, or mobility-friendly adjustments

2. STRICT OUT-OF-SCOPE GUARDRAIL:
   If the traveler's inquiry is NOT related to travel (for example: programming/software coding, academic homework, unrelated math, stock market trading, general political debates, sports news, non-travel medical diagnosis):
   - You MUST politely decline and steer them back to their trip.
   - Example polite decline: "I am your TapItTrip travel companion, focused exclusively on travel advice, trip planning, local recommendations, and journey logistics. How can I help with your trip to {$trip->title}?"
   - In this case, set "category" to "out_of_scope" and "suggested_actions" to [].

3. FOCUS ON PRACTICAL SUGGESTIONS:
   - Provide concrete, actionable suggestions rather than vague generalities.
   - Use clean Markdown with bold headings and bullet points for readability.
   - Be concise, friendly, and culturally authentic.

4. ACTIONABLE SUGGESTIONS (suggested_actions):
   If you recommend 1 or 2 specific places, restaurants, or activities that the traveler could add as a stop in their itinerary, include them in "suggested_actions".
   Each item MUST have:
   - "label": e.g. "Add [Name] to Itinerary"
   - "kind": "add_activity"
   - "payload":
     - "title": Clean concise activity title (max 60 chars)
     - "kind": Valid canonical category: one of ["attraction", "meal", "transport", "hotel"]
     - "place_name": Name of the venue or location
     - "notes": Brief tip (e.g. "Best enjoyed at sunset", "Requires cash only")
   If no specific activity stop makes sense, provide an empty array [].

OUTPUT FORMAT:
Return pure valid JSON matching this schema:
{
  "reply": "string (Markdown formatted answer with travel recommendations or polite out-of-scope redirection)",
  "category": "dining" | "culture" | "transit" | "packing" | "itinerary" | "weather" | "safety" | "lounge" | "general" | "out_of_scope",
  "suggested_actions": [
    {
      "label": "Add [Name] to Itinerary",
      "kind": "add_activity",
      "payload": {
        "title": "Visit Meiji Shrine",
        "kind": "attraction",
        "place_name": "Meiji Jingu",
        "notes": "Serene forest shrine"
      }
    }
  ]
}
PROMPT;
    }

    /**
     * @param  array<string, mixed>  $decoded
     * @param  array<string, mixed>  $contextSummary
     */
    private function parseResponse(array $decoded, array $contextSummary): TripAssistantResult
    {
        $reply = trim((string) ($decoded['reply'] ?? ''));
        $category = strtolower(trim((string) ($decoded['category'] ?? 'general')));

        $allowedCategories = [
            'dining', 'culture', 'transit', 'packing', 'itinerary',
            'weather', 'safety', 'lounge', 'toddler_friendly', 'general', 'out_of_scope',
        ];

        if (! in_array($category, $allowedCategories, true)) {
            $category = 'general';
        }

        $actions = [];
        if (isset($decoded['suggested_actions']) && is_array($decoded['suggested_actions'])) {
            foreach ($decoded['suggested_actions'] as $rawAction) {
                if (! is_array($rawAction)) {
                    continue;
                }

                $label = trim((string) ($rawAction['label'] ?? ''));
                $actionKind = trim((string) ($rawAction['kind'] ?? 'add_activity'));
                $payload = is_array($rawAction['payload'] ?? null) ? $rawAction['payload'] : [];

                if ($label === '') {
                    continue;
                }

                // Normalize kind in payload if add_activity
                if ($actionKind === 'add_activity') {
                    $rawKind = strtolower(trim((string) ($payload['kind'] ?? 'attraction')));
                    $normalizedKind = match ($rawKind) {
                        'dining', 'food', 'restaurant', 'cafe', 'bar' => 'meal',
                        'transit', 'train', 'bus', 'taxi', 'rideshare' => 'transport',
                        'stay', 'hotel', 'resort', 'accommodation' => 'hotel',
                        default => 'attraction',
                    };
                    $payload['kind'] = $normalizedKind;

                    if (empty($payload['title'])) {
                        $payload['title'] = $label;
                    }
                }

                $actions[] = [
                    'label' => $label,
                    'kind' => $actionKind,
                    'payload' => $payload,
                ];
            }
        }

        return new TripAssistantResult(
            reply: $reply,
            category: $category,
            contextSummary: $contextSummary,
            suggestedActions: $actions,
        );
    }
}
