<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Checklists\Models\Checklist;
use App\Domain\Checklists\Models\ChecklistItem;
use App\Domain\Sync\Models\SyncOperation;
use App\Domain\Trips\Models\Trip;
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
}
