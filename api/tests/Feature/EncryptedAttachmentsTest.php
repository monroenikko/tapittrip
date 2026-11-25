<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\BookingImport;
use App\Models\TravelDocument;
use App\Models\Trip;
use App\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class EncryptedAttachmentsTest extends TestCase
{
    use DatabaseTransactions;

    public function test_travel_document_encrypts_uploaded_pdf_at_rest_streams_via_signed_url_and_blocks_companions(): void
    {
        Storage::fake('local');

        $owner = User::factory()->create();
        $editor = User::factory()->create();

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::query()->create([
            'trip_id' => $trip->id,
            'user_id' => $editor->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        Sanctum::actingAs($owner);

        $rawPdfBytes = "%PDF-1.4\n1 0 obj << /Title (Passport Secret Scan 9988) >> endobj\n%%EOF";
        $file = UploadedFile::fake()->createWithContent('passport_scan.pdf', $rawPdfBytes);

        $created = $this->post("/api/v1/trips/{$trip->id}/documents", [
            'document_type' => 'passport_note',
            'display_name' => 'Passport Bio Page Scan',
            'access_policy' => 'circle_members',
            'file' => $file,
        ], ['Accept' => 'application/json'])
            ->assertCreated()
            ->assertJsonPath('data.has_attachment', true)
            ->assertJsonPath('data.original_filename', 'passport_scan.pdf')
            ->assertJsonPath('data.mime_type', 'application/pdf')
            ->json('data');

        $this->assertNotEmpty($created['download_url']);

        // 1. Verify raw stored bytes on disk are encrypted (never plaintext PDF bytes)
        /** @var TravelDocument $doc */
        $doc = TravelDocument::query()->findOrFail($created['id']);
        $this->assertNotNull($doc->file_path);
        Storage::disk('local')->assertExists($doc->file_path);
        $storedOnDisk = (string) Storage::disk('local')->get($doc->file_path);
        $this->assertStringNotContainsString('Passport Secret Scan 9988', $storedOnDisk);

        // 2. Owner downloads decrypted PDF via the short-lived signed URL
        $downloadResp = $this->get($created['download_url']);
        $downloadResp
            ->assertOk()
            ->assertHeader('Content-Type', 'application/pdf')
            ->assertHeader('X-Content-Type-Options', 'nosniff');
        $this->assertSame($rawPdfBytes, $downloadResp->getContent());

        // 3. Unsigned download URL is rejected with 403
        $this->get("/api/v1/documents/{$doc->id}/download")->assertForbidden();

        // 4. Non-owner companion sees shared metadata summary, but download_url & filename are redacted and download is forbidden
        Sanctum::actingAs($editor);
        $this->getJson("/api/v1/trips/{$trip->id}/documents")
            ->assertOk()
            ->assertJsonPath('data.0.has_attachment', true)
            ->assertJsonPath('data.0.original_filename', null)
            ->assertJsonPath('data.0.download_url', null);

        $this->get($created['download_url'])->assertForbidden();

        // 5. Deleting the document deletes the encrypted file from disk
        Sanctum::actingAs($owner);
        $this->deleteJson("/api/v1/documents/{$doc->id}")->assertNoContent();
        Storage::disk('local')->assertMissing($doc->file_path);
    }

    public function test_travel_document_owner_can_attach_file_to_existing_document_and_invalid_mime_is_rejected(): void
    {
        Storage::fake('local');

        $owner = User::factory()->create();
        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);

        Sanctum::actingAs($owner);

        $doc = $this->postJson("/api/v1/trips/{$trip->id}/documents", [
            'document_type' => 'visa_reference',
            'display_name' => 'Japan eVisa Approval',
        ])->assertCreated()->json('data');

        // Reject executable / unsupported MIME type
        $badFile = UploadedFile::fake()->createWithContent('payload.sh', '#!/bin/sh\necho bad');
        $this->post("/api/v1/documents/{$doc['id']}/attachment", [
            'file' => $badFile,
        ], ['Accept' => 'application/json'])->assertUnprocessable();

        // Attach valid PNG image
        $pngFile = UploadedFile::fake()->image('evisa.png', 200, 200);
        $updated = $this->post("/api/v1/documents/{$doc['id']}/attachment", [
            'file' => $pngFile,
        ], ['Accept' => 'application/json'])
            ->assertOk()
            ->assertJsonPath('data.has_attachment', true)
            ->assertJsonPath('data.version', 2)
            ->json('data');

        $this->assertNotEmpty($updated['download_url']);
    }

    public function test_booking_import_supports_multipart_file_upload_encrypts_at_rest_and_redacts_for_companions(): void
    {
        Storage::fake('local');

        $owner = User::factory()->create();
        $editorA = User::factory()->create();
        $editorB = User::factory()->create();

        /** @var Trip $trip */
        $trip = Trip::factory()->create(['owner_id' => $owner->id]);
        TripMember::query()->create([
            'trip_id' => $trip->id,
            'user_id' => $editorA->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);
        TripMember::query()->create([
            'trip_id' => $trip->id,
            'user_id' => $editorB->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        Sanctum::actingAs($editorA);

        $rawPdf = "%PDF-1.4\nFlight PR 101 MNL -> NRT PNR: PR-PDF-777\n%%EOF";
        $file = UploadedFile::fake()->createWithContent('flight_eticket.pdf', $rawPdf);

        $created = $this->post("/api/v1/trips/{$trip->id}/imports", [
            'file' => $file,
            'booking_type' => 'flight',
        ], ['Accept' => 'application/json'])
            ->assertCreated()
            ->assertJsonPath('data.source', 'upload_file')
            ->assertJsonPath('data.has_attachment', true)
            ->assertJsonPath('data.original_filename', 'flight_eticket.pdf')
            ->json('data');

        $this->assertNotEmpty($created['download_url']);

        /** @var BookingImport $import */
        $import = BookingImport::query()->findOrFail($created['id']);
        $this->assertNotNull($import->file_path);
        Storage::disk('local')->assertExists($import->file_path);
        $this->assertStringNotContainsString('PR-PDF-777', (string) Storage::disk('local')->get($import->file_path));

        // Creator can download decrypted PDF
        $resp = $this->get($created['download_url']);
        $resp->assertOk();
        $this->assertSame($rawPdf, $resp->getContent());

        // Editor B (neither creator nor trip owner) gets redacted download_url & 403 on download
        Sanctum::actingAs($editorB);
        $this->getJson("/api/v1/imports/{$import->id}")
            ->assertOk()
            ->assertJsonPath('data.has_attachment', true)
            ->assertJsonPath('data.original_filename', null)
            ->assertJsonPath('data.download_url', null);

        $this->get($created['download_url'])->assertForbidden();

        // Trip owner can download the attachment
        Sanctum::actingAs($owner);
        $this->get($created['download_url'])->assertOk();
    }
}
