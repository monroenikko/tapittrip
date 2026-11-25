<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\DTOs\Itinerary\GenerateAiItineraryData;
use App\DTOs\Stays\CompareStayTransportData;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\TripMember;
use App\Models\User;
use App\Services\Imports\FakeBookingExtractor;
use App\Services\Imports\GeminiBookingExtractor;
use App\Services\Itinerary\GeminiItineraryService;
use App\Services\Stays\GeminiTransitService;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class SecurityAndPrivacyAuditTest extends TestCase
{
    use DatabaseTransactions;

    public function test_booking_import_encrypts_raw_text_and_extracted_data_at_rest_redacts_for_companions_and_guards_mutations(): void
    {
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

        // Editor A creates a flight booking import containing a secret PNR
        Sanctum::actingAs($editorA);
        $rawText = "Philippine Airlines Flight Confirmation\nBooking Reference: PR-SECRET999\nFlight PR 101\nRoute: MNL -> NRT\nDate: 2027-04-10T08:00:00Z";

        $created = $this->postJson("/api/v1/trips/{$trip->id}/imports", [
            'raw_text' => $rawText,
            'booking_type' => 'flight',
        ])
            ->assertCreated()
            ->assertJsonPath('data.raw_text', $rawText)
            ->assertJsonPath('data.extracted_data.flight.booking_reference', 'PR-SECRET999')
            ->json('data');

        // 1. Verify BOTH raw_text and extracted_data are encrypted at rest in PostgreSQL
        $dbRow = DB::table('booking_imports')->where('id', $created['id'])->first();
        $this->assertNotNull($dbRow);
        $this->assertNotSame($rawText, $dbRow->raw_text);
        $this->assertStringNotContainsString('PR-SECRET999', (string) $dbRow->raw_text);
        $this->assertStringNotContainsString('PR-SECRET999', (string) $dbRow->extracted_data);

        // 2. Editor B (companion who is neither the import creator nor trip owner) sees redacted raw_text & booking_reference
        Sanctum::actingAs($editorB);
        $this->getJson("/api/v1/imports/{$created['id']}")
            ->assertOk()
            ->assertJsonPath('data.raw_text', null)
            ->assertJsonPath('data.extracted_data.flight.booking_reference', null);

        // 3. Editor B cannot confirm or delete Editor A's booking import
        $this->postJson("/api/v1/imports/{$created['id']}/confirm", [
            'base_version' => 1,
            'booking_type' => 'flight',
            'flight' => $created['extracted_data']['flight'],
        ])->assertForbidden();

        $this->deleteJson("/api/v1/imports/{$created['id']}")->assertForbidden();

        // 4. Trip Owner CAN view and confirm/manage imports in their trip
        Sanctum::actingAs($owner);
        $this->getJson("/api/v1/imports/{$created['id']}")
            ->assertOk()
            ->assertJsonPath('data.raw_text', $rawText)
            ->assertJsonPath('data.extracted_data.flight.booking_reference', 'PR-SECRET999');
    }

    public function test_friends_family_stay_redacts_private_address_across_transport_comparison_today_summary_and_assistant(): void
    {
        $owner = User::factory()->create();
        $companion = User::factory()->create();

        /** @var Trip $trip */
        $trip = Trip::factory()->create([
            'owner_id' => $owner->id,
            'title' => 'Tokyo Visit',
            'destination_country' => 'JP',
        ]);

        TripMember::query()->create([
            'trip_id' => $trip->id,
            'user_id' => $companion->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        /** @var Stay $stay */
        $stay = Stay::query()->create([
            'trip_id' => $trip->id,
            'name' => 'Auntie May Residence',
            'stay_type' => 'friends_family',
            'address' => '42 Secret Host Lane, Shibuya 902',
            'latitude' => 35.6595,
            'longitude' => 139.7004,
            'phone' => '+81-90-5555-9999',
            'booking_reference' => 'HOST-PRIVATE-77',
            'notes' => 'Door code 9988',
            'timezone' => 'Asia/Tokyo',
        ]);

        Sanctum::actingAs($companion);

        // 1. Stay transport options endpoint must not leak private host address, directions URL, or transit proximity
        $transportResp = $this->postJson("/api/v1/stays/{$stay->id}/transport-options", [
            'luggage_preset' => 'light',
        ]);
        $transportResp
            ->assertOk()
            ->assertJsonPath('data.verified', false)
            ->assertJsonPath('data.google_maps_directions_url', null)
            ->assertJsonPath('data.nearest_transit', null)
            ->assertJsonCount(0, 'data.options');
        $this->assertStringNotContainsString('42 Secret Host Lane', $transportResp->getContent());
        $this->assertStringNotContainsString('35.6595', $transportResp->getContent());

        // 2. Today dashboard endpoint must redact private stay address, coordinates, phone, booking_reference, and notes
        $todayResp = $this->getJson("/api/v1/trips/{$trip->id}/today");
        $todayResp
            ->assertOk()
            ->assertJsonPath('data.current_stay.name', 'Auntie May Residence')
            ->assertJsonPath('data.current_stay.address', null)
            ->assertJsonPath('data.current_stay.latitude', null)
            ->assertJsonPath('data.current_stay.longitude', null)
            ->assertJsonPath('data.current_stay.phone', null)
            ->assertJsonPath('data.current_stay.booking_reference', null)
            ->assertJsonPath('data.current_stay.notes', null)
            ->assertJsonPath('data.current_stay.google_maps_url', null)
            ->assertJsonPath('data.current_stay.google_maps_directions_url', null);

        // 3. Trip assistant dining query must not leak private friends_family address in reply or action payload
        $assistantResp = $this->postJson("/api/v1/trips/{$trip->id}/assistant/query", [
            'query' => 'Where should we eat dinner near our hotel stay?',
        ]);
        $assistantResp->assertOk();
        $this->assertStringNotContainsString('42 Secret Host Lane', $assistantResp->getContent());
        $this->assertStringNotContainsString('Door code 9988', $assistantResp->getContent());
    }

    public function test_gemini_providers_never_log_api_keys_raw_response_bodies_or_sensitive_prompts_on_failure(): void
    {
        config()->set('services.gemini.api_key', 'AIzaSy-TOP-SECRET-GEMINI-KEY-999');

        Http::fake([
            '*generativelanguage.googleapis.com*' => Http::response(
                'RAW_PROVIDER_BODY_WITH_SECRET_PNR_PR-SECRET999_AND_KEY',
                500,
            ),
        ]);

        $loggedMessages = [];
        Log::listen(function ($logEntry) use (&$loggedMessages): void {
            $loggedMessages[] = $logEntry->message.' '.json_encode($logEntry->context);
        });

        /** @var Trip $trip */
        $trip = Trip::factory()->create([
            'title' => 'Tokyo Security Audit',
            'destination_country' => 'JP',
        ]);
        /** @var Stay $stay */
        $stay = Stay::query()->create([
            'trip_id' => $trip->id,
            'name' => 'Private Host Stay',
            'stay_type' => 'friends_family',
            'address' => '99 Confidential Street',
            'timezone' => 'Asia/Tokyo',
        ]);

        // 1. Trigger GeminiBookingExtractor failure
        $extractor = new GeminiBookingExtractor(app(FakeBookingExtractor::class));
        $extractor->extract("Flight PR 101\nPNR: PR-SECRET999\nMNL -> NRT\n2027-04-10T08:00:00Z", 'flight');

        // 2. Trigger GeminiTransitService failure
        $transit = new GeminiTransitService;
        $transit->getLiveTransportOptions(
            $stay,
            CompareStayTransportData::from(['luggage_preset' => 'light']),
            ['nearest_airport_name' => 'Narita', 'nearest_airport_code' => 'NRT', 'station_name' => 'Shibuya'],
            'Narita (NRT)',
            'JPY',
            false,
        );

        // 3. Trigger GeminiItineraryService failure
        $itinerary = new GeminiItineraryService;
        $itinerary->generatePlan(
            $trip,
            GenerateAiItineraryData::fromArray(['destination' => 'Tokyo', 'duration_days' => 2]),
            'Tokyo',
            2,
            'JPY',
            false,
        );

        $this->assertNotEmpty($loggedMessages);
        $combinedLogs = implode("\n", $loggedMessages);
        $this->assertStringNotContainsString('AIzaSy-TOP-SECRET-GEMINI-KEY-999', $combinedLogs);
        $this->assertStringNotContainsString('RAW_PROVIDER_BODY_WITH_SECRET_PNR', $combinedLogs);
        $this->assertStringNotContainsString('PR-SECRET999', $combinedLogs);
        $this->assertStringNotContainsString('99 Confidential Street', $combinedLogs);
    }
}
