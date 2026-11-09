<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Lounges\Models\Airport;
use App\Domain\Lounges\Models\AirportLounge;
use App\Domain\Lounges\Models\AirportTerminal;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class AirportLoungeTest extends TestCase
{
    use DatabaseTransactions;

    public function test_user_can_search_lounges_by_airport_iata(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $airport = Airport::factory()->create(['iata_code' => 'MNL', 'name' => 'Ninoy Aquino International Airport']);
        $terminal = AirportTerminal::factory()->create(['airport_id' => $airport->id, 'code' => 'T3', 'name' => 'Terminal 3']);

        $lounge = AirportLounge::factory()->create([
            'airport_id' => $airport->id,
            'terminal_id' => $terminal->id,
            'name' => 'PAGSS Premium Lounge',
            'is_airside' => true,
        ]);

        $response = $this->getJson('/api/v1/airports/mnl/lounges');

        $response->assertStatus(200)
            ->assertJsonPath('data.airport.iata_code', 'MNL')
            ->assertJsonPath('data.lounges.0.name', 'PAGSS Premium Lounge')
            ->assertJsonPath('data.lounges.0.terminal.code', 'T3');
    }

    public function test_user_can_filter_lounges_by_terminal(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $airport = Airport::factory()->create(['iata_code' => 'SIN']);
        $t1 = AirportTerminal::factory()->create(['airport_id' => $airport->id, 'code' => 'T1', 'name' => 'Terminal 1']);
        $t3 = AirportTerminal::factory()->create(['airport_id' => $airport->id, 'code' => 'T3', 'name' => 'Terminal 3']);

        AirportLounge::factory()->create([
            'airport_id' => $airport->id,
            'terminal_id' => $t1->id,
            'name' => 'Plaza Premium Lounge T1',
        ]);

        $loungeT3 = AirportLounge::factory()->create([
            'airport_id' => $airport->id,
            'terminal_id' => $t3->id,
            'name' => 'SATS Premier Lounge T3',
        ]);

        $response = $this->getJson('/api/v1/airports/SIN/lounges?terminal=T3');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data.lounges')
            ->assertJsonPath('data.lounges.0.id', $loungeT3->id)
            ->assertJsonPath('data.lounges.0.name', 'SATS Premier Lounge T3');
    }

    public function test_user_can_filter_lounges_by_access_method(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $airport = Airport::factory()->create(['iata_code' => 'NRT']);
        $terminal = AirportTerminal::factory()->create(['airport_id' => $airport->id, 'code' => 'T1']);

        $priorityPassLounge = AirportLounge::factory()->create([
            'airport_id' => $airport->id,
            'terminal_id' => $terminal->id,
            'name' => 'IASS Superior Lounge',
            'access_methods' => ['priority_pass', 'lounge_key'],
        ]);

        AirportLounge::factory()->create([
            'airport_id' => $airport->id,
            'terminal_id' => $terminal->id,
            'name' => 'Airline Exclusive Lounge',
            'access_methods' => ['first_class', 'star_alliance_gold'],
        ]);

        $response = $this->getJson('/api/v1/airports/NRT/lounges?access_methods[]=priority_pass');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data.lounges')
            ->assertJsonPath('data.lounges.0.id', $priorityPassLounge->id);
    }

    public function test_user_can_view_lounge_details(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $airport = Airport::factory()->create(['iata_code' => 'HND']);
        $terminal = AirportTerminal::factory()->create(['airport_id' => $airport->id, 'code' => 'T3']);

        $lounge = AirportLounge::factory()->create([
            'airport_id' => $airport->id,
            'terminal_id' => $terminal->id,
            'name' => 'TIAT Lounge',
            'location_description' => 'Near Gate 114, Level 4',
            'amenities' => ['buffet', 'showers', 'wifi'],
            'transit_warning' => 'Must hold a departure boarding pass from Terminal 3.',
        ]);

        $response = $this->getJson("/api/v1/lounges/{$lounge->id}");

        $response->assertStatus(200)
            ->assertJsonPath('data.id', $lounge->id)
            ->assertJsonPath('data.name', 'TIAT Lounge')
            ->assertJsonPath('data.location_description', 'Near Gate 114, Level 4')
            ->assertJsonPath('data.transit_warning', 'Must hold a departure boarding pass from Terminal 3.')
            ->assertJsonPath('data.amenities', ['buffet', 'showers', 'wifi']);
    }

    public function test_user_can_list_and_search_global_airports(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/airports?q=London');

        $response->assertStatus(200)
            ->assertJsonPath('data.0.iata_code', 'LHR');
    }

    public function test_user_can_search_lounges_by_city_alias(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/airports/LONDON/lounges');

        $response->assertStatus(200)
            ->assertJsonPath('data.airport.iata_code', 'LHR');
    }

    public function test_search_unknown_airport_returns_404(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/airports/ZZZ/lounges');

        $response->assertStatus(404);
    }
}
