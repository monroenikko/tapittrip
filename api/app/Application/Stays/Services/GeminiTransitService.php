<?php

declare(strict_types=1);

namespace App\Application\Stays\Services;

use App\Application\Stays\Data\CompareStayTransportData;
use App\Domain\Stays\Models\Stay;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

final class GeminiTransitService
{
    /**
     * Query Google Gemini live internet AI for localized airport/terminal to stay ground transit options.
     *
     * @return array<int, array<string, mixed>>|null
     */
    public function getLiveTransportOptions(
        Stay $stay,
        CompareStayTransportData $data,
        array $transitInfo,
        string $origin,
        string $destinationCurrency,
        bool $isHeavyLuggage,
    ): ?array {
        $apiKey = (string) config('services.gemini.api_key');
        if (trim($apiKey) === '') {
            return null;
        }

        $model = (string) config('services.gemini.model', 'gemini-flash-lite-latest');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key=".urlencode($apiKey);

        $prompt = $this->buildPrompt($stay, $data, $transitInfo, $origin, $destinationCurrency, $isHeavyLuggage);

        try {
            $response = Http::timeout(12)
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
                        'temperature' => 0.2,
                    ],
                ]);

            if (! $response->successful()) {
                Log::warning('GeminiTransitService HTTP error: '.$response->status().' '.$response->body());

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

            return $this->sanitizeAndScoreOptions($decoded, $stay, $data, $transitInfo, $origin, $destinationCurrency, $isHeavyLuggage);
        } catch (\Throwable $e) {
            Log::warning('GeminiTransitService exception: '.$e->getMessage());

            return null;
        }
    }

    private function buildPrompt(
        Stay $stay,
        CompareStayTransportData $data,
        array $transitInfo,
        string $origin,
        string $destinationCurrency,
        bool $isHeavyLuggage,
    ): string {
        $stayName = $stay->name ?? 'Hotel / Accommodation';
        $stayAddress = $stay->address ?? $stayName;
        $country = $stay->trip?->destination_country ?? $stay->trip?->title ?? 'Destination';
        $strollerText = $data->stroller ? 'with stroller' : 'no stroller';

        return <<<PROMPT
You are an expert global transit intelligence engine for TapItTrip travelers.
Analyze ground transportation from origin "{$origin}" to destination stay "{$stayName}" ({$stayAddress}, {$country}).

Traveler luggage profile:
- Preset: {$data->luggagePreset}
- Party size: {$data->partySize} passenger(s)
- Checked bags: {$data->checkedBags}
- Carry-ons: {$data->carryOns}
- Stroller / baby gear: {$strollerText}
- Heavy luggage: {$isHeavyLuggage}

Expected primary currency: {$destinationCurrency}

Provide exactly 3 realistic, localized ground transport options (e.g. direct private transfer/taxi, airport express rail or metro if available, airport bus or rideshare like Grab/Uber/Bolt/local taxi).

CRITICAL GROUND-TRUTH RULES:
1. If the origin airport/hub has NO passenger rail station (e.g., Manila NAIA, Bali DPS, Phuket), do NOT invent or suggest express_rail. Propose rideshare, airport taxi, private driver, or airport express buses instead.
2. If the airport has a genuine express train or metro station (e.g., Tokyo Narita/Haneda, London Heathrow, Zurich Airport, Paris CDG, Hong Kong, Singapore Changi), DO include the real rail line and operator.
3. Use real local transport providers, operators, and app services in that country.
4. Fares must be in minor integer units of currency "{$destinationCurrency}" (e.g. JPY 2,200 is 2200; PHP 450 is 45000; USD $35 is 3500; CHF 6.90 is 690).

Return ONLY a JSON array matching this exact schema:
[
  {
    "mode": "private_transfer" | "express_rail" | "public_transit" | "rideshare",
    "title": "string (e.g. GrabCar / NAIA Airport Taxi or Keikyu Line Express)",
    "provider": "string (real company or transport authority name)",
    "estimated_duration_minutes": number,
    "estimated_cost_minor": number,
    "currency": "{$destinationCurrency}",
    "transfers": number,
    "walking_meters": number,
    "boarding_location": "string (specific terminal bay, taxi stand, or platform)",
    "dropoff_location": "string",
    "luggage_capacity": "string (how baggage fits in vehicle or train)",
    "accessibility_notes": "string (step-free / elevator / curbside notes)",
    "explanation": "string (explain why this option suits this trip and luggage profile)"
  }
]
PROMPT;
    }

    /**
     * Validate, normalize, and score options deterministically.
     *
     * @param  array<int, mixed>  $rawOptions
     * @return array<int, array<string, mixed>>
     */
    private function sanitizeAndScoreOptions(
        array $rawOptions,
        Stay $stay,
        CompareStayTransportData $data,
        array $transitInfo,
        string $origin,
        string $destinationCurrency,
        bool $isHeavyLuggage,
    ): array {
        $allowedModes = ['private_transfer', 'express_rail', 'public_transit', 'rideshare'];
        $options = [];
        $lowestCost = PHP_INT_MAX;
        $lowestDuration = PHP_INT_MAX;

        foreach ($rawOptions as $index => $item) {
            if (! is_array($item)) {
                continue;
            }

            $mode = strtolower(trim((string) ($item['mode'] ?? 'private_transfer')));
            if (! in_array($mode, $allowedModes, true)) {
                $mode = 'private_transfer';
            }

            $title = trim((string) ($item['title'] ?? 'Local Transport'));
            $provider = trim((string) ($item['provider'] ?? 'Regional Transport Operator'));
            $duration = max(5, min(360, (int) ($item['estimated_duration_minutes'] ?? 45)));
            $costMinor = max(50, (int) ($item['estimated_cost_minor'] ?? 2500));
            $currency = strtoupper(trim((string) ($item['currency'] ?? $destinationCurrency)));
            $transfers = max(0, min(5, (int) ($item['transfers'] ?? 0)));
            $walking = max(10, min(3000, (int) ($item['walking_meters'] ?? 50)));

            if ($costMinor < $lowestCost) {
                $lowestCost = $costMinor;
            }
            if ($duration < $lowestDuration) {
                $lowestDuration = $duration;
            }

            $boarding = trim((string) ($item['boarding_location'] ?? "{$origin} Terminal Curbside"));
            $dropoff = trim((string) ($item['dropoff_location'] ?? ($stay->name ?? 'Destination')));
            $luggageCap = trim((string) ($item['luggage_capacity'] ?? 'Accommodates standard luggage'));
            $accessibility = trim((string) ($item['accessibility_notes'] ?? 'Standard transit accessibility'));
            $explanation = trim((string) ($item['explanation'] ?? 'Localized ground transport advisory.'));

            // Calculate luggage-aware convenience score
            $convenience = 80;
            if ($mode === 'private_transfer' || $mode === 'rideshare') {
                $convenience = $isHeavyLuggage ? 96 : 88;
            } elseif ($mode === 'express_rail') {
                $convenience = $isHeavyLuggage ? 60 : 92;
            } elseif ($mode === 'public_transit') {
                $convenience = $isHeavyLuggage ? 45 : 75;
            }

            $options[] = [
                'id' => 'opt-live-'.($index + 1),
                'mode' => $mode,
                'title' => $title,
                'provider' => $provider,
                'estimated_duration_minutes' => $duration,
                'estimated_cost_minor' => $costMinor,
                'currency' => $currency,
                'transfers' => $transfers,
                'walking_meters' => $walking,
                'boarding_location' => $boarding,
                'dropoff_location' => $dropoff,
                'dropoff_address' => $stay->address ?? $stay->name,
                'last_mile_walk_meters' => min($walking, 400),
                'last_mile_walk_minutes' => max(1, (int) round(min($walking, 400) / 80)),
                'last_mile_directions_url' => $stay->google_maps_directions_url,
                'luggage_capacity' => $luggageCap,
                'accessibility_notes' => $accessibility,
                'convenience_score' => $convenience,
                'is_most_convenient' => false,
                'is_fastest' => false,
                'is_cheapest' => false,
                'explanation' => $explanation,
            ];
        }

        if (count($options) === 0) {
            return [];
        }

        // Rank Most Convenient, Fastest, Cheapest
        $maxConvenience = -1;
        $mostConvenientIdx = 0;
        foreach ($options as $idx => $opt) {
            if ($opt['convenience_score'] > $maxConvenience) {
                $maxConvenience = $opt['convenience_score'];
                $mostConvenientIdx = $idx;
            }
            if ($opt['estimated_cost_minor'] === $lowestCost) {
                $options[$idx]['is_cheapest'] = true;
            }
            if ($opt['estimated_duration_minutes'] === $lowestDuration) {
                $options[$idx]['is_fastest'] = true;
            }
        }

        $options[$mostConvenientIdx]['is_most_convenient'] = true;

        return $options;
    }
}
