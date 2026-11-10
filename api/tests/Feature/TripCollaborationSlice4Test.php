<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Checklist;
use App\Models\ChecklistItem;
use App\Models\ItineraryItem;
use App\Models\Trip;
use App\Models\TripMember;
use App\Models\TripTraveler;
use App\Models\User;
use App\Models\VisitEvent;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TripCollaborationSlice4Test extends TestCase
{
    use DatabaseTransactions;

    public function test_tc6_1_assign_checklist_items_to_member_or_traveler_and_clear_on_removal(): void
    {
        $owner = User::factory()->create(['display_name' => 'Owner Maya']);
        $editor = User::factory()->create(['display_name' => 'Editor Nia']);
        $viewer = User::factory()->create(['display_name' => 'Viewer Kai']);
        $outsider = User::factory()->create();

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        $otherTrip = Trip::factory()->create(['owner_id' => $outsider->id]);

        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $editor->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);
        $viewerMember = TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $viewer->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);

        $checklist = Checklist::factory()->create(['trip_id' => $trip->id]);
        $otherTraveler = TripTraveler::factory()->create([
            'trip_id' => $otherTrip->id,
            'managing_user_id' => $outsider->id,
            'display_name' => 'Other Child',
        ]);

        Sanctum::actingAs($owner);
        $travelerRes = $this->postJson("/api/v1/trips/{$trip->id}/travelers", [
            'display_name' => 'Leo',
            'traveler_category' => 'child',
            'restricted_notes' => 'Peanut allergy',
        ]);
        $travelerRes->assertCreated()->assertJsonPath('data.display_name', 'Leo');
        $leoId = (string) $travelerRes->json('data.id');

        // Reject assigning both user & traveler, non-member user, or cross-trip traveler
        $this->postJson("/api/v1/checklists/{$checklist->id}/items", [
            'title' => 'Invalid Both',
            'assigned_user_id' => $viewer->id,
            'assigned_traveler_id' => $leoId,
        ])->assertStatus(422);

        $this->postJson("/api/v1/checklists/{$checklist->id}/items", [
            'title' => 'Invalid NonMember',
            'assigned_user_id' => $outsider->id,
        ])->assertStatus(422);

        $this->postJson("/api/v1/checklists/{$checklist->id}/items", [
            'title' => 'Invalid CrossTrip',
            'assigned_traveler_id' => $otherTraveler->id,
        ])->assertStatus(422);

        // Assign item 1 to viewer member and item 2 to managed traveler Leo
        $itemViewerRes = $this->postJson("/api/v1/checklists/{$checklist->id}/items", [
            'title' => 'Bring Rain Jacket',
            'category' => 'clothing',
            'assigned_user_id' => $viewer->id,
        ]);
        $itemViewerRes->assertCreated()
            ->assertJsonPath('data.assigned_user_id', $viewer->id)
            ->assertJsonPath('data.assigned_user_name', 'Viewer Kai');
        $itemViewerId = (string) $itemViewerRes->json('data.id');

        Sanctum::actingAs($editor);
        $itemTravelerRes = $this->postJson("/api/v1/checklists/{$checklist->id}/items", [
            'title' => 'Pack Kids Floaties',
            'category' => 'gear',
            'assigned_traveler_id' => $leoId,
        ]);
        $itemTravelerRes->assertCreated()
            ->assertJsonPath('data.assigned_traveler_id', $leoId)
            ->assertJsonPath('data.assigned_traveler_name', 'Leo')
            ->assertJsonPath('data.assigned_traveler_category', 'child');
        $itemTravelerId = (string) $itemTravelerRes->json('data.id');

        // Deleting managed traveler clears assigned_traveler_id without orphaning task
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/v1/travelers/{$leoId}")->assertNoContent();
        $this->assertNull(ChecklistItem::findOrFail($itemTravelerId)->assigned_traveler_id);

        // Removing member clears assigned_user_id without orphaning task
        $this->deleteJson("/api/v1/trips/{$trip->id}/members/{$viewerMember->id}")->assertNoContent();
        $this->assertNull(ChecklistItem::findOrFail($itemViewerId)->assigned_user_id);
    }

    public function test_tc6_2_viewer_personal_completion_isolation_offline_sync_and_conflict(): void
    {
        $owner = User::factory()->create();
        $editor = User::factory()->create(['display_name' => 'Editor Nia']);
        $viewer = User::factory()->create(['display_name' => 'Viewer Kai']);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $editor->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $viewer->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);

        $itineraryItem = ItineraryItem::factory()->create([
            'trip_id' => $trip->id,
            'status' => 'planned',
        ]);

        $checklist = Checklist::factory()->create(['trip_id' => $trip->id]);
        $assignedToViewer = ChecklistItem::factory()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $trip->id,
            'assigned_user_id' => $viewer->id,
            'title' => 'Passport',
            'is_packed' => false,
            'version' => 1,
        ]);
        $unassigned = ChecklistItem::factory()->create([
            'checklist_id' => $checklist->id,
            'trip_id' => $trip->id,
            'assigned_user_id' => null,
            'title' => 'First Aid Kit',
            'is_packed' => false,
            'version' => 1,
        ]);

        // Viewer toggles completion on own assigned item -> 200, tracks completed_by_user_id, never touches itinerary visit status
        Sanctum::actingAs($viewer);
        $this->postJson("/api/v1/checklist-items/{$assignedToViewer->id}/toggle", [
            'base_version' => 1,
        ])
            ->assertOk()
            ->assertJsonPath('data.is_packed', true)
            ->assertJsonPath('data.completed_by_user_id', $viewer->id)
            ->assertJsonPath('data.version', 2);

        $this->assertSame('planned', $itineraryItem->fresh()->status);
        $this->assertSame(0, VisitEvent::where('itinerary_item_id', $itineraryItem->id)->count());

        // Viewer CANNOT edit title, delete, or toggle unassigned/other items (TC-6.2)
        $this->patchJson("/api/v1/checklist-items/{$assignedToViewer->id}", [
            'title' => 'Hacked Title',
        ])->assertForbidden();
        $this->deleteJson("/api/v1/checklist-items/{$assignedToViewer->id}")->assertForbidden();
        $this->postJson("/api/v1/checklist-items/{$unassigned->id}/toggle")->assertForbidden();

        // Stale base_version toggle returns 409 version_conflict
        $this->postJson("/api/v1/checklist-items/{$assignedToViewer->id}/toggle", [
            'base_version' => 1,
        ])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'version_conflict')
            ->assertJsonPath('error.details.server_version', 2);

        // Offline sync: viewer can push is_packed on assigned item; rejected on title edit or unassigned item
        $syncRes = $this->postJson('/api/v1/sync/push', [
            'device_key' => 'viewer-phone',
            'operations' => [
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $assignedToViewer->id,
                    'operation_type' => 'update',
                    'base_version' => 2,
                    'payload' => ['is_packed' => false],
                ],
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $assignedToViewer->id,
                    'operation_type' => 'update',
                    'base_version' => 3,
                    'payload' => ['title' => 'Unauthorized Rename'],
                ],
                [
                    'operation_id' => (string) Str::uuid(),
                    'trip_id' => $trip->id,
                    'entity_type' => 'checklist_item',
                    'entity_id' => $unassigned->id,
                    'operation_type' => 'update',
                    'base_version' => 1,
                    'payload' => ['is_packed' => true],
                ],
            ],
        ]);

        $syncRes->assertOk()
            ->assertJsonPath('data.results.0.status', 'accepted')
            ->assertJsonPath('data.results.1.status', 'rejected')
            ->assertJsonPath('data.results.2.status', 'rejected');

        $this->assertFalse($assignedToViewer->fresh()->is_packed);
        $this->assertNull($assignedToViewer->fresh()->completed_by_user_id);
        $this->assertFalse($unassigned->fresh()->is_packed);
    }

    public function test_tc6_3_managed_traveler_lifecycle_and_restricted_notes_isolation(): void
    {
        $owner = User::factory()->create(['display_name' => 'Owner Maya']);
        $editor = User::factory()->create(['display_name' => 'Parent Nia']);
        $viewer = User::factory()->create(['display_name' => 'Viewer Kai']);

        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $editor->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);
        TripMember::factory()->create([
            'trip_id' => $trip->id,
            'user_id' => $viewer->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);

        // Viewer cannot create a managed traveler profile
        Sanctum::actingAs($viewer);
        $this->postJson("/api/v1/trips/{$trip->id}/travelers", [
            'display_name' => 'Unauthorized Child',
            'traveler_category' => 'child',
        ])->assertForbidden();

        // Editor Nia creates Baby Sam with private restricted_notes (encrypted at rest)
        Sanctum::actingAs($editor);
        $createRes = $this->postJson("/api/v1/trips/{$trip->id}/travelers", [
            'display_name' => 'Baby Sam',
            'traveler_category' => 'infant',
            'restricted_notes' => 'Requires hypoallergenic formula',
        ]);
        $createRes->assertCreated()
            ->assertJsonPath('data.display_name', 'Baby Sam')
            ->assertJsonPath('data.restricted_notes', 'Requires hypoallergenic formula')
            ->assertJsonPath('data.can_edit', true);

        $samId = (string) $createRes->json('data.id');
        $rawNotes = DB::table('trip_travelers')->where('id', $samId)->value('restricted_notes');
        $this->assertNotSame('Requires hypoallergenic formula', $rawNotes);

        // Other members (even trip owner!) cannot see restricted_notes or edit Baby Sam's profile
        Sanctum::actingAs($owner);
        $ownerList = $this->getJson("/api/v1/trips/{$trip->id}/travelers");
        $ownerList->assertOk()
            ->assertJsonPath('data.0.display_name', 'Baby Sam')
            ->assertJsonPath('data.0.restricted_notes', null)
            ->assertJsonPath('data.0.can_edit', false);

        $this->patchJson("/api/v1/travelers/{$samId}", [
            'display_name' => 'Tampered Name',
        ])->assertForbidden();

        // Managing parent updates cleanly and gets 409 on stale base_version
        Sanctum::actingAs($editor);
        $this->patchJson("/api/v1/travelers/{$samId}", [
            'display_name' => 'Toddler Sam',
            'base_version' => 1,
        ])->assertOk()->assertJsonPath('data.version', 2);

        $this->patchJson("/api/v1/travelers/{$samId}", [
            'display_name' => 'Stale Update',
            'base_version' => 1,
        ])->assertStatus(409);

        // Removing managing adult cleans up their managed traveler profile automatically
        Sanctum::actingAs($owner);
        $editorMember = TripMember::where('trip_id', $trip->id)->where('user_id', $editor->id)->firstOrFail();
        $this->deleteJson("/api/v1/trips/{$trip->id}/members/{$editorMember->id}")->assertNoContent();
        $this->assertSoftDeleted('trip_travelers', ['id' => $samId]);
    }
}
