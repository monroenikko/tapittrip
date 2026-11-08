<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\TripBudget;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripExpenseTest extends TestCase
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
            'title' => 'Tokyo Culinary Journey',
            'destination_country' => 'JP',
        ]);

        TripBudget::create([
            'trip_id' => $this->trip->id,
            'currency' => 'USD',
            'total_budget_minor' => 100000, // $1,000.00
            'daily_budget_minor' => 20000,
        ]);
    }

    public function test_user_can_create_expense_with_currency_conversion(): void
    {
        // Trip is in USD, expense logged in JPY at rate 0.0067
        $response = $this->postJson("/api/v1/trips/{$this->trip->id}/expenses", [
            'category' => 'dining',
            'title' => 'Ramen Lunch in Shinjuku',
            'amount_minor' => 3000, // ¥3,000
            'currency' => 'JPY',
            'exchange_rate' => 0.0067,
            'expense_date' => '2026-11-10',
            'notes' => 'Delicious tonkotsu broth',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.category', 'dining')
            ->assertJsonPath('data.title', 'Ramen Lunch in Shinjuku')
            ->assertJsonPath('data.amount_minor', 3000)
            ->assertJsonPath('data.currency', 'JPY')
            ->assertJsonPath('data.base_amount_minor', 20); // 3000 * 0.0067 = 20.1 -> 20 USD cents

        $this->assertDatabaseHas('expenses', [
            'trip_id' => $this->trip->id,
            'title' => 'Ramen Lunch in Shinjuku',
            'amount_minor' => 3000,
            'base_amount_minor' => 20,
        ]);
    }

    public function test_user_can_update_expense_in_place(): void
    {
        $expense = Expense::factory()->create([
            'trip_id' => $this->trip->id,
            'payer_id' => $this->user->id,
            'title' => 'Metro Day Pass',
            'category' => 'transport',
            'amount_minor' => 800,
            'currency' => 'USD',
            'exchange_rate' => 1.0,
            'base_amount_minor' => 800,
        ]);

        $response = $this->patchJson("/api/v1/expenses/{$expense->id}", [
            'title' => '24-Hour Subway Pass',
            'amount_minor' => 1200,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.title', '24-Hour Subway Pass')
            ->assertJsonPath('data.amount_minor', 1200)
            ->assertJsonPath('data.base_amount_minor', 1200)
            ->assertJsonPath('data.version', 2);
    }

    public function test_user_can_filter_expenses_by_category(): void
    {
        Expense::factory()->create([
            'trip_id' => $this->trip->id,
            'payer_id' => $this->user->id,
            'category' => 'dining',
            'title' => 'Sushi Dinner',
        ]);

        Expense::factory()->create([
            'trip_id' => $this->trip->id,
            'payer_id' => $this->user->id,
            'category' => 'transport',
            'title' => 'Bullet Train Ticket',
        ]);

        $response = $this->getJson("/api/v1/trips/{$this->trip->id}/expenses?category=dining");

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('Sushi Dinner', $response->json('data.0.title'));
    }

    public function test_user_can_soft_delete_expense(): void
    {
        $expense = Expense::factory()->create([
            'trip_id' => $this->trip->id,
            'payer_id' => $this->user->id,
        ]);

        $response = $this->deleteJson("/api/v1/expenses/{$expense->id}");

        $response->assertNoContent();
        $this->assertSoftDeleted('expenses', ['id' => $expense->id]);
    }

    public function test_user_can_view_aggregated_expense_summary(): void
    {
        Expense::factory()->create([
            'trip_id' => $this->trip->id,
            'payer_id' => $this->user->id,
            'category' => 'dining',
            'base_amount_minor' => 4000, // $40.00
            'expense_date' => '2026-11-10',
        ]);

        Expense::factory()->create([
            'trip_id' => $this->trip->id,
            'payer_id' => $this->user->id,
            'category' => 'transport',
            'base_amount_minor' => 6000, // $60.00
            'expense_date' => '2026-11-10',
        ]);

        $response = $this->getJson("/api/v1/trips/{$this->trip->id}/expenses/summary");

        $response->assertOk()
            ->assertJsonPath('data.base_currency', 'USD')
            ->assertJsonPath('data.total_budget_minor', 100000)
            ->assertJsonPath('data.total_spent_base_minor', 10000)
            ->assertJsonPath('data.remaining_budget_minor', 90000)
            ->assertJsonPath('data.expenses_count', 2);

        $this->assertEquals(10.0, $response->json('data.budget_utilization_percent'));

        $breakdown = $response->json('data.category_breakdown');
        $this->assertCount(2, $breakdown);
    }

    public function test_non_trip_members_cannot_log_expenses(): void
    {
        $otherUser = User::factory()->create();
        Sanctum::actingAs($otherUser);

        $response = $this->postJson("/api/v1/trips/{$this->trip->id}/expenses", [
            'category' => 'shopping',
            'title' => 'Souvenirs',
            'amount_minor' => 5000,
            'currency' => 'JPY',
            'expense_date' => '2026-11-10',
        ]);

        $response->assertForbidden();
    }
}
