<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Checklist;
use App\Models\ChecklistItem;
use App\Models\ItineraryItem;
use App\Models\Stay;
use App\Models\SyncOperation;
use App\Models\Trip;
use App\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class SyncTest extends TestCase
{
    use DatabaseTransactions;

    public function test_push_applies_accepted_mutations_and_bumps_version(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create(['owner_id' => $user->id]);
        $checklist = Checklist::factory()->create(['trip_id' => $trip->id]);
        $item = ChecklistItem::factory()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $trip->id,
            'title' => 'Passport',
            'is_packed' => false,
            'version' => 1,
        ]);

        $opId = (string) Str::uuid();

        $response = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-test-1',
            'operations' => [
                [
                    'operation_id' => $opId,
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $item->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => [
                        'title' => 'Passport & Visa',
                        'is_packed' => true,
                    ],
                ],
            ],
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.results.0.operation_id', $opId)
            ->assertJsonPath('data.results.0.status', 'accepted')
            ->assertJsonPath('data.results.0.current_version', 2);

        $item->refresh();
        $this->assertSame('Passport & Visa', $item->title);
        $this->assertTrue($item->is_packed);
        $this->assertSame(2, $item->version);

        $this->assertDatabaseHas('sync_operations', [
            'operation_id' => $opId,
            'status' => 'accepted',
            'entity_type' => 'checklist_item',
            'entity_id' => $item->id,
        ]);
    }

    public function test_push_idempotency_returns_recorded_result_without_duplicate_processing(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create(['owner_id' => $user->id]);
        $checklist = Checklist::factory()->create(['trip_id' => $trip->id]);
        $item = ChecklistItem::factory()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $trip->id,
            'title' => 'Charger',
            'version' => 1,
        ]);

        $opId = (string) Str::uuid();

        $payload = [
            'device_key' => 'device-test-1',
            'operations' => [
                [
                    'operation_id' => $opId,
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $item->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => [
                        'title' => 'Fast Charger',
                    ],
                ],
            ],
        ];

        // First push
        $response1 = $this->postJson('/api/v1/sync/push', $payload);
        $response1->assertStatus(200)
            ->assertJsonPath('data.results.0.status', 'accepted');

        $item->refresh();
        $this->assertSame(2, $item->version);
        $this->assertSame('Fast Charger', $item->title);

        // Second push with same operation_id (retry / retransmission)
        $response2 = $this->postJson('/api/v1/sync/push', $payload);
        $response2->assertStatus(200)
            ->assertJsonPath('data.results.0.operation_id', $opId)
            ->assertJsonPath('data.results.0.status', 'accepted');

        // Verify version was NOT bumped again and title was not doubly processed
        $item->refresh();
        $this->assertSame(2, $item->version);

        $count = SyncOperation::where('operation_id', $opId)->count();
        $this->assertSame(1, $count);
    }

    public function test_push_detects_conflict_when_base_version_is_stale(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create(['owner_id' => $user->id]);
        $checklist = Checklist::factory()->create(['trip_id' => $trip->id]);
        $item = ChecklistItem::factory()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $trip->id,
            'title' => 'Sunscreen',
            'version' => 3, // Current server version is 3
        ]);

        $opId = (string) Str::uuid();

        // Client offline mutation based on stale version 1
        $response = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-test-offline',
            'operations' => [
                [
                    'operation_id' => $opId,
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $item->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => [
                        'title' => 'SPF 50 Sunscreen',
                    ],
                ],
            ],
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.results.0.operation_id', $opId)
            ->assertJsonPath('data.results.0.status', 'conflict')
            ->assertJsonPath('data.results.0.current_version', 3)
            ->assertJsonPath('data.results.0.conflict_details.server_version', 3);

        // Assert item was NOT overwritten
        $item->refresh();
        $this->assertSame('Sunscreen', $item->title);
        $this->assertSame(3, $item->version);
    }

    public function test_push_rejects_unauthorized_trip_operations(): void
    {
        $owner = User::factory()->create();
        $attacker = User::factory()->create();

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        $checklist = Checklist::factory()->create(['trip_id' => $trip->id]);
        $item = ChecklistItem::factory()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $trip->id,
            'title' => 'Private Item',
            'version' => 1,
        ]);

        Sanctum::actingAs($attacker);

        $opId = (string) Str::uuid();

        $response = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-attacker',
            'operations' => [
                [
                    'operation_id' => $opId,
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $item->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => [
                        'title' => 'Hacked Item',
                    ],
                ],
            ],
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.results.0.operation_id', $opId)
            ->assertJsonPath('data.results.0.status', 'rejected');

        $item->refresh();
        $this->assertSame('Private Item', $item->title);
    }

    public function test_pull_returns_changes_with_monotonic_cursor_and_tombstones(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create(['owner_id' => $user->id]);
        $checklist = Checklist::factory()->create(['trip_id' => $trip->id]);
        $item = ChecklistItem::factory()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $trip->id,
            'title' => 'Luggage Tag',
            'version' => 1,
        ]);

        // Push an update
        $op1 = (string) Str::uuid();
        $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-a',
            'operations' => [
                [
                    'operation_id' => $op1,
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $item->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => ['title' => 'Updated Luggage Tag'],
                ],
            ],
        ])->assertStatus(200);

        // Push a delete (tombstone)
        $op2 = (string) Str::uuid();
        $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-a',
            'operations' => [
                [
                    'operation_id' => $op2,
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $item->id,
                    'operation_type' => 'delete',
                    'base_version' => 2,
                ],
            ],
        ])->assertStatus(200);

        // Device B pulls from cursor 0
        $pullResponse = $this->getJson('/api/v1/sync/pull?device_key=device-b&cursor=0&trip_id='.$trip->id);

        $pullResponse->assertStatus(200)
            ->assertJsonPath('data.has_more', false);

        $data = $pullResponse->json('data');
        $this->assertCount(2, $data['operations']);
        $this->assertGreaterThan(0, $data['cursor']);

        // First operation is update, second is delete tombstone
        $this->assertSame('update', $data['operations'][0]['operation_type']);
        $this->assertSame('delete', $data['operations'][1]['operation_type']);

        // Pulling again with the updated cursor returns empty array
        $emptyPull = $this->getJson('/api/v1/sync/pull?device_key=device-b&cursor='.$data['cursor'].'&trip_id='.$trip->id);
        $emptyPull->assertStatus(200)
            ->assertJsonPath('data.operations', []);
    }

    public function test_push_rejects_unsupported_entity_type(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create(['owner_id' => $user->id]);
        $opId = (string) Str::uuid();

        $response = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-test-1',
            'operations' => [
                [
                    'operation_id' => $opId,
                    'trip_id' => $trip->id,
                    'entity_type' => 'unknown_satellite',
                    'entity_id' => (string) Str::uuid(),
                    'operation_type' => 'create',
                    'base_version' => 1,
                    'payload' => ['title' => 'Invalid'],
                ],
            ],
        ]);

        $response->assertUnprocessable()
            ->assertJsonPath('error.code', 'validation_failed');
        $this->assertArrayHasKey('operations.0.entity_type', $response->json('error.details.fields') ?? []);
    }

    public function test_push_rejects_nonexistent_item_update(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create(['owner_id' => $user->id]);
        $opId = (string) Str::uuid();
        $nonExistentId = (string) Str::uuid();

        $response = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-test-1',
            'operations' => [
                [
                    'operation_id' => $opId,
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $nonExistentId,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => ['title' => 'Ghost Item'],
                ],
            ],
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.results.0.operation_id', $opId)
            ->assertJsonPath('data.results.0.status', 'rejected')
            ->assertJsonPath('data.results.0.conflict_details.reason', 'Checklist item not found');
    }

    public function test_pull_fails_when_trip_does_not_exist(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $randomTripId = (string) Str::uuid();

        $response = $this->getJson("/api/v1/sync/pull?device_key=device-test&cursor=0&trip_id={$randomTripId}");

        $response->assertStatus(404);
    }

    public function test_pull_fails_when_user_is_not_a_member_of_the_trip(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($stranger);

        $response = $this->getJson("/api/v1/sync/pull?device_key=device-test&cursor=0&trip_id={$trip->id}");

        $response->assertStatus(403);
    }

    public function test_multi_device_concurrent_stay_and_itinerary_edits_detect_conflicts_and_resolve(): void
    {
        $owner = User::factory()->create();
        $editor = User::factory()->create();

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $editor->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Shinjuku Hotel',
            'stay_type' => 'hotel',
            'booking_reference' => 'SECRET-BK-99',
            'phone' => '+81-3-1111-2222',
            'version' => 1,
        ]);

        $itineraryItem = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'title' => 'Visit Senso-ji',
            'sort_order' => 0,
            'version' => 1,
        ]);

        // Device A (Owner) syncs online first, bumping both entities to v2
        Sanctum::actingAs($owner);
        $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-a',
            'operations' => [
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'stay',
                    'entity_id' => $stay->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => ['name' => 'Shinjuku Prince Hotel'],
                ],
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'itinerary_item',
                    'entity_id' => $itineraryItem->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => ['title' => 'Morning Walk at Senso-ji'],
                ],
            ],
        ])->assertOk()
            ->assertJsonPath('data.results.0.status', 'accepted')
            ->assertJsonPath('data.results.0.current_version', 2)
            ->assertJsonPath('data.results.1.status', 'accepted')
            ->assertJsonPath('data.results.1.current_version', 2);

        // Device B (Editor) comes back online with stale v1 edits
        Sanctum::actingAs($editor);
        $conflictResponse = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-b',
            'operations' => [
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'stay',
                    'entity_id' => $stay->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => ['name' => 'Shinjuku Boutique Inn'],
                ],
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'itinerary_item',
                    'entity_id' => $itineraryItem->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => ['title' => 'Afternoon Senso-ji Visit'],
                ],
            ],
        ]);

        $conflictResponse->assertOk()
            ->assertJsonPath('data.results.0.status', 'conflict')
            ->assertJsonPath('data.results.0.current_version', 2)
            ->assertJsonPath('data.results.0.conflict_details.server_version', 2)
            ->assertJsonPath('data.results.0.conflict_details.server_payload.name', 'Shinjuku Prince Hotel')
            ->assertJsonPath('data.results.0.conflict_details.server_payload.booking_reference', null)
            ->assertJsonPath('data.results.0.conflict_details.server_payload.phone', null)
            ->assertJsonPath('data.results.1.status', 'conflict')
            ->assertJsonPath('data.results.1.current_version', 2)
            ->assertJsonPath('data.results.1.conflict_details.server_payload.title', 'Morning Walk at Senso-ji');

        // Device B resolves both conflicts keeping local edits at base_version 2
        $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-b',
            'operations' => [
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'stay',
                    'entity_id' => $stay->id,
                    'operation_type' => 'update',
                    'base_version' => 2,
                    'payload' => ['name' => 'Shinjuku Boutique Inn'],
                ],
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'itinerary_item',
                    'entity_id' => $itineraryItem->id,
                    'operation_type' => 'update',
                    'base_version' => 2,
                    'payload' => ['title' => 'Afternoon Senso-ji Visit'],
                ],
            ],
        ])->assertOk()
            ->assertJsonPath('data.results.0.status', 'accepted')
            ->assertJsonPath('data.results.0.current_version', 3)
            ->assertJsonPath('data.results.1.status', 'accepted')
            ->assertJsonPath('data.results.1.current_version', 3);

        $stay->refresh();
        $itineraryItem->refresh();
        $this->assertSame('Shinjuku Boutique Inn', $stay->name);
        $this->assertSame(3, $stay->version);
        $this->assertSame('SECRET-BK-99', $stay->booking_reference);
        $this->assertSame('Afternoon Senso-ji Visit', $itineraryItem->title);
        $this->assertSame(3, $itineraryItem->version);
    }

    public function test_remote_delete_triggers_conflict_and_allows_offline_edit_restore_resolution(): void
    {
        $owner = User::factory()->create();
        Sanctum::actingAs($owner);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        $checklist = Checklist::factory()->create(['trip_id' => $trip->id]);
        $item = ChecklistItem::factory()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $trip->id,
            'title' => 'Universal Adapter',
            'version' => 1,
        ]);

        // Device A deletes the item while online (bumps version to 2 & soft-deletes)
        $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-a',
            'operations' => [
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $item->id,
                    'operation_type' => 'delete',
                    'base_version' => 1,
                ],
            ],
        ])->assertOk()
            ->assertJsonPath('data.results.0.status', 'accepted');

        // Device B reconnects with an offline update based on stale v1
        $conflictRes = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-b',
            'operations' => [
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $item->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => ['title' => 'Type-A/C Travel Adapter', 'is_packed' => true],
                ],
            ],
        ]);

        $conflictRes->assertOk()
            ->assertJsonPath('data.results.0.status', 'conflict')
            ->assertJsonPath('data.results.0.current_version', 2)
            ->assertJsonPath('data.results.0.conflict_details.server_version', 2)
            ->assertJsonPath('data.results.0.conflict_details.server_payload.deleted', true);

        // User on Device B chooses "Keep My Offline Edit" (base_version = 2)
        $resolveRes = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'device-b',
            'operations' => [
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $item->id,
                    'operation_type' => 'update',
                    'base_version' => 2,
                    'payload' => ['title' => 'Type-A/C Travel Adapter', 'is_packed' => true],
                ],
            ],
        ]);

        $resolveRes->assertOk()
            ->assertJsonPath('data.results.0.status', 'accepted')
            ->assertJsonPath('data.results.0.current_version', 3);

        $restored = ChecklistItem::find($item->id);
        $this->assertNotNull($restored);
        $this->assertFalse($restored->trashed());
        $this->assertSame('Type-A/C Travel Adapter', $restored->title);
        $this->assertTrue($restored->is_packed);
        $this->assertSame(3, $restored->version);
    }

    public function test_sync_sanitizes_sensitive_stay_fields_from_ledger_and_companion_pulls(): void
    {
        $owner = User::factory()->create();
        $companion = User::factory()->create();

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        $stayId = (string) Str::uuid();
        $opId = (string) Str::uuid();

        Sanctum::actingAs($owner);
        $this->postJson('/api/v1/sync/push', [
            'device_key' => 'owner-phone',
            'operations' => [
                [
                    'operation_id' => $opId,
                    'trip_id' => $trip->id,
                    'entity_type' => 'stay',
                    'entity_id' => $stayId,
                    'operation_type' => 'create',
                    'base_version' => 1,
                    'payload' => [
                        'name' => "Auntie May's Apartment",
                        'stay_type' => 'friends_family',
                        'address' => '42 Secret Lane, Kyoto',
                        'latitude' => 35.0116,
                        'longitude' => 135.7681,
                        'phone' => '+81-75-555-0199',
                        'booking_reference' => 'FAMILY-CODE-77',
                        'notes' => 'Key is under the planter',
                    ],
                ],
            ],
        ])->assertOk()
            ->assertJsonPath('data.results.0.status', 'accepted');

        // Verify ledger row does NOT persist booking_reference or phone in sync_operations.payload
        $ledgerRow = SyncOperation::where('operation_id', $opId)->firstOrFail();
        $this->assertArrayNotHasKey('booking_reference', $ledgerRow->payload ?? []);
        $this->assertArrayNotHasKey('phone', $ledgerRow->payload ?? []);

        // Companion pulls updates and must NOT see friends_family private address, coords, notes, phone, or booking ref
        Sanctum::actingAs($companion);
        $pullRes = $this->getJson("/api/v1/sync/pull?device_key=companion-phone&cursor=0&trip_id={$trip->id}");
        $pullRes->assertOk();

        $ops = collect($pullRes->json('data.operations'));
        $stayOp = $ops->firstWhere('operation_id', $opId);
        $this->assertNotNull($stayOp);
        $pulledPayload = $stayOp['payload'];
        $this->assertSame("Auntie May's Apartment", $pulledPayload['name']);
        $this->assertArrayNotHasKey('booking_reference', $pulledPayload);
        $this->assertArrayNotHasKey('phone', $pulledPayload);
        $this->assertArrayNotHasKey('address', $pulledPayload);
        $this->assertArrayNotHasKey('latitude', $pulledPayload);
        $this->assertArrayNotHasKey('longitude', $pulledPayload);
        $this->assertArrayNotHasKey('notes', $pulledPayload);
    }

    public function test_consecutive_offline_updates_in_single_batch_apply_without_self_conflict(): void
    {
        $owner = User::factory()->create();
        Sanctum::actingAs($owner);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        $stay = Stay::factory()->create([
            'trip_id' => $trip->id,
            'name' => 'Initial Lodge',
            'version' => 1,
        ]);

        $response = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'offline-tablet',
            'operations' => [
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'stay',
                    'entity_id' => $stay->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => ['name' => 'Updated Lodge'],
                ],
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'stay',
                    'entity_id' => $stay->id,
                    'operation_type' => 'update',
                    'base_version' => 2,
                    'payload' => ['notes' => 'Checked luggage policy', 'latitude' => 35.69, 'longitude' => 139.70],
                ],
            ],
        ]);

        $response->assertOk()
            ->assertJsonPath('data.results.0.status', 'accepted')
            ->assertJsonPath('data.results.0.current_version', 2)
            ->assertJsonPath('data.results.1.status', 'accepted')
            ->assertJsonPath('data.results.1.current_version', 3);

        $stay->refresh();
        $this->assertSame('Updated Lodge', $stay->name);
        $this->assertSame('Checked luggage policy', $stay->notes);
        $this->assertEquals(35.69, $stay->latitude);
        $this->assertEquals(139.70, $stay->longitude);
        $this->assertSame(3, $stay->version);
    }
}
