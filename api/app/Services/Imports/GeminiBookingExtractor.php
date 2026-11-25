<?php

declare(strict_types=1);

namespace App\Services\Imports;

use App\Contracts\BookingExtractorInterface;
use App\DTOs\Imports\ExtractedBookingData;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

final class GeminiBookingExtractor implements BookingExtractorInterface
{
    public function __construct(
        private readonly FakeBookingExtractor $fallbackExtractor,
    ) {}

    public function extract(string $text, ?string $hintType = null): ?ExtractedBookingData
    {
        $apiKey = (string) config('services.gemini.api_key');
        if (trim($apiKey) === '') {
            return $this->fallbackExtractor->extract($text, $hintType);
        }

        $model = (string) config('services.gemini.model', 'gemini-flash-lite-latest');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key=".urlencode($apiKey);

        $prompt = <<<PROMPT
You are a travel booking confirmation extractor. Parse the given travel booking text and return a JSON object strictly adhering to this schema:
{
  "booking_type": "flight" | "stay" | "activity",
  "confidence": number (between 0.0 and 1.0),
  "summary": string,
  "flight": {
    "airline": string | null,
    "booking_reference": string | null,
    "segments": [
      {
        "flight_number": string,
        "origin_airport": string (3-letter IATA),
        "destination_airport": string (3-letter IATA),
        "scheduled_departure_utc": string (ISO 8601 UTC),
        "scheduled_arrival_utc": string (ISO 8601 UTC),
        "origin_timezone": string (IANA, e.g. "Asia/Manila"),
        "destination_timezone": string (IANA, e.g. "Asia/Tokyo"),
        "terminal": string | null,
        "gate": string | null
      }
    ]
  } | null,
  "stay": {
    "name": string,
    "stay_type": "hotel" | "hostel" | "rental" | "resort" | "other",
    "address": string | null,
    "check_in_at": string | null (ISO 8601 UTC),
    "check_out_at": string | null (ISO 8601 UTC),
    "timezone": string (IANA, e.g. "Asia/Tokyo"),
    "phone": string | null,
    "booking_reference": string | null,
    "notes": string | null
  } | null,
  "activity": {
    "title": string,
    "kind": "attraction" | "meal" | "transport" | "custom",
    "place_name": string | null,
    "starts_at_utc": string | null (ISO 8601 UTC),
    "ends_at_utc": string | null (ISO 8601 UTC),
    "timezone": string (IANA),
    "notes": string | null
  } | null
}

Do NOT invent or fabricate missing booking references, flight numbers, or dates. Leave null if not present in the text.
Hint type: {$hintType}

Booking text to extract:
{$text}
PROMPT;

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
                        'temperature' => 0.1,
                    ],
                ]);

            if (! $response->successful()) {
                Log::warning('GeminiBookingExtractor HTTP error', ['status' => $response->status()]);

                return $this->fallbackExtractor->extract($text, $hintType);
            }

            $raw = (string) $response->json('candidates.0.content.parts.0.text');
            if (trim($raw) === '') {
                return $this->fallbackExtractor->extract($text, $hintType);
            }

            $parsed = json_decode($raw, true);
            if (! is_array($parsed) || ! isset($parsed['booking_type'])) {
                return $this->fallbackExtractor->extract($text, $hintType);
            }

            return ExtractedBookingData::fromArray($parsed);
        } catch (\Throwable) {
            Log::warning('GeminiBookingExtractor request failed');

            return $this->fallbackExtractor->extract($text, $hintType);
        }
    }
}
