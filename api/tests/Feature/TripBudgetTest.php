<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Expenses\Models\TripBudget;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripBudgetTest extends TestCase
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
            'title' => 'Tokyo Holiday',
            'destination_country' => 'JP',
        ]);
    }

    public function test_user_can_set_and_update_trip_budget(): void
    {
        $response = $this->putJson("/api/v1/trips/{$this->trip->id}/budget", [
            'currency' => 'JPY',
            'total_budget_minor' => 300000,
            'daily_budget_minor' => 50000,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.currency', 'JPY')
            ->assertJsonPath('data.total_budget_minor', 300000)
            ->assertJsonPath('data.daily_budget_minor', 50000);

        $this->assertDatabaseHas('trip_budgets', [
            'trip_id' => $this->trip->id,
            'currency' => 'JPY',
            'total_budget_minor' => 300000,
        ]);

        // Update existing budget
        $updateResponse = $this->putJson("/api/v1/trips/{$this->trip->id}/budget", [
            'currency' => 'JPY',
            'total_budget_minor' => 350000,
            'daily_budget_minor' => 60000,
        ]);

        $updateResponse->assertOk()
            ->assertJsonPath('data.total_budget_minor', 350000);

        $this->assertEquals(1, TripBudget::where('trip_id', $this->trip->id)->count());
    }

    public function test_user_can_view_trip_budget(): void
    {
        TripBudget::create([
            'trip_id' => $this->trip->id,
            'currency' => 'EUR',
            'total_budget_minor' => 200000,
            'daily_budget_minor' => 40000,
        ]);

        $response = $this->getJson("/api/v1/trips/{$this->trip->id}/budget");

        $response->assertOk()
            ->assertJsonPath('data.currency', 'EUR')
            ->assertJsonPath('data.total_budget_minor', 200000);
    }

    public function test_budget_returns_null_data_when_unset(): void
    {
        $response = $this->getJson("/api/v1/trips/{$this->trip->id}/budget");

        $response->assertOk()
            ->assertJsonPath('data', null);
    }

    public function test_non_trip_members_cannot_modify_budget(): void
    {
        $otherUser = User::factory()->create();
        Sanctum::actingAs($otherUser);

        $response = $this->putJson("/api/v1/trips/{$this->trip->id}/budget", [
            'currency' => 'USD',
            'total_budget_minor' => 100000,
        ]);

        $response->assertForbidden();
    }

    public function test_budget_validation_fails_for_invalid_amounts(): void
    {
        $response = $this->putJson("/api/v1/trips/{$this->trip->id}/budget", [
            'currency' => 'INVALID',
            'total_budget_minor' => -50,
        ]);

        $response->assertUnprocessable();
    }
}
