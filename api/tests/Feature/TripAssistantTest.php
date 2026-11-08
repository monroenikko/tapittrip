<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Lounges\Models\Airport;
use App\Domain\Lounges\Models\AirportLounge;
use App\Domain\Lounges\Models\AirportTerminal;
use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripAssistantTest extends TestCase
{
    use DatabaseTransactions;

    private User $user;

    private Trip $trip;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);

        $this->trip = Trip::factory()->create([
            'owner_id' => $this->user->id,
            'title' => 'Tokyo Family Explorer',
            'destination_country' => 'JP',
            'start_date' => '2026-11-10',
            'end_date' => '2026-11-15',
        ]);
    }

    public function test_assistant_provides_dining_near_hotel_when_stay_exists(): void
    {
        Stay::create([
            'trip_id' => $this->trip->id,
            'name' => 'Shinjuku Granbell Hotel',
            'stay_type' => 'hotel',
            'address' => '2-14-5 Kabukicho, Shinjuku, Tokyo',
            'check_in_at' => '2026-11-10 15:00:00',
            'check_out_at' => '2026-11-15 11:00:00',
            'timezone' => 'Asia/Tokyo',
            'version' => 1,
        ]);

        $response = $this->postJson("/api/v1/trips/{$this->trip->id}/assistant/query", [
            'query' => 'Where should we go tomorrow near our hotel to eat?',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.category', 'dining')
            ->assertJsonPath('data.context_summary.has_stay', true)
            ->assertJsonPath('data.context_summary.stay_name', 'Shinjuku Granbell Hotel');

        $this->assertStringContainsString('Shinjuku Granbell Hotel', $response->json('data.reply'));
        $this->assertNotEmpty($response->json('data.suggested_actions'));
    }

    public function test_assistant_suggests_adding_stay_when_no_stay_exists_yet(): void
    {
        $response = $this->postJson("/api/v1/trips/{$this->trip->id}/assistant/query", [
            'query' => 'Where can we eat near our hotel?',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.category', 'dining')
            ->assertJsonPath('data.context_summary.has_stay', false);

        $this->assertStringContainsString("You don't have an accommodation saved yet", $response->json('data.reply'));
    }

    public function test_assistant_answers_lounge_query_for_terminal_with_gate_reminder(): void
    {
        $airport = Airport::create([
            'iata_code' => 'MNL',
            'name' => 'Ninoy Aquino International Airport',
            'city' => 'Manila',
            'country' => 'Philippines',
            'timezone' => 'Asia/Manila',
        ]);

        $terminal = AirportTerminal::create([
            'airport_id' => $airport->id,
            'name' => 'Terminal 3',
            'code' => 'T3',
        ]);

        AirportLounge::create([
            'airport_id' => $airport->id,
            'terminal_id' => $terminal->id,
            'name' => 'PAGSS Premium Lounge T3',
            'operator' => 'PAGSS',
            'location_description' => 'Airside, 4th Floor near Gate 114',
            'is_airside' => true,
            'amenities' => ['wi-fi', 'showers', 'buffet'],
            'access_methods' => ['Priority Pass', 'Business Class'],
        ]);

        $response = $this->postJson("/api/v1/trips/{$this->trip->id}/assistant/query", [
            'query' => 'Which lounge can I use in Terminal 3?',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.category', 'lounge');

        $reply = $response->json('data.reply');
        $this->assertStringContainsString('PAGSS Premium Lounge T3', $reply);
        $this->assertStringContainsString('Gate Reminder', $reply);
    }

    public function test_assistant_provides_toddler_friendly_and_pacing_guidance(): void
    {
        $response = $this->postJson("/api/v1/trips/{$this->trip->id}/assistant/query", [
            'query' => 'Can you make Day 2 easier for our toddler?',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.category', 'toddler_friendly');

        $reply = $response->json('data.reply');
        $this->assertStringContainsString('Midday Nap', $reply);
        $this->assertStringContainsString('Stroller', $reply);
    }

    public function test_assistant_provides_weather_alternatives(): void
    {
        $response = $this->postJson("/api/v1/trips/{$this->trip->id}/assistant/query", [
            'query' => 'What should we do if it rains today?',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.category', 'weather');

        $reply = $response->json('data.reply');
        $this->assertStringContainsString('Shopping Arcades', $reply);
        $this->assertStringContainsString('Museums', $reply);
    }

    public function test_non_trip_members_cannot_query_assistant(): void
    {
        $otherUser = User::factory()->create();
        Sanctum::actingAs($otherUser);

        $response = $this->postJson("/api/v1/trips/{$this->trip->id}/assistant/query", [
            'query' => 'Where to eat?',
        ]);

        $response->assertForbidden();
    }

    public function test_query_validation_requires_minimum_length(): void
    {
        $response = $this->postJson("/api/v1/trips/{$this->trip->id}/assistant/query", [
            'query' => 'hi',
        ]);

        $response->assertUnprocessable();
    }
}
