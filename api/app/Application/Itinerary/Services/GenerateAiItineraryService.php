<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Services;

use App\Application\Itinerary\Data\AiActivitySuggestionData;
use App\Application\Itinerary\Data\AiDaySuggestionData;
use App\Application\Itinerary\Data\AiItineraryPlanResult;
use App\Application\Itinerary\Data\GenerateAiItineraryData;
use App\Domain\Trips\Models\Trip;

final class GenerateAiItineraryService
{
    public function __construct(
        private ?GeminiItineraryService $geminiItineraryService = null,
    ) {
        $this->geminiItineraryService = $geminiItineraryService ?? new GeminiItineraryService;
    }

    public function execute(Trip $trip, GenerateAiItineraryData $data): AiItineraryPlanResult
    {
        $destination = $data->destination !== '' ? $data->destination : ($trip->destination_country ?? $trip->title);
        $duration = max(1, min(14, $data->durationDays));
        $isFamily = in_array($data->travelParty, ['family_kids', 'seniors'], true);
        $isRelaxed = $data->pace === 'relaxed' || $isFamily;
        $currency = $this->resolveCurrency($destination);

        $days = null;

        // 1. Try Live Internet AI Generation via Google Gemini
        if ($this->geminiItineraryService !== null && ! app()->runningUnitTests()) {
            $liveDays = $this->geminiItineraryService->generatePlan(
                trip: $trip,
                data: $data,
                destination: $destination,
                duration: $duration,
                currency: $currency,
                isFamily: $isFamily,
            );
            if ($liveDays !== null && count($liveDays) > 0) {
                $days = $liveDays;
            }
        }

        // 2. Curated Heuristic clusters fallback
        if ($days === null) {
            $clusterTemplates = $this->getNeighborhoodClusters($destination);
            $days = [];

            for ($dayNum = 1; $dayNum <= $duration; $dayNum++) {
                $templateIndex = ($dayNum - 1) % count($clusterTemplates);
                $cluster = $clusterTemplates[$templateIndex];

                $activities = [];
                $stops = $isRelaxed ? array_slice($cluster['stops'], 0, 2) : $cluster['stops'];

                foreach ($stops as $idx => $stop) {
                    $activities[] = new AiActivitySuggestionData(
                        title: $stop['title'],
                        kind: $stop['kind'],
                        neighborhood: $cluster['neighborhood'],
                        description: $stop['description'],
                        plannedStartTime: $stop['start_time'],
                        plannedEndTime: $stop['end_time'],
                        placeName: $stop['place_name'],
                        placeAddress: "{$stop['place_name']}, {$cluster['neighborhood']}, {$destination}",
                        latitude: $stop['lat'] ?? null,
                        longitude: $stop['lng'] ?? null,
                        costEstimate: [
                            'amount_cents' => $this->calculateActivityCost($stop['kind'], $data->budgetTier),
                            'currency' => $currency,
                        ],
                        accessibilityNote: $isFamily
                            ? 'Stroller and step-free access available near primary station exits.'
                            : 'Standard pedestrian route with public transit access.',
                    );
                }

                $dailyBudget = array_sum(array_map(
                    static fn (AiActivitySuggestionData $a): int => (int) ($a->costEstimate['amount_cents'] ?? 0),
                    $activities
                ));

                $days[] = new AiDaySuggestionData(
                    dayNumber: $dayNum,
                    title: "Day {$dayNum}: {$cluster['theme']}",
                    theme: $cluster['theme'],
                    primaryNeighborhood: $cluster['neighborhood'],
                    activities: $activities,
                    budgetEstimate: [
                        'amount_cents' => $dailyBudget,
                        'currency' => $currency,
                    ],
                    familyTip: $isFamily
                        ? 'Allow 30-minute rest buffers between morning and afternoon walking stops.'
                        : null,
                );
            }
        }

        $totalBudget = array_sum(array_map(
            static fn (AiDaySuggestionData $d): int => (int) ($d->budgetEstimate['amount_cents'] ?? 0),
            $days
        ));

        return new AiItineraryPlanResult(
            destination: $destination,
            summary: "Curated {$duration}-day {$data->pace} itinerary for {$destination} focusing on ".implode(', ', $data->interests).'.',
            travelParty: $data->travelParty,
            pace: $data->pace,
            days: $days,
            totalEstimatedBudget: [
                'amount_cents' => $totalBudget,
                'currency' => $currency,
            ],
            weatherAlternativeNote: 'In case of rain or inclement weather, indoor observation decks, covered arcades, and major museums offer seamless underground connections.',
        );
    }

    private function resolveCurrency(string $destination): string
    {
        $lower = strtolower($destination);
        if (str_contains($lower, 'japan') || str_contains($lower, 'tokyo') || $lower === 'jp') {
            return 'JPY';
        }
        if (str_contains($lower, 'philippines') || str_contains($lower, 'manila') || $lower === 'ph') {
            return 'PHP';
        }
        if (str_contains($lower, 'hong kong') || str_contains($lower, 'hongkong') || $lower === 'hk') {
            return 'HKD';
        }
        if (str_contains($lower, 'singapore') || $lower === 'sg') {
            return 'SGD';
        }
        if (str_contains($lower, 'france') || str_contains($lower, 'paris') || str_contains($lower, 'europe')) {
            return 'EUR';
        }

        return 'USD';
    }

    private function calculateActivityCost(string $kind, string $budgetTier): int
    {
        $multiplier = match ($budgetTier) {
            'low' => 0.6,
            'luxury' => 2.5,
            default => 1.0,
        };

        $base = match ($kind) {
            'dining' => 2500,
            'sightseeing' => 1500,
            'activity' => 3000,
            default => 1000,
        };

        return (int) round($base * $multiplier);
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    private function getNeighborhoodClusters(string $destination): array
    {
        $lower = strtolower($destination);

        if (str_contains($lower, 'hong kong') || str_contains($lower, 'hongkong') || $lower === 'hk') {
            return [
                [
                    'neighborhood' => 'Central & Victoria Peak',
                    'theme' => 'Skyline Panoramas & Historic Trams',
                    'stops' => [
                        [
                            'title' => 'Peak Tram to Victoria Peak Sky Terrace',
                            'kind' => 'sightseeing',
                            'place_name' => 'Victoria Peak',
                            'description' => 'Historic funicular railway ride offering iconic 360-degree views of Victoria Harbour.',
                            'start_time' => '09:30',
                            'end_time' => '11:30',
                            'lat' => 22.2759,
                            'lng' => 114.1455,
                        ],
                        [
                            'title' => 'Traditional Dim Sum Lunch in Central',
                            'kind' => 'dining',
                            'place_name' => 'Lin Heung Tea House / Luk Yu',
                            'description' => 'Classic trolley-cart dim sum, har gow dumplings, and fragrant jasmine tea.',
                            'start_time' => '12:00',
                            'end_time' => '13:30',
                            'lat' => 22.2842,
                            'lng' => 114.1528,
                        ],
                        [
                            'title' => 'Central-Mid-Levels Escalator & Tai Kwun Heritage',
                            'kind' => 'sightseeing',
                            'place_name' => 'Tai Kwun Heritage Arts Centre',
                            'description' => 'World-famous covered outdoor escalator system and revitalized colonial police compound.',
                            'start_time' => '14:30',
                            'end_time' => '16:30',
                            'lat' => 22.2817,
                            'lng' => 114.1542,
                        ],
                    ],
                ],
                [
                    'neighborhood' => 'Tsim Sha Tsui & Harbour Promenade',
                    'theme' => 'Harbour Views, Star Ferry & Street Markets',
                    'stops' => [
                        [
                            'title' => 'Historic Star Ferry Harbour Crossing',
                            'kind' => 'transport',
                            'place_name' => 'Tsim Sha Tsui Star Ferry Pier',
                            'description' => 'Gentle harbour crossing between Central and Kowloon with panoramic sea breezes.',
                            'start_time' => '10:00',
                            'end_time' => '10:45',
                            'lat' => 22.2938,
                            'lng' => 114.1687,
                        ],
                        [
                            'title' => 'Avenue of Stars & Tsim Sha Tsui Promenade',
                            'kind' => 'sightseeing',
                            'place_name' => 'Avenue of Stars',
                            'description' => 'Stroll along the world-renowned harbourfront paying homage to cinematic legends.',
                            'start_time' => '11:00',
                            'end_time' => '12:30',
                            'lat' => 22.2932,
                            'lng' => 114.1738,
                        ],
                        [
                            'title' => 'Temple Street Night Market & Claypot Rice',
                            'kind' => 'dining',
                            'place_name' => 'Temple Street Night Market',
                            'description' => 'Vibrant night bazaar with open-air dai pai dong stalls, crispy seafood, and claypot rice.',
                            'start_time' => '18:00',
                            'end_time' => '20:00',
                            'lat' => 22.3089,
                            'lng' => 114.1694,
                        ],
                    ],
                ],
            ];
        }

        if (str_contains($lower, 'tokyo') || str_contains($lower, 'japan')) {
            return [
                [
                    'neighborhood' => 'Asakusa & Ueno',
                    'theme' => 'Historic Temples & Cultural Parks',
                    'stops' => [
                        [
                            'title' => 'Senso-ji Temple & Nakamise-dori',
                            'kind' => 'sightseeing',
                            'place_name' => 'Senso-ji Temple',
                            'description' => 'Historic Buddhist temple and traditional street food stalls along Nakamise.',
                            'start_time' => '09:30',
                            'end_time' => '11:30',
                            'lat' => 35.7148,
                            'lng' => 139.7967,
                        ],
                        [
                            'title' => 'Local Asakusa Soba or Ramen Lunch',
                            'kind' => 'dining',
                            'place_name' => 'Namiki Yabusoba',
                            'description' => 'Authentic hand-made buckwheat soba noodles in historic Asakusa.',
                            'start_time' => '12:00',
                            'end_time' => '13:00',
                            'lat' => 35.7101,
                            'lng' => 139.7972,
                        ],
                        [
                            'title' => 'Ueno Park & Tokyo National Museum',
                            'kind' => 'sightseeing',
                            'place_name' => 'Ueno Onshi Park',
                            'description' => 'Spacious cultural park with tree-lined promenades and world-class museums.',
                            'start_time' => '14:00',
                            'end_time' => '16:30',
                            'lat' => 35.7140,
                            'lng' => 139.7741,
                        ],
                    ],
                ],
                [
                    'neighborhood' => 'Shibuya & Harajuku',
                    'theme' => 'Modern Culture, Shrines & City Views',
                    'stops' => [
                        [
                            'title' => 'Meiji Jingu Shrine & Forest Walk',
                            'kind' => 'sightseeing',
                            'place_name' => 'Meiji Jingu',
                            'description' => 'Tranquil forested Shinto shrine in the heart of Shibuya.',
                            'start_time' => '09:30',
                            'end_time' => '11:00',
                            'lat' => 35.6764,
                            'lng' => 139.6993,
                        ],
                        [
                            'title' => 'Harajuku Takeshita Street & Cafe',
                            'kind' => 'activity',
                            'place_name' => 'Takeshita Street',
                            'description' => 'Vibrant youth fashion street, local crepes, and specialty coffee.',
                            'start_time' => '11:30',
                            'end_time' => '13:00',
                            'lat' => 35.6716,
                            'lng' => 139.7032,
                        ],
                        [
                            'title' => 'Shibuya Crossing & Shibuya Sky',
                            'kind' => 'sightseeing',
                            'place_name' => 'Shibuya Sky',
                            'description' => 'Iconic scramble intersection followed by 360-degree open-air rooftop views.',
                            'start_time' => '16:00',
                            'end_time' => '18:00',
                            'lat' => 35.6591,
                            'lng' => 139.7006,
                        ],
                    ],
                ],
                [
                    'neighborhood' => 'Shinjuku',
                    'theme' => 'Gardens, Skylines & Evening Dining',
                    'stops' => [
                        [
                            'title' => 'Shinjuku Gyoen National Garden',
                            'kind' => 'nature',
                            'place_name' => 'Shinjuku Gyoen',
                            'description' => 'Expansive park blending traditional Japanese, English landscape, and French gardens.',
                            'start_time' => '10:00',
                            'end_time' => '12:00',
                            'lat' => 35.6852,
                            'lng' => 139.7101,
                        ],
                        [
                            'title' => 'Tokyo Metropolitan Government Observatory',
                            'kind' => 'sightseeing',
                            'place_name' => 'Tokyo Metropolitan Gov Building',
                            'description' => 'Panoramic 45th floor city vistas with Mount Fuji views on clear days.',
                            'start_time' => '14:00',
                            'end_time' => '15:30',
                            'lat' => 35.6896,
                            'lng' => 139.6921,
                        ],
                        [
                            'title' => 'Omoide Yokocho Dinner & Stroll',
                            'kind' => 'dining',
                            'place_name' => 'Omoide Yokocho',
                            'description' => 'Atmospheric historic alleyway famous for yakitori skewers and local izakayas.',
                            'start_time' => '18:00',
                            'end_time' => '19:30',
                            'lat' => 35.6934,
                            'lng' => 139.6996,
                        ],
                    ],
                ],
            ];
        }

        // Generic International Destination Template
        return [
            [
                'neighborhood' => 'Old Town & Heritage Core',
                'theme' => 'Historic Sights & Landmark Discoveries',
                'stops' => [
                    [
                        'title' => 'Historic City Center & Main Square',
                        'kind' => 'sightseeing',
                        'place_name' => 'Central Plaza',
                        'description' => 'Guided walking tour through historic streets and cultural landmarks.',
                        'start_time' => '09:30',
                        'end_time' => '11:30',
                    ],
                    [
                        'title' => 'Heritage Bistro Lunch',
                        'kind' => 'dining',
                        'place_name' => 'Local Culinary Bistro',
                        'description' => 'Traditional regional lunch featuring local specialties.',
                        'start_time' => '12:00',
                        'end_time' => '13:30',
                    ],
                    [
                        'title' => 'Cultural Museum & Gallery',
                        'kind' => 'sightseeing',
                        'place_name' => 'National Art & History Museum',
                        'description' => 'World-class exhibits showcasing regional art and heritage.',
                        'start_time' => '14:30',
                        'end_time' => '16:30',
                    ],
                ],
            ],
            [
                'neighborhood' => 'Waterfront & Modern District',
                'theme' => 'Harbor Promenades & Scenic Vistas',
                'stops' => [
                    [
                        'title' => 'Waterfront Promenade & Gardens',
                        'kind' => 'nature',
                        'place_name' => 'Harbor Gardens',
                        'description' => 'Scenic waterside stroll with refreshing coastal views.',
                        'start_time' => '10:00',
                        'end_time' => '12:00',
                    ],
                    [
                        'title' => 'Market Square Tasting Tour',
                        'kind' => 'dining',
                        'place_name' => 'Central Farmers Market',
                        'description' => 'Artisanal cheese, street foods, and fresh seasonal treats.',
                        'start_time' => '12:30',
                        'end_time' => '14:00',
                    ],
                    [
                        'title' => 'Sunset Scenic Lookout',
                        'kind' => 'sightseeing',
                        'place_name' => 'Skyline Viewpoint',
                        'description' => 'Panoramic sunset view overlooking the city skyline.',
                        'start_time' => '17:00',
                        'end_time' => '18:30',
                    ],
                ],
            ],
        ];
    }
}
