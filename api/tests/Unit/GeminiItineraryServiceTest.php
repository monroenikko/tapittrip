<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Application\Itinerary\Data\GenerateAiItineraryData;
use App\Application\Itinerary\Services\GeminiItineraryService;
use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

final class GeminiItineraryServiceTest extends TestCase
{
    public function test_returns_null_when_api_key_is_missing(): void
    {
        Config::set('services.gemini.api_key', '');

        $service = new GeminiItineraryService;
        $trip = new Trip(['title' => 'Taguig Trip']);
        $data = new GenerateAiItineraryData(destination: 'BGC Taguig');

        $result = $service->generatePlan($trip, $data, 'BGC Taguig', 2, 'PHP', false);
        $this->assertNull($result);
    }

    public function test_parses_live_gemini_itinerary_response_correctly(): void
    {
        Config::set('services.gemini.api_key', 'test-fake-key');

        $geminiResponse = [
            'candidates' => [
                [
                    'content' => [
                        'parts' => [
                            [
                                'text' => json_encode([
                                    [
                                        'day_number' => 1,
                                        'title' => 'Day 1: High Street & Contemporary Art',
                                        'theme' => 'Modern Culture',
                                        'primary_neighborhood' => 'Bonifacio Global City',
                                        'family_tip' => 'Wide flat sidewalks throughout',
                                        'activities' => [
                                            [
                                                'title' => 'Bonifacio High Street Promenade Walk',
                                                'kind' => 'sightseeing',
                                                'neighborhood' => 'BGC',
                                                'place_name' => 'Bonifacio High Street',
                                                'place_address' => 'BGC, Taguig, Philippines',
                                                'description' => 'Pedestrian mall with interactive art installations.',
                                                'start_time' => '10:00',
                                                'end_time' => '12:00',
                                                'latitude' => 14.5505,
                                                'longitude' => 121.0509,
                                                'cost_cents' => 0,
                                                'accessibility_note' => 'Step-free open air mall',
                                            ],
                                            [
                                                'title' => 'Lunch at Wildflour Cafe + Bakery',
                                                'kind' => 'dining',
                                                'neighborhood' => 'BGC',
                                                'place_name' => 'Wildflour BGC',
                                                'place_address' => '4th Ave cor 26th St, Taguig',
                                                'description' => 'Celebrated brunch & local pastries.',
                                                'start_time' => '12:30',
                                                'end_time' => '14:00',
                                                'latitude' => 14.5492,
                                                'longitude' => 121.0475,
                                                'cost_cents' => 85000,
                                                'accessibility_note' => 'Street level access',
                                            ],
                                        ],
                                    ],
                                ]),
                            ],
                        ],
                    ],
                ],
            ],
        ];

        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response($geminiResponse, 200),
        ]);

        $trip = new Trip(['title' => 'BGC Stay']);
        $data = new GenerateAiItineraryData(destination: 'BGC Taguig');
        $service = new GeminiItineraryService;

        $days = $service->generatePlan($trip, $data, 'BGC Taguig', 1, 'PHP', false);

        $this->assertNotNull($days);
        $this->assertCount(1, $days);
        $this->assertEquals('Day 1: High Street & Contemporary Art', $days[0]->title);
        $this->assertCount(2, $days[0]->activities);
        $this->assertEquals('Bonifacio High Street Promenade Walk', $days[0]->activities[0]->title);
        $this->assertEquals('PHP', $days[0]->budgetEstimate['currency']);
    }
}
