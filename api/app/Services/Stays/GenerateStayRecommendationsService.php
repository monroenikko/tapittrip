<?php

declare(strict_types=1);

namespace App\Services\Stays;

use App\Contracts\StayRecommendationProvider;
use App\DTOs\Itinerary\TripAssistantResult;
use App\Models\Trip;

final class GenerateStayRecommendationsService
{
    public function __construct(private readonly StayRecommendationProvider $provider) {}

    public function execute(Trip $trip): TripAssistantResult
    {
        if ($trip->stays()->exists()) {
            return $this->result($trip, 'stay_exists');
        }

        $suggestions = $this->provider->recommend($trip);

        // A stay may have been saved while the provider request was running.
        if ($trip->stays()->exists()) {
            return $this->result($trip, 'stay_exists');
        }
        if ($suggestions === null) {
            return $this->result($trip, 'unavailable');
        }

        $actions = [];
        $seen = [];
        foreach ($suggestions->suggestedActions as $action) {
            $payload = $action['payload'] ?? null;
            if (($action['kind'] ?? null) !== 'add_activity' || ! is_array($payload) || ($payload['kind'] ?? null) !== 'hotel') {
                continue;
            }
            $title = $this->text($payload['title'] ?? null, 255);
            $place = $this->text($payload['place_name'] ?? null, 255);
            $key = mb_strtolower($place !== '' ? $place : $title);
            if ($title === '' || isset($seen[$key])) {
                continue;
            }
            $seen[$key] = true;
            $actions[] = [
                'label' => $title,
                'kind' => 'add_activity',
                'payload' => [
                    'title' => $title,
                    'kind' => 'hotel',
                    'place_name' => $place !== '' ? $place : $title,
                    'notes' => $this->text($payload['notes'] ?? null, 1000),
                ],
            ];
            if (count($actions) === 3) {
                break;
            }
        }

        return $this->result($trip, 'ready', $this->text($suggestions->reply, 6000), $actions);
    }

    private function text(mixed $value, int $limit): string
    {
        return is_string($value) ? mb_substr(trim(strip_tags($value)), 0, $limit) : '';
    }

    /** @param list<array<string, mixed>> $actions */
    private function result(Trip $trip, string $status, string $reply = '', array $actions = []): TripAssistantResult
    {
        return new TripAssistantResult(
            reply: $reply,
            category: 'general',
            contextSummary: [
                'trip_id' => $trip->id,
                'destination' => trim($trip->title.' '.($trip->destination_country ?? '')),
                'source' => $status === 'ready' ? 'gemini' : 'local_fallback',
                'status' => $status,
                'has_stay' => $status === 'stay_exists',
                'verified' => false,
            ],
            suggestedActions: $actions,
        );
    }
}
