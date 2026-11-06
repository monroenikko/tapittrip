<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Checklists\Models\Checklist;
use App\Domain\Checklists\Models\ChecklistItem;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class ChecklistTest extends TestCase
{
    use DatabaseTransactions;

    public function test_user_can_list_and_create_checklists_for_trip(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $payload = [
            'title' => 'Japan Spring Packing List',
            'type' => 'packing',
            'description' => 'Luggage and gear for Tokyo and Kyoto.',
        ];

        $response = $this->postJson("/api/v1/trips/{$trip->id}/checklists", $payload);

        $response
            ->assertCreated()
            ->assertJsonPath('data.title', 'Japan Spring Packing List')
            ->assertJsonPath('data.type', 'packing')
            ->assertJsonPath('data.total_items_count', 0)
            ->assertJsonPath('data.progress_percentage', 0);

        $this->assertDatabaseHas('checklists', [
            'trip_id' => $trip->id,
            'title' => 'Japan Spring Packing List',
        ]);

        $listResponse = $this->getJson("/api/v1/trips/{$trip->id}/checklists");
        $listResponse
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Japan Spring Packing List');
    }

    public function test_user_can_apply_starter_templates_one_tap(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        // 1. Apply International Essentials template
        $response = $this->postJson("/api/v1/trips/{$trip->id}/checklists/apply-template", [
            'template' => 'international_essentials',
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.title', 'International Essentials')
            ->assertJsonPath('data.total_items_count', 10)
            ->assertJsonPath('data.packed_items_count', 0)
            ->assertJsonPath('data.progress_percentage', 0);

        $this->assertDatabaseHas('checklist_items', [
            'trip_id' => $trip->id,
            'title' => 'Passport & Visa Copies',
            'category' => 'documents',
        ]);

        // 2. Apply All Essentials template
        $allResp = $this->postJson("/api/v1/trips/{$trip->id}/checklists/apply-template", [
            'template' => 'all_essentials',
        ]);

        $allResp
            ->assertCreated()
            ->assertJsonPath('data.title', 'Trip Packing Essentials');

        // Should have merged count: 10 + 7 + 7 + 7 = 31 items
        $this->assertEquals(31, $allResp->json('data.total_items_count'));
    }

    public function test_user_can_add_update_and_toggle_checklist_items(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        /** @var Checklist $checklist */
        $checklist = Checklist::factory()->create([
            'trip_id' => $trip->id,
            'title' => 'Tech & Gadgets',
        ]);

        // 1. Add item
        $addResponse = $this->postJson("/api/v1/checklists/{$checklist->id}/items", [
            'title' => 'Sony Noise Cancelling Headphones',
            'category' => 'electronics',
            'quantity' => 1,
            'notes' => 'Don\'t forget airplane adapter cable',
        ]);

        $addResponse
            ->assertCreated()
            ->assertJsonPath('data.title', 'Sony Noise Cancelling Headphones')
            ->assertJsonPath('data.category', 'electronics')
            ->assertJsonPath('data.is_packed', false)
            ->assertJsonPath('data.quantity', 1);

        $itemId = $addResponse->json('data.id');

        // 2. Toggle packed status
        $toggle1 = $this->postJson("/api/v1/checklist-items/{$itemId}/toggle");
        $toggle1
            ->assertOk()
            ->assertJsonPath('data.is_packed', true)
            ->assertJsonPath('data.version', 2);

        $this->assertNotNull($toggle1->json('data.packed_at'));

        // Check checklist progress calculation
        $showChecklist = $this->getJson("/api/v1/checklists/{$checklist->id}");
        $showChecklist
            ->assertOk()
            ->assertJsonPath('data.total_items_count', 1)
            ->assertJsonPath('data.packed_items_count', 1)
            ->assertJsonPath('data.progress_percentage', 100);

        // 3. Toggle back
        $toggle2 = $this->postJson("/api/v1/checklist-items/{$itemId}/toggle");
        $toggle2
            ->assertOk()
            ->assertJsonPath('data.is_packed', false)
            ->assertJsonPath('data.packed_at', null)
            ->assertJsonPath('data.version', 3);

        // 4. Update item details
        $updateResponse = $this->patchJson("/api/v1/checklist-items/{$itemId}", [
            'title' => 'Sony WH-1000XM5 Headphones',
            'quantity' => 2,
            'notes' => 'Pack in carry-on bag.',
        ]);

        $updateResponse
            ->assertOk()
            ->assertJsonPath('data.title', 'Sony WH-1000XM5 Headphones')
            ->assertJsonPath('data.quantity', 2)
            ->assertJsonPath('data.notes', 'Pack in carry-on bag.');
    }

    public function test_user_can_delete_checklist_items_and_checklists(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        /** @var Checklist $checklist */
        $checklist = Checklist::factory()->create(['trip_id' => $trip->id]);

        /** @var ChecklistItem $item */
        $item = ChecklistItem::factory()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $trip->id,
            'title' => 'Toothbrush',
        ]);

        // Delete item
        $this->deleteJson("/api/v1/checklist-items/{$item->id}")
            ->assertNoContent();

        $this->assertDatabaseMissing('checklist_items', ['id' => $item->id]);

        // Delete checklist
        $this->deleteJson("/api/v1/checklists/{$checklist->id}")
            ->assertNoContent();

        $this->assertDatabaseMissing('checklists', ['id' => $checklist->id]);
    }

    public function test_authorization_isolation_non_members_cannot_access_or_modify_checklists(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        /** @var Checklist $checklist */
        $checklist = Checklist::factory()->create(['trip_id' => $trip->id]);

        /** @var ChecklistItem $item */
        $item = ChecklistItem::factory()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $trip->id,
        ]);

        Sanctum::actingAs($stranger);

        // Attempt listing checklists
        $this->getJson("/api/v1/trips/{$trip->id}/checklists")
            ->assertForbidden();

        // Attempt creating checklist
        $this->postJson("/api/v1/trips/{$trip->id}/checklists", ['title' => 'Hacked List'])
            ->assertForbidden();

        // Attempt applying template
        $this->postJson("/api/v1/trips/{$trip->id}/checklists/apply-template", ['template' => 'international_essentials'])
            ->assertForbidden();

        // Attempt viewing checklist
        $this->getJson("/api/v1/checklists/{$checklist->id}")
            ->assertForbidden();

        // Attempt toggling item
        $this->postJson("/api/v1/checklist-items/{$item->id}/toggle")
            ->assertForbidden();

        // Attempt updating item
        $this->patchJson("/api/v1/checklist-items/{$item->id}", ['title' => 'Malicious Update'])
            ->assertForbidden();

        // Attempt deleting item
        $this->deleteJson("/api/v1/checklist-items/{$item->id}")
            ->assertForbidden();

        // Attempt deleting checklist
        $this->deleteJson("/api/v1/checklists/{$checklist->id}")
            ->assertForbidden();
    }
}
