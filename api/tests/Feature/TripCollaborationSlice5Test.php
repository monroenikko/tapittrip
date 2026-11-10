<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Contracts\ExchangeRateProviderInterface;
use App\Models\Expense;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\TripBudget;
use App\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripCollaborationSlice5Test extends TestCase
{
    use DatabaseTransactions;

    public function test_tc7_1_payer_selected_and_custom_splits_with_exact_minor_rounding_and_validation(): void
    {
        $alice = User::factory()->create(['name' => 'Alice', 'home_currency' => 'USD']);
        $bob = User::factory()->create(['name' => 'Bob', 'home_currency' => 'USD']);
        $charlie = User::factory()->create(['name' => 'Charlie', 'home_currency' => 'USD']);
        $outsider = User::factory()->create(['name' => 'Outsider']);

        $trip = Trip::factory()->create(['owner_id' => $alice->id, 'destination_country' => 'US']);
        TripBudget::factory()->create(['trip_id' => $trip->id, 'currency' => 'USD', 'total_budget_minor' => 200000]);

        $bobMembership = TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $bob->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $charlie->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);

        $otherTrip = Trip::factory()->create(['owner_id' => $outsider->id]);
        $foreignStay = Stay::factory()->create(['trip_id' => $otherTrip->id]);

        Sanctum::actingAs($bob);

        // Reject cross-trip stay_id, outsider payer, outsider participant, and invalid custom sum
        $this->postJson("/api/v1/trips/{$trip->id}/expenses", [
            'payer_id' => $outsider->id,
            'category' => 'dining',
            'title' => 'Invalid Payer',
            'amount_minor' => 1000,
            'currency' => 'USD',
            'expense_date' => '2026-11-10',
            'split_type' => 'equal',
        ])->assertUnprocessable()->assertJsonPath('error.code', 'validation_failed');

        $this->postJson("/api/v1/trips/{$trip->id}/expenses", [
            'category' => 'dining',
            'title' => 'Cross-trip Stay Link',
            'amount_minor' => 1000,
            'currency' => 'USD',
            'expense_date' => '2026-11-10',
            'stay_id' => $foreignStay->id,
            'split_type' => 'equal',
        ])->assertUnprocessable();

        $this->postJson("/api/v1/trips/{$trip->id}/expenses", [
            'category' => 'dining',
            'title' => 'Bad Custom Sum',
            'amount_minor' => 1000,
            'currency' => 'USD',
            'expense_date' => '2026-11-10',
            'split_type' => 'custom',
            'splits' => [
                ['user_id' => $alice->id, 'amount_minor' => 500],
                ['user_id' => $bob->id, 'amount_minor' => 400],
            ],
        ])->assertUnprocessable();

        $this->postJson("/api/v1/trips/{$trip->id}/expenses", [
            'category' => 'dining',
            'title' => 'Non-Member Participant',
            'amount_minor' => 1000,
            'currency' => 'USD',
            'expense_date' => '2026-11-10',
            'split_type' => 'selected',
            'participant_ids' => [$bob->id, $outsider->id],
        ])->assertUnprocessable();

        // Valid selected-traveler split ($10.01 across Bob & Charlie, paid by Bob) -> 501 + 500
        $selectedRes = $this->postJson("/api/v1/trips/{$trip->id}/expenses", [
            'payer_id' => $bob->id,
            'category' => 'transport',
            'title' => 'Train Tickets',
            'amount_minor' => 1001,
            'currency' => 'USD',
            'expense_date' => '2026-11-10',
            'split_type' => 'selected',
            'participant_ids' => [$bob->id, $charlie->id],
        ]);

        $selectedRes->assertCreated()
            ->assertJsonPath('data.split_type', 'selected')
            ->assertJsonPath('data.visibility', 'shared');

        $selectedSplits = collect($selectedRes->json('data.splits'));
        $this->assertSame(1001, $selectedSplits->sum('amount_minor'));
        $this->assertSame(501, $selectedSplits->firstWhere('user_id', $bob->id)['amount_minor']);
        $this->assertSame(500, $selectedSplits->firstWhere('user_id', $charlie->id)['amount_minor']);

        // Balances: Bob gets back +500, Charlie owes -500, Alice 0
        $balances = collect($this->getJson("/api/v1/trips/{$trip->id}/settlements")->json('data.balances'));
        $this->assertSame(0, $balances->firstWhere('user_id', $alice->id)['net_balance_minor']);
        $this->assertSame(500, $balances->firstWhere('user_id', $bob->id)['net_balance_minor']);
        $this->assertSame(-500, $balances->firstWhere('user_id', $charlie->id)['net_balance_minor']);
        $this->assertArrayNotHasKey('email', $balances->firstWhere('user_id', $alice->id));

        // Update custom split with exact base_amount_minor proportional rounding (JPY 3000 -> 2027 USD cents)
        $expId = $selectedRes->json('data.id');
        $updateRes = $this->patchJson("/api/v1/expenses/{$expId}", [
            'amount_minor' => 3000,
            'currency' => 'JPY',
            'exchange_rate' => 0.006755, // 3000 * 0.006755 = 20.265 -> 2027 USD cents
            'split_type' => 'custom',
            'splits' => [
                ['user_id' => $alice->id, 'amount_minor' => 2000],
                ['user_id' => $charlie->id, 'amount_minor' => 1000],
            ],
            'base_version' => 1,
        ]);

        $updateRes->assertOk()
            ->assertJsonPath('data.version', 2)
            ->assertJsonPath('data.base_amount_minor', 2027);

        $updatedSplits = collect($updateRes->json('data.splits'));
        $this->assertSame(2027, $updatedSplits->sum('base_amount_minor'));

        // Stale base_version returns 409 version_conflict
        $this->patchJson("/api/v1/expenses/{$expId}", [
            'title' => 'Stale Rename',
            'base_version' => 1,
        ])->assertStatus(409)->assertJsonPath('error.code', 'version_conflict');

        // Viewer cannot edit shared expenses
        Sanctum::actingAs($charlie);
        $this->patchJson("/api/v1/expenses/{$expId}", [
            'title' => 'Viewer Override Attempt',
        ])->assertForbidden();
        $this->assertSame($bob->id, $bobMembership->user_id);
    }

    public function test_tc7_2_multi_currency_attributed_snapshots_unavailable_handling_and_immutable_history(): void
    {
        $alice = User::factory()->create(['name' => 'Alice', 'home_currency' => 'USD']);
        $bob = User::factory()->create(['name' => 'Bob', 'home_currency' => 'USD']);
        $trip = Trip::factory()->create(['owner_id' => $alice->id, 'destination_country' => 'JP']);
        TripBudget::factory()->create(['trip_id' => $trip->id, 'currency' => 'USD', 'total_budget_minor' => 100000]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $bob->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        // Bind a failing exchange-rate provider (returns null -> never invents 1.0)
        $this->app->instance(ExchangeRateProviderInterface::class, new class implements ExchangeRateProviderInterface
        {
            public function getRate(string $fromCurrency, string $toCurrency): ?float
            {
                return null;
            }

            public function getRatesForBase(string $baseCurrency): array
            {
                return [];
            }
        });

        Sanctum::actingAs($alice);

        // Live rate endpoint reports 503 exchange_rate_unavailable rather than inventing a rate
        $this->getJson('/api/v1/currencies/rates?from=JPY&to=USD')
            ->assertStatus(503)
            ->assertJsonPath('error.code', 'exchange_rate_unavailable');

        // Foreign expense created without rate while provider unavailable stores conversion_status = unavailable
        $unavailableRes = $this->postJson("/api/v1/trips/{$trip->id}/expenses", [
            'category' => 'dining',
            'title' => 'Offline Ramen Bar',
            'amount_minor' => 4000,
            'currency' => 'JPY',
            'expense_date' => '2026-11-10',
            'split_type' => 'equal',
        ]);

        $unavailableRes->assertCreated()
            ->assertJsonPath('data.conversion_status', 'unavailable')
            ->assertJsonPath('data.rate_source', 'unavailable')
            ->assertJsonPath('data.exchange_rate', null)
            ->assertJsonPath('data.base_amount_minor', null);

        // Log a converted foreign expense with explicit attributed dated snapshot (2000 JPY @ 0.007 = $14.00 USD)
        $convertedRes = $this->postJson("/api/v1/trips/{$trip->id}/expenses", [
            'category' => 'activities',
            'title' => 'TeamLab Entry',
            'amount_minor' => 2000,
            'currency' => 'JPY',
            'exchange_rate' => 0.007,
            'rate_source' => 'cached_snapshot',
            'rate_captured_at' => '2026-11-10T09:00:00Z',
            'expense_date' => '2026-11-10',
            'split_type' => 'equal',
        ]);

        $convertedRes->assertCreated()
            ->assertJsonPath('data.conversion_status', 'converted')
            ->assertJsonPath('data.rate_source', 'cached_snapshot')
            ->assertJsonPath('data.base_amount_minor', 1400);

        // Settlements & Summary exclude unconverted JPY from USD balances and expose unconverted list + per_currency_balances
        $summaryRes = $this->getJson("/api/v1/trips/{$trip->id}/expenses/summary")->assertOk();
        $summaryRes->assertJsonPath('data.total_spent_base_minor', 1400)
            ->assertJsonPath('data.unconverted_expenses_count', 1)
            ->assertJsonPath('data.unconverted_totals.0.currency', 'JPY')
            ->assertJsonPath('data.unconverted_totals.0.amount_minor', 4000);

        $settlementsRes = $this->getJson("/api/v1/trips/{$trip->id}/settlements")->assertOk();
        $balances = collect($settlementsRes->json('data.balances'));
        $this->assertSame(700, $balances->firstWhere('user_id', $alice->id)['net_balance_minor']);
        $this->assertSame(-700, $balances->firstWhere('user_id', $bob->id)['net_balance_minor']);
        $this->assertCount(1, $settlementsRes->json('data.unconverted_expenses'));
        $this->assertSame('Offline Ramen Bar', $settlementsRes->json('data.unconverted_expenses.0.title'));
        $this->assertArrayHasKey('JPY', $settlementsRes->json('data.per_currency_balances'));

        // Settlement in foreign currency without rate rejects (422), with snapshot converts cleanly (1000 JPY @ 0.007 = $7.00)
        $this->postJson("/api/v1/trips/{$trip->id}/settlements", [
            'payer_id' => $bob->id,
            'payee_id' => $alice->id,
            'amount_minor' => 1000,
            'currency' => 'JPY',
        ])->assertUnprocessable();

        $this->postJson("/api/v1/trips/{$trip->id}/settlements", [
            'payer_id' => $bob->id,
            'payee_id' => $alice->id,
            'amount_minor' => 1000,
            'currency' => 'JPY',
            'exchange_rate' => 0.007,
            'rate_source' => 'user_manual',
            'notes' => 'Cash yen equivalent',
        ])->assertCreated()->assertJsonPath('data.base_amount_minor', 700);

        $afterSettle = $this->getJson("/api/v1/trips/{$trip->id}/settlements")->assertOk();
        $this->assertSame([], $afterSettle->json('data.suggested_settlements'));

        // Changing trip budget currency later never mutates historical snapped base_amount_minor on already logged expense
        $this->putJson("/api/v1/trips/{$trip->id}/budget", [
            'currency' => 'EUR',
            'total_budget_minor' => 90000,
        ])->assertOk();

        $refetchedExpense = $this->getJson('/api/v1/expenses/'.$convertedRes->json('data.id'))->assertOk();
        $this->assertSame(1400, $refetchedExpense->json('data.base_amount_minor'));
    }

    public function test_tc7_3_personal_privacy_offline_sync_idempotency_and_member_departure(): void
    {
        $alice = User::factory()->create(['name' => 'Alice', 'home_currency' => 'USD']);
        $bob = User::factory()->create(['name' => 'Bob', 'home_currency' => 'USD']);
        $charlie = User::factory()->create(['name' => 'Charlie', 'home_currency' => 'USD']);

        $trip = Trip::factory()->create(['owner_id' => $alice->id, 'destination_country' => 'US']);
        TripBudget::factory()->create(['trip_id' => $trip->id, 'currency' => 'USD', 'total_budget_minor' => 100000]);

        $bobMembership = TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $bob->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $charlie->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);

        // 1. Alice creates a personal ("single") expense -> private by default
        Sanctum::actingAs($alice);
        $privateOpId = (string) Str::uuid();
        $privateRes = $this->postJson("/api/v1/trips/{$trip->id}/expenses", [
            'category' => 'shopping',
            'title' => 'Private Birthday Gift',
            'amount_minor' => 5000,
            'currency' => 'USD',
            'expense_date' => '2026-11-10',
            'split_type' => 'single',
            'client_operation_id' => $privateOpId,
        ])->assertCreated()
            ->assertJsonPath('data.visibility', 'private');

        // Retrying same client_operation_id is idempotent
        $retryRes = $this->postJson("/api/v1/trips/{$trip->id}/expenses", [
            'category' => 'shopping',
            'title' => 'Private Birthday Gift',
            'amount_minor' => 5000,
            'currency' => 'USD',
            'expense_date' => '2026-11-10',
            'split_type' => 'single',
            'client_operation_id' => $privateOpId,
        ])->assertCreated();
        $this->assertSame($privateRes->json('data.id'), $retryRes->json('data.id'));

        $privateId = $privateRes->json('data.id');

        // Bob (even as editor!) & Charlie cannot read, edit, delete, or see Alice's private expense in summary/today/settlements
        Sanctum::actingAs($bob);
        $this->getJson("/api/v1/trips/{$trip->id}/expenses")->assertOk()->assertJsonCount(0, 'data');
        $this->getJson("/api/v1/expenses/{$privateId}")->assertForbidden();
        $this->patchJson("/api/v1/expenses/{$privateId}", ['title' => 'Snooped'])->assertForbidden();
        $this->deleteJson("/api/v1/expenses/{$privateId}")->assertForbidden();
        $this->getJson("/api/v1/trips/{$trip->id}/expenses/summary")
            ->assertOk()
            ->assertJsonPath('data.total_spent_base_minor', 0)
            ->assertJsonPath('data.expenses_count', 0);
        $this->getJson("/api/v1/trips/{$trip->id}/today")
            ->assertOk()
            ->assertJsonPath('data.budget_pacing.total_spent_minor', 0);

        // 2. Offline Sync Push: Alice pushes a private expense + a shared expense; Bob's pull omits Alice's private expense!
        Sanctum::actingAs($alice);
        $offlinePrivateUuid = (string) Str::uuid();
        $offlineSharedUuid = (string) Str::uuid();
        $syncPushRes = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'alice-phone',
            'operations' => [
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'expense',
                    'entity_id' => $offlinePrivateUuid,
                    'operation_type' => 'create',
                    'base_version' => 1,
                    'payload' => [
                        'category' => 'other',
                        'title' => 'Offline Secret Item',
                        'amount_minor' => 2500,
                        'currency' => 'USD',
                        'expense_date' => '2026-11-10',
                        'split_type' => 'single',
                    ],
                ],
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'expense',
                    'entity_id' => $offlineSharedUuid,
                    'operation_type' => 'create',
                    'base_version' => 1,
                    'payload' => [
                        'payer_id' => $alice->id,
                        'category' => 'dining',
                        'title' => 'Shared Airport Shuttle',
                        'amount_minor' => 9000,
                        'currency' => 'USD',
                        'expense_date' => '2026-11-10',
                        'split_type' => 'equal',
                    ],
                ],
            ],
        ])->assertOk();
        $this->assertSame('accepted', $syncPushRes->json('data.results.0.status'));
        $this->assertSame('accepted', $syncPushRes->json('data.results.1.status'));

        // Bob pulls sync operations -> only receives Shared Airport Shuttle, NEVER Offline Secret Item
        Sanctum::actingAs($bob);
        $pullRes = $this->getJson("/api/v1/sync/pull?trip_id={$trip->id}&cursor=0&device_key=bob-phone")->assertOk();
        $pulledIds = collect($pullRes->json('data.operations'))->pluck('entity_id')->all();
        $this->assertContains($offlineSharedUuid, $pulledIds);
        $this->assertNotContains($offlinePrivateUuid, $pulledIds);

        // Alice edits shared shuttle to v2 first, then Bob pushes stale base_version 1 -> sync reports conflict
        Sanctum::actingAs($alice);
        $this->patchJson("/api/v1/expenses/{$offlineSharedUuid}", [
            'title' => 'Shared Limousine Bus',
            'base_version' => 1,
        ])->assertOk()->assertJsonPath('data.version', 2);

        Sanctum::actingAs($bob);
        $conflictPush = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'bob-phone',
            'operations' => [
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'expense',
                    'entity_id' => $offlineSharedUuid,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => ['title' => 'Stale Edit'],
                ],
            ],
        ])->assertOk();
        $this->assertSame('conflict', $conflictPush->json('data.results.0.status'));

        Sanctum::actingAs($charlie);
        $viewerPush = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'charlie-phone',
            'operations' => [
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'expense',
                    'entity_id' => $offlineSharedUuid,
                    'operation_type' => 'delete',
                    'base_version' => 1,
                ],
            ],
        ])->assertOk();
        $this->assertSame('rejected', $viewerPush->json('data.results.0.status'));

        // 3. Settlement retry idempotency + non-transfer disclaimer
        Sanctum::actingAs($alice);
        $settleOpId = (string) Str::uuid();
        $this->postJson("/api/v1/trips/{$trip->id}/settlements", [
            'payer_id' => $bob->id,
            'payee_id' => $alice->id,
            'amount_minor' => 1500,
            'currency' => 'USD',
            'client_operation_id' => $settleOpId,
        ])->assertCreated();
        $this->postJson("/api/v1/trips/{$trip->id}/settlements", [
            'payer_id' => $bob->id,
            'payee_id' => $alice->id,
            'amount_minor' => 1500,
            'currency' => 'USD',
            'client_operation_id' => $settleOpId,
        ])->assertCreated();

        $settlementPayload = $this->getJson("/api/v1/trips/{$trip->id}/settlements")->assertOk();
        $this->assertCount(1, $settlementPayload->json('data.settlement_history'));
        $this->assertStringContainsString('does not transfer funds', strtolower((string) $settlementPayload->json('data.accounting_notice')));

        // 4. Member departure preserves auditable ledger balances while revoking access and blocking new splits
        $this->deleteJson("/api/v1/trips/{$trip->id}/members/{$bobMembership->id}")->assertNoContent();

        $postDepartureBalances = $this->getJson("/api/v1/trips/{$trip->id}/settlements")->assertOk();
        $bobAfter = collect($postDepartureBalances->json('data.balances'))->firstWhere('user_id', $bob->id);
        $this->assertNotNull($bobAfter);
        $this->assertTrue($bobAfter['is_departed']);
        $this->assertSame(-1500, $bobAfter['net_balance_minor']); // -3000 split + 1500 settlement retained

        $this->postJson("/api/v1/trips/{$trip->id}/expenses", [
            'category' => 'dining',
            'title' => 'Post-Departure Split Attempt',
            'amount_minor' => 2000,
            'currency' => 'USD',
            'expense_date' => '2026-11-10',
            'split_type' => 'selected',
            'participant_ids' => [$alice->id, $bob->id],
        ])->assertUnprocessable();

        Sanctum::actingAs($bob);
        $this->getJson("/api/v1/trips/{$trip->id}/expenses")->assertForbidden();
        $this->assertSame(Expense::withTrashed()->find($offlinePrivateUuid)?->visibility, 'private');
    }
}
