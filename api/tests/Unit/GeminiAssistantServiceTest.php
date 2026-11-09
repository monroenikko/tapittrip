<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Application\Itinerary\Services\GeminiAssistantService;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

final class GeminiAssistantServiceTest extends TestCase
{
    use DatabaseTransactions;

    private Trip $trip;

    private GeminiAssistantService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $user = User::factory()->create();
        $this->trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'title' => 'Tokyo Winter Explorer',
            'destination_country' => 'Japan',
            'start_date' => '2026-12-01',
            'end_date' => '2026-12-07',
            'trip_type' => 'leisure',
        ]);

        $this->service = new GeminiAssistantService;
    }

    public function test_returns_null_when_gemini_api_key_is_missing(): void
    {
        Config::set('services.gemini.api_key', '');

        $result = $this->service->ask($this->trip, 'What should I pack for Tokyo in December?');

        $this->assertNull($result);
    }

    public function test_successfully_answers_travel_query_with_suggestions_and_actions(): void
    {
        Config::set('services.gemini.api_key', 'test-api-key');

        $fakeAiResponse = [
            'candidates' => [
                [
                    'content' => [
                        'parts' => [
                            [
                                'text' => json_encode([
                                    'reply' => "For Tokyo in December, temperatures range from 5°C to 12°C.\n\n• **Layering**: Thermal undershirts (Heattech), down jacket, and comfortable walking shoes.\n• **Recommended Warm Stop**: Cozy up at Meiji Shrine or enjoy hot matcha.",
                                    'category' => 'packing',
                                    'suggested_actions' => [
                                        [
                                            'label' => 'Add Meiji Shrine Walk',
                                            'kind' => 'add_activity',
                                            'payload' => [
                                                'title' => 'Meiji Shrine Winter Morning Walk',
                                                'kind' => 'sightseeing',
                                                'place_name' => 'Meiji Jingu',
                                                'notes' => 'Crisp winter morning walk in the evergreen forest',
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
            'generativelanguage.googleapis.com/*' => Http::response($fakeAiResponse, 200),
        ]);

        $result = $this->service->ask($this->trip, 'What should I pack for Tokyo in December?');

        $this->assertNotNull($result);
        $this->assertSame('packing', $result->category);
        $this->assertStringContainsString('Layering', $result->reply);
        $this->assertCount(1, $result->suggestedActions);

        $action = $result->suggestedActions[0];
        $this->assertSame('Add Meiji Shrine Walk', $action['label']);
        $this->assertSame('add_activity', $action['kind']);
        // Notice kind should be normalized to canonical 'attraction'
        $this->assertSame('attraction', $action['payload']['kind']);
        $this->assertSame('Meiji Jingu', $action['payload']['place_name']);
    }

    public function test_out_of_scope_inquiry_returns_out_of_scope_category_and_redirection(): void
    {
        Config::set('services.gemini.api_key', 'test-api-key');

        $fakeAiResponse = [
            'candidates' => [
                [
                    'content' => [
                        'parts' => [
                            [
                                'text' => json_encode([
                                    'reply' => 'I am your TapItTrip travel companion, focused exclusively on travel advice, trip planning, local recommendations, and journey logistics. How can I help with your trip to Tokyo Winter Explorer?',
                                    'category' => 'out_of_scope',
                                    'suggested_actions' => [],
                                ]),
                            ],
                        ],
                    ],
                ],
            ],
        ];

        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response($fakeAiResponse, 200),
        ]);

        $result = $this->service->ask($this->trip, 'Can you write me Python code to sort an array?');

        $this->assertNotNull($result);
        $this->assertSame('out_of_scope', $result->category);
        $this->assertStringContainsString('focused exclusively on travel advice', $result->reply);
        $this->assertEmpty($result->suggestedActions);
    }

    public function test_handles_gemini_api_timeout_or_error_gracefully(): void
    {
        Config::set('services.gemini.api_key', 'test-api-key');

        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response(['error' => 'API quota exceeded'], 503),
        ]);

        $result = $this->service->ask($this->trip, 'What to do in Shibuya?');

        $this->assertNull($result);
    }
}
