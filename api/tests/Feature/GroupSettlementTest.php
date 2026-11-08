<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\TripBudget;
use App\Domain\Trips\Models\Trip;
use App\Domain\Trips\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class GroupSettlementTest extends TestCase
{
    use DatabaseTransactions;

    public function test_can_get_group_balances_and_suggested_settlements(): void
    {
        $owner = User::factory()->create(['name' => 'Alice']);
        $member = User::factory()->create(['name' => 'Bob']);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $member->id,
            'role' => 'editor',
        ]);

        TripBudget::factory()->create([
            'trip_id' => $trip->id,
            'currency' => 'USD',
            'total_budget_minor' => 100000,
        ]);

        // Alice pays $60 for dining, split equally
        $expense = Expense::factory()->create([
            'trip_id' => $trip->id,
            'payer_id' => $owner->id,
            'title' => 'Dinner in Shibuya',
            'category' => 'dining',
            'amount_minor' => 6000,
            'currency' => 'USD',
            'base_amount_minor' => 6000,
            'split_type' => 'equal',
        ]);

        Sanctum::actingAs($owner);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/settlements");

        $response->assertOk()
            ->assertJsonPath('data.trip_id', $trip->id)
            ->assertJsonPath('data.base_currency', 'USD');

        $balances = collect($response->json('data.balances'));
        $aliceBalance = $balances->firstWhere('user_id', $owner->id);
        $bobBalance = $balances->firstWhere('user_id', $member->id);

        $this->assertEquals(3000, $aliceBalance['net_balance_minor']);
        $this->assertEquals('is_owed', $aliceBalance['status']);

        $this->assertEquals(-3000, $bobBalance['net_balance_minor']);
        $this->assertEquals('owes', $bobBalance['status']);

        // Check suggested settlement: Bob owes Alice $30
        $suggested = $response->json('data.suggested_settlements');
        $this->assertCount(1, $suggested);
        $this->assertEquals($member->id, $suggested[0]['payer_id']);
        $this->assertEquals($owner->id, $suggested[0]['payee_id']);
        $this->assertEquals(3000, $suggested[0]['amount_minor']);
        $this->assertEquals('USD', $suggested[0]['currency']);
    }

    public function test_greedy_cash_flow_minimization_with_three_members(): void
    {
        $alice = User::factory()->create(['name' => 'Alice']);
        $bob = User::factory()->create(['name' => 'Bob']);
        $charlie = User::factory()->create(['name' => 'Charlie']);

        $trip = Trip::factory()->create(['owner_id' => $alice->id]);
        TripMember::factory()->create(['trip_id' => $trip->id, 'user_id' => $bob->id, 'role' => 'editor']);
        TripMember::factory()->create(['trip_id' => $trip->id, 'user_id' => $charlie->id, 'role' => 'viewer']);

        // Alice pays $60 ($20 each)
        Expense::factory()->create([
            'trip_id' => $trip->id,
            'payer_id' => $alice->id,
            'amount_minor' => 6000,
            'currency' => 'USD',
            'base_amount_minor' => 6000,
            'split_type' => 'equal',
        ]);

        // Bob pays $30 ($10 each)
        Expense::factory()->create([
            'trip_id' => $trip->id,
            'payer_id' => $bob->id,
            'amount_minor' => 3000,
            'currency' => 'USD',
            'base_amount_minor' => 3000,
            'split_type' => 'equal',
        ]);

        Sanctum::actingAs($alice);

        $response = $this->getJson("/api/v1/trips/{$trip->id}/settlements");

        $response->assertOk();

        $balances = collect($response->json('data.balances'));
        $aliceBalance = $balances->firstWhere('user_id', $alice->id);
        $bobBalance = $balances->firstWhere('user_id', $bob->id);
        $charlieBalance = $balances->firstWhere('user_id', $charlie->id);

        $this->assertEquals(3000, $aliceBalance['net_balance_minor']); // +60 - 20 - 10 = +30
        $this->assertEquals(0, $bobBalance['net_balance_minor']);       // +30 - 20 - 10 = 0
        $this->assertEquals(-3000, $charlieBalance['net_balance_minor']); // 0 - 20 - 10 = -30

        // Only 1 transaction needed: Charlie pays Alice directly!
        $suggested = $response->json('data.suggested_settlements');
        $this->assertCount(1, $suggested);
        $this->assertEquals($charlie->id, $suggested[0]['payer_id']);
        $this->assertEquals($alice->id, $suggested[0]['payee_id']);
        $this->assertEquals(3000, $suggested[0]['amount_minor']);
    }

    public function test_can_record_settlement_payment(): void
    {
        $owner = User::factory()->create(['name' => 'Alice']);
        $member = User::factory()->create(['name' => 'Bob']);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::factory()->create(['trip_id' => $trip->id, 'user_id' => $member->id, 'role' => 'editor']);

        // Alice pays $40 split equally ($20 each)
        Expense::factory()->create([
            'trip_id' => $trip->id,
            'payer_id' => $owner->id,
            'amount_minor' => 4000,
            'currency' => 'USD',
            'base_amount_minor' => 4000,
            'split_type' => 'equal',
        ]);

        Sanctum::actingAs($owner);

        // Bob settles $20 to Alice
        $settleResponse = $this->postJson("/api/v1/trips/{$trip->id}/settlements", [
            'payer_id' => $member->id,
            'payee_id' => $owner->id,
            'amount_minor' => 2000,
            'currency' => 'USD',
            'settled_at' => now()->toIso8601String(),
            'notes' => 'Venmo transfer',
        ]);

        $settleResponse->assertCreated()
            ->assertJsonPath('data.payer_id', $member->id)
            ->assertJsonPath('data.payee_id', $owner->id)
            ->assertJsonPath('data.amount_minor', 2000)
            ->assertJsonPath('data.notes', 'Venmo transfer');

        // Balances should now be settled
        $balancesResponse = $this->getJson("/api/v1/trips/{$trip->id}/settlements");
        $balancesResponse->assertOk()
            ->assertJsonPath('data.suggested_settlements', []);

        $balances = collect($balancesResponse->json('data.balances'));
        $this->assertEquals(0, $balances->firstWhere('user_id', $owner->id)['net_balance_minor']);
        $this->assertEquals(0, $balances->firstWhere('user_id', $member->id)['net_balance_minor']);

        $history = $balancesResponse->json('data.settlement_history');
        $this->assertCount(1, $history);
        $this->assertEquals(2000, $history[0]['amount_minor']);
    }

    public function test_cannot_record_settlement_with_invalid_members_or_same_user(): void
    {
        $owner = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($owner);

        // Same user as payer and payee
        $response = $this->postJson("/api/v1/trips/{$trip->id}/settlements", [
            'payer_id' => $owner->id,
            'payee_id' => $owner->id,
            'amount_minor' => 2000,
            'currency' => 'USD',
        ]);

        $response->assertUnprocessable()
            ->assertJsonPath('error.code', 'validation_failed');

        // Non member
        $stranger = User::factory()->create();
        $responseNonMember = $this->postJson("/api/v1/trips/{$trip->id}/settlements", [
            'payer_id' => $stranger->id,
            'payee_id' => $owner->id,
            'amount_minor' => 2000,
            'currency' => 'USD',
        ]);

        $responseNonMember->assertUnprocessable()
            ->assertJsonPath('error.code', 'validation_failed');
    }

    public function test_unauthorized_user_cannot_view_or_record_settlements(): void
    {
        $owner = User::factory()->create();
        $otherMember = User::factory()->create();
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        $stranger = User::factory()->create();
        Sanctum::actingAs($stranger);

        $this->getJson("/api/v1/trips/{$trip->id}/settlements")
            ->assertForbidden();

        $this->postJson("/api/v1/trips/{$trip->id}/settlements", [
            'payer_id' => $owner->id,
            'payee_id' => $otherMember->id,
            'amount_minor' => 1000,
            'currency' => 'USD',
        ])->assertForbidden();
    }
}
