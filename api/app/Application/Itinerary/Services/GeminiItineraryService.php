<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Services;

use App\Application\Itinerary\Data\AiActivitySuggestionData;
use App\Application\Itinerary\Data\AiDaySuggestionData;
use App\Application\Itinerary\Data\GenerateAiItineraryData;
use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

final class GeminiItineraryService
{
    /**
     * Query Google Gemini live internet AI for localized day-by-day itinerary suggestions.
     *
     * @return array<int, AiDaySuggestionData>|null
     */
    public function generatePlan(
        Trip $trip,
        GenerateAiItineraryData $data,
        string $destination,
        int $duration,
        string $currency,
        bool $isFamily,
    ): ?array {
        $apiKey = (string) config('services.gemini.api_key');
        if (trim($apiKey) === '') {
            return null;
        }

        $model = (string) config('services.gemini.model', 'gemini-flash-lite-latest');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key=".urlencode($apiKey);

        $prompt = $this->buildPrompt($trip, $data, $destination, $duration, $currency, $isFamily);

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
                        'temperature' => 0.3,
                    ],
                ]);

            if (! $response->successful()) {
                Log::warning('GeminiItineraryService HTTP error: '.$response->status().' '.$response->body());

                return null;
            }

            $rawText = (string) $response->json('candidates.0.content.parts.0.text');
            if (trim($rawText) === '') {
                return null;
            }

            $decoded = json_decode($rawText, true);
            if (! is_array($decoded) || count($decoded) === 0) {
                return null;
            }

            return $this->parseDays($decoded, $destination, $currency, $isFamily);
        } catch (\Throwable $e) {
            Log::warning('GeminiItineraryService exception: '.$e->getMessage());

            return null;
        }
    }

    private function buildPrompt(
        Trip $trip,
        GenerateAiItineraryData $data,
        string $destination,
        int $duration,
        string $currency,
        bool $isFamily,
    ): string {
        $interests = count($data->interests) > 0 ? implode(', ', $data->interests) : 'culture, local food, exploration';
        $familyContext = $isFamily ? 'Travelers include kids/seniors; choose accessible, relaxed pacing.' : 'Independent traveler/adult party.';

        return <<<PROMPT
You are a local travel expert and city concierge for TapItTrip.
Create an authentic, geographically organized {$duration}-day travel itinerary for destination "{$destination}".

Parameters:
- Duration: {$duration} day(s)
- Pace: {$data->pace}
- Party: {$data->travelParty} ({$familyContext})
- Budget tier: {$data->budgetTier}
- Key interests: {$interests}
- Currency: {$currency}

RULES:
1. Use real, existing venues, sights, markets, parks, and restaurants in "{$destination}".
2. Group each day by realistic geographic neighborhoods to minimize unnecessary travel back-and-forth.
3. Include realistic coordinates (latitude, longitude) for mapped waypoints.
4. Activity cost estimates must be realistic minor integer units of "{$currency}" (e.g. JPY 1500 = 1500, PHP 300 = 30000, USD \$15 = 1500).

Return ONLY a JSON array of days matching this schema:
[
  {
    "day_number": 1,
    "title": "Day 1: Historic Temples & Local Market Bites",
    "theme": "Historic Heart & Street Food",
    "primary_neighborhood": "string",
    "family_tip": "string (or null)",
    "activities": [
      {
        "title": "string",
        "kind": "sightseeing" | "dining" | "activity" | "nature" | "transport",
        "neighborhood": "string",
        "place_name": "string (real landmark or venue name)",
        "place_address": "string",
        "description": "string",
        "start_time": "HH:MM",
        "end_time": "HH:MM",
        "latitude": number,
        "longitude": number,
        "cost_cents": number,
        "accessibility_note": "string"
      }
    ]
  }
]
PROMPT;
    }

    /**
     * @param  array<int, mixed>  $rawDays
     * @return array<int, AiDaySuggestionData>
     */
    private function parseDays(
        array $rawDays,
        string $destination,
        string $currency,
        bool $isFamily,
    ): array {
        $allowedKinds = ['sightseeing', 'dining', 'activity', 'nature', 'transport'];
        $days = [];

        foreach ($rawDays as $dIdx => $dayItem) {
            if (! is_array($dayItem)) {
                continue;
            }

            $dayNum = (int) ($dayItem['day_number'] ?? ($dIdx + 1));
            $theme = trim((string) ($dayItem['theme'] ?? "Day {$dayNum}"));
            $title = trim((string) ($dayItem['title'] ?? "Day {$dayNum}: {$theme}"));
            $primaryNeighborhood = trim((string) ($dayItem['primary_neighborhood'] ?? $destination));
            $familyTip = isset($dayItem['family_tip']) ? trim((string) $dayItem['family_tip']) : ($isFamily ? 'Step-free transit available.' : null);

            $rawActivities = $dayItem['activities'] ?? [];
            if (! is_array($rawActivities) || count($rawActivities) === 0) {
                continue;
            }

            $activities = [];
            $dailyTotal = 0;

            foreach ($rawActivities as $actItem) {
                if (! is_array($actItem)) {
                    continue;
                }

                $actTitle = trim((string) ($actItem['title'] ?? 'Activity'));
                $kind = strtolower(trim((string) ($actItem['kind'] ?? 'sightseeing')));
                if (! in_array($kind, $allowedKinds, true)) {
                    $kind = 'sightseeing';
                }

                $neighborhood = trim((string) ($actItem['neighborhood'] ?? $primaryNeighborhood));
                $placeName = trim((string) ($actItem['place_name'] ?? $actTitle));
                $placeAddress = trim((string) ($actItem['place_address'] ?? "{$placeName}, {$neighborhood}, {$destination}"));
                $description = trim((string) ($actItem['description'] ?? ''));
                $startTime = (string) ($actItem['start_time'] ?? '10:00');
                $endTime = (string) ($actItem['end_time'] ?? '12:00');
                $lat = isset($actItem['latitude']) && is_numeric($actItem['latitude']) ? (float) $actItem['latitude'] : null;
                $lng = isset($actItem['longitude']) && is_numeric($actItem['longitude']) ? (float) $actItem['longitude'] : null;
                $costMinor = max(0, (int) ($actItem['cost_cents'] ?? 0));
                $dailyTotal += $costMinor;
                $accessNote = trim((string) ($actItem['accessibility_note'] ?? 'Accessible pedestrian routes.'));

                $activities[] = new AiActivitySuggestionData(
                    title: $actTitle,
                    kind: $kind,
                    neighborhood: $neighborhood,
                    description: $description,
                    plannedStartTime: $startTime,
                    plannedEndTime: $endTime,
                    placeName: $placeName,
                    placeAddress: $placeAddress,
                    latitude: $lat,
                    longitude: $lng,
                    costEstimate: [
                        'amount_cents' => $costMinor,
                        'currency' => $currency,
                    ],
                    accessibilityNote: $accessNote,
                );
            }

            if (count($activities) > 0) {
                $days[] = new AiDaySuggestionData(
                    dayNumber: $dayNum,
                    title: $title,
                    theme: $theme,
                    primaryNeighborhood: $primaryNeighborhood,
                    activities: $activities,
                    budgetEstimate: [
                        'amount_cents' => $dailyTotal,
                        'currency' => $currency,
                    ],
                    familyTip: $familyTip,
                );
            }
        }

        return $days;
    }
}
