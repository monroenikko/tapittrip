<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Trip;
use App\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TravelDocumentTest extends TestCase
{
    use DatabaseTransactions;

    public function test_owner_creates_encrypted_document_and_owner_only_policy_hides_it_from_circle_members(): void
    {
        $owner = User::factory()->create();
        $editor = User::factory()->create();
        $viewer = User::factory()->create();
        $outsider = User::factory()->create();

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

        $opId = (string) Str::uuid();
        Sanctum::actingAs($owner);

        $created = $this->postJson("/api/v1/trips/{$trip->id}/documents", [
            'document_type' => 'passport_note',
            'display_name' => 'Passport Renewal Reminder',
            'issuer' => 'DFA Philippines',
            'reference_number' => 'P-SECRET-9988',
            'notes_private' => 'Keep copy in carry-on pouch',
            'expires_on' => '2029-05-15',
            'access_policy' => 'owner_only',
            'client_operation_id' => $opId,
        ])
            ->assertCreated()
            ->assertJsonPath('data.display_name', 'Passport Renewal Reminder')
            ->assertJsonPath('data.reference_number', 'P-SECRET-9988')
            ->assertJsonPath('data.access_policy', 'owner_only')
            ->assertJsonPath('data.is_owner', true)
            ->json('data');

        // Verify reference_number and notes_private are encrypted at rest in PostgreSQL
        $raw = DB::table('travel_documents')->where('id', $created['id'])->first();
        $this->assertNotNull($raw);
        $this->assertNotSame('P-SECRET-9988', $raw->reference_number);
        $this->assertNotSame('Keep copy in carry-on pouch', $raw->notes_private);

        // Idempotent retry with same client_operation_id returns 200 without duplicating
        $this->postJson("/api/v1/trips/{$trip->id}/documents", [
            'document_type' => 'passport_note',
            'display_name' => 'Passport Renewal Reminder',
            'client_operation_id' => $opId,
        ])
            ->assertOk()
            ->assertJsonPath('data.id', $created['id']);

        // Editor and Viewer cannot see an owner_only document belonging to another user
        Sanctum::actingAs($editor);
        $this->getJson("/api/v1/trips/{$trip->id}/documents")
            ->assertOk()
            ->assertJsonCount(0, 'data');

        // Viewer cannot create documents
        Sanctum::actingAs($viewer);
        $this->postJson("/api/v1/trips/{$trip->id}/documents", [
            'document_type' => 'ticket_voucher',
            'display_name' => 'JR Pass Exchange Order',
        ])->assertForbidden();

        // Outsider is rejected
        Sanctum::actingAs($outsider);
        $this->getJson("/api/v1/trips/{$trip->id}/documents")->assertForbidden();
    }

    public function test_shared_circle_document_is_visible_to_members_with_reference_number_redacted_and_enforces_version_conflict(): void
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

        Sanctum::actingAs($owner);
        $doc = $this->postJson("/api/v1/trips/{$trip->id}/documents", [
            'document_type' => 'travel_insurance',
            'display_name' => 'Group Travel Insurance Policy',
            'issuer' => 'Pacific Cross',
            'reference_number' => 'POL-774411',
            'notes_private' => '24/7 hotline +63 2 8899',
            'expires_on' => '2027-01-10',
            'access_policy' => 'circle_members',
        ])
            ->assertCreated()
            ->json('data');

        // Editor can view the shared circle_members document, but reference_number is redacted
        Sanctum::actingAs($editor);
        $this->getJson("/api/v1/trips/{$trip->id}/documents")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $doc['id'])
            ->assertJsonPath('data.0.is_owner', false)
            ->assertJsonPath('data.0.reference_number', null)
            ->assertJsonPath('data.0.notes_private', '24/7 hotline +63 2 8899');

        // Editor cannot modify owner's document
        $this->patchJson("/api/v1/documents/{$doc['id']}", [
            'base_version' => 1,
            'display_name' => 'Tampered Policy',
        ])->assertForbidden();

        // Owner updates document and increments version; stale base_version returns 409 version_conflict
        Sanctum::actingAs($owner);
        $this->patchJson("/api/v1/documents/{$doc['id']}", [
            'base_version' => 1,
            'display_name' => 'Updated Group Insurance Policy',
        ])
            ->assertOk()
            ->assertJsonPath('data.version', 2)
            ->assertJsonPath('data.display_name', 'Updated Group Insurance Policy');

        $this->patchJson("/api/v1/documents/{$doc['id']}", [
            'base_version' => 1,
            'display_name' => 'Stale Update',
        ])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'version_conflict');

        $this->deleteJson("/api/v1/documents/{$doc['id']}")
            ->assertNoContent();
    }
}
