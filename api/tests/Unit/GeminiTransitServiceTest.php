<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Application\Stays\Data\CompareStayTransportData;
use App\Application\Stays\Services\GeminiTransitService;
use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

final class GeminiTransitServiceTest extends TestCase
{
    public function test_returns_null_when_api_key_is_missing(): void
    {
        Config::set('services.gemini.api_key', '');

        $service = new GeminiTransitService;
        $stay = new Stay(['name' => 'Grand Hotel']);
        $data = new CompareStayTransportData(partySize: 2, luggagePreset: 'standard');

        $result = $service->getLiveTransportOptions(
            stay: $stay,
            data: $data,
            transitInfo: [],
            origin: 'Airport',
            destinationCurrency: 'USD',
            isHeavyLuggage: false,
        );

        $this->assertNull($result);
    }

    public function test_parses_and_scores_live_gemini_json_response_correctly(): void
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
                                        'mode' => 'express_rail',
                                        'title' => 'SBB Direct Airport Train',
                                        'provider' => 'Swiss Federal Railways',
                                        'estimated_duration_minutes' => 12,
                                        'estimated_cost_minor' => 690,
                                        'currency' => 'CHF',
                                        'transfers' => 0,
                                        'walking_meters' => 150,
                                        'boarding_location' => 'ZRH Station Platform 3',
                                        'dropoff_location' => 'Zurich HB',
                                        'explanation' => 'Fastest rail link directly to downtown.',
                                    ],
                                    [
                                        'mode' => 'private_transfer',
                                        'title' => 'VIP Chauffeur Transfer',
                                        'provider' => 'Zurich Airport Limo',
                                        'estimated_duration_minutes' => 20,
                                        'estimated_cost_minor' => 8500,
                                        'currency' => 'CHF',
                                        'transfers' => 0,
                                        'walking_meters' => 30,
                                        'boarding_location' => 'Arrivals Hall',
                                        'dropoff_location' => 'Hotel Entrance',
                                        'explanation' => 'Door-to-door luxury sedan for heavy bags.',
                                    ],
                                    [
                                        'mode' => 'rideshare',
                                        'title' => 'UberX Airport Pickup',
                                        'provider' => 'Uber',
                                        'estimated_duration_minutes' => 22,
                                        'estimated_cost_minor' => 4500,
                                        'currency' => 'CHF',
                                        'transfers' => 0,
                                        'walking_meters' => 100,
                                        'boarding_location' => 'Rideshare Pickup Bay',
                                        'dropoff_location' => 'Hotel',
                                        'explanation' => 'On-demand car.',
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

        $trip = new Trip(['destination_country' => 'Switzerland', 'title' => 'Swiss Trip']);
        $stay = new Stay(['name' => 'Storchen Zürich', 'address' => 'Weinplatz 2, Zurich']);
        $stay->setRelation('trip', $trip);

        $data = new CompareStayTransportData(
            partySize: 2,
            luggagePreset: 'heavy',
            checkedBags: 3,
            stroller: true,
        );

        $service = new GeminiTransitService;
        $options = $service->getLiveTransportOptions(
            stay: $stay,
            data: $data,
            transitInfo: ['station_name' => 'Zurich HB'],
            origin: 'Zurich Airport (ZRH)',
            destinationCurrency: 'CHF',
            isHeavyLuggage: true,
        );

        $this->assertNotNull($options);
        $this->assertCount(3, $options);

        // Verify Swiss Francs currency
        $this->assertEquals('CHF', $options[0]['currency']);

        // Verify fastest option
        $rail = collect($options)->firstWhere('mode', 'express_rail');
        $this->assertNotNull($rail);
        $this->assertTrue($rail['is_fastest']);
        $this->assertTrue($rail['is_cheapest']);

        // Verify private transfer wins most convenient under heavy luggage
        $private = collect($options)->firstWhere('mode', 'private_transfer');
        $this->assertNotNull($private);
        $this->assertTrue($private['is_most_convenient']);
    }

    public function test_handles_gemini_api_timeout_or_error_gracefully(): void
    {
        Config::set('services.gemini.api_key', 'test-fake-key');

        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response(['error' => ['message' => 'Rate limit exceeded']], 429),
        ]);

        $service = new GeminiTransitService;
        $stay = new Stay(['name' => 'Grand Hotel']);
        $data = new CompareStayTransportData(partySize: 2, luggagePreset: 'standard');

        $result = $service->getLiveTransportOptions(
            stay: $stay,
            data: $data,
            transitInfo: [],
            origin: 'Airport',
            destinationCurrency: 'USD',
            isHeavyLuggage: false,
        );

        $this->assertNull($result);
    }
}
