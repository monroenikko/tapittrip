<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Checklists\Models\Checklist;
use App\Domain\Checklists\Models\ChecklistItem;
use App\Domain\Media\Models\MediaAttachment;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class MediaAttachmentTest extends TestCase
{
    use DatabaseTransactions;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
    }

    public function test_user_can_upload_photo_and_document_to_trip_media_vault(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        $file = UploadedFile::fake()->image('flight_boarding_pass.jpg', 800, 600);

        $response = $this->postJson("/api/v1/trips/{$trip->id}/media", [
            'file' => $file,
            'title' => 'Flight Boarding Pass',
            'attachable_type' => 'trip_document',
            'notes' => 'Terminal 2, Gate 42',
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.title', 'Flight Boarding Pass')
            ->assertJsonPath('data.original_filename', 'flight_boarding_pass.jpg')
            ->assertJsonPath('data.mime_type', 'image/jpeg')
            ->assertJsonPath('data.is_image', true)
            ->assertJsonPath('data.is_pdf', false);

        $attachmentId = $response->json('data.id');
        $this->assertDatabaseHas('media_attachments', [
            'id' => $attachmentId,
            'trip_id' => $trip->id,
            'title' => 'Flight Boarding Pass',
        ]);

        // Verify file is on the fake storage disk
        /** @var MediaAttachment $media */
        $media = MediaAttachment::query()->findOrFail($attachmentId);
        Storage::disk('local')->assertExists($media->file_path);

        // Verify listed in vault
        $listResponse = $this->getJson("/api/v1/trips/{$trip->id}/media");
        $listResponse
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $attachmentId);
    }

    public function test_user_can_download_or_view_private_media_with_authorization(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        $file = UploadedFile::fake()->create('travel_insurance.pdf', 250, 'application/pdf');

        Sanctum::actingAs($owner);
        $upload = $this->postJson("/api/v1/trips/{$trip->id}/media", [
            'file' => $file,
            'title' => 'Travel Insurance Policy',
            'attachable_type' => 'trip_document',
        ]);
        $upload->assertCreated();
        $mediaId = $upload->json('data.id');

        // Owner can access the private file
        $viewResponse = $this->get("/api/v1/trips/{$trip->id}/media/{$mediaId}");
        $viewResponse->assertOk();
        $this->assertEquals('application/pdf', $viewResponse->headers->get('Content-Type'));

        // Stranger is blocked by trip membership policy
        Sanctum::actingAs($stranger);
        $this->get("/api/v1/trips/{$trip->id}/media/{$mediaId}")
            ->assertForbidden();

        $this->deleteJson("/api/v1/trips/{$trip->id}/media/{$mediaId}")
            ->assertForbidden();
    }

    public function test_user_can_upload_photo_directly_to_checklist_item(): void
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
            'title' => 'Japan Rail Pass Voucher',
            'photo_url' => null,
        ]);

        $photo = UploadedFile::fake()->image('jr_pass_receipt.png', 400, 400);

        $response = $this->postJson("/api/v1/checklist-items/{$item->id}/photo", [
            'file' => $photo,
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('data.id', $item->id);

        $item->refresh();
        $this->assertNotNull($item->photo_url);
        $this->assertStringContainsString("/api/v1/trips/{$trip->id}/media/", $item->photo_url);

        // Deleting media removes file and clears photo_url
        $media = MediaAttachment::query()->where('attachable_id', $item->id)->firstOrFail();
        $deleteResp = $this->deleteJson("/api/v1/trips/{$trip->id}/media/{$media->id}");
        $deleteResp->assertNoContent();

        $item->refresh();
        $this->assertNull($item->photo_url);
    }

    public function test_trip_stage_checklist_templates_include_departure_and_return(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $user->id]);

        // 1. Departure Day Checklist
        $depResp = $this->postJson("/api/v1/trips/{$trip->id}/checklists/apply-template", [
            'template' => 'departure_day',
        ]);

        $depResp
            ->assertCreated()
            ->assertJsonPath('data.title', 'Departure Day Checklist')
            ->assertJsonPath('data.type', 'departure')
            ->assertJsonPath('data.total_items_count', 6);

        // 2. Return Trip Checklist
        $retResp = $this->postJson("/api/v1/trips/{$trip->id}/checklists/apply-template", [
            'template' => 'return_trip',
        ]);

        $retResp
            ->assertCreated()
            ->assertJsonPath('data.title', 'Return Trip Checklist')
            ->assertJsonPath('data.type', 'return')
            ->assertJsonPath('data.total_items_count', 6);
    }
}
