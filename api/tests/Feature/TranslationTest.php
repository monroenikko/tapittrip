<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Trip;
use App\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class TranslationTest extends TestCase
{
    use DatabaseTransactions;

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $this->getJson('/api/v1/translation/languages')->assertUnauthorized();
        $this->getJson('/api/v1/translation/phrasebook/ja')->assertUnauthorized();
        $this->postJson('/api/v1/translation/translate', [
            'text' => 'Thank you',
            'target_language' => 'ja',
            'consent_cloud' => false,
        ])->assertUnauthorized();
    }

    public function test_can_list_languages_and_filter_curated_phrasebook(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson('/api/v1/translation/languages')
            ->assertOk()
            ->assertJsonFragment([
                'language_code' => 'ja',
                'language_name' => 'Japanese',
                'country_code' => 'JP',
            ]);

        $dining = $this->getJson('/api/v1/translation/phrasebook/Japan?category=dining')
            ->assertOk()
            ->assertJsonPath('data.language_code', 'ja')
            ->json('data.phrases');

        $this->assertNotEmpty($dining);
        foreach ($dining as $phrase) {
            $this->assertSame('dining', $phrase['category']);
        }
    }

    public function test_trip_phrasebook_supports_all_four_planning_modes_and_enforces_membership(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $outsider = User::factory()->create();

        foreach (['diy', 'existing', 'guided', 'simple'] as $mode) {
            $trip = Trip::factory()->create([
                'owner_id' => $owner->id,
                'destination_country' => 'South Korea',
                'planning_mode' => $mode,
            ]);

            TripMember::factory()->create([
                'trip_id' => $trip->id,
                'user_id' => $viewer->id,
                'role' => 'viewer',
                'invitation_status' => 'accepted',
            ]);

            Sanctum::actingAs($owner);
            $this->getJson("/api/v1/trips/{$trip->id}/phrasebook")
                ->assertOk()
                ->assertJsonPath('data.language_code', 'ko')
                ->assertJsonPath('data.country_code', 'KR');

            Sanctum::actingAs($viewer);
            $this->getJson("/api/v1/trips/{$trip->id}/phrasebook?language=tl")
                ->assertOk()
                ->assertJsonPath('data.language_code', 'tl')
                ->assertJsonPath('data.country_code', 'PH');

            Sanctum::actingAs($outsider);
            $this->getJson("/api/v1/trips/{$trip->id}/phrasebook")
                ->assertForbidden();
        }
    }

    public function test_translate_uses_offline_phrasebook_first_and_requires_cloud_consent_for_custom_text(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // 1. Offline phrasebook match succeeds even when consent_cloud = false
        $this->postJson('/api/v1/translation/translate', [
            'text' => 'I have a food allergy.',
            'target_language' => 'ja',
            'consent_cloud' => false,
        ])
            ->assertOk()
            ->assertJsonPath('data.is_offline_match', true)
            ->assertJsonPath('data.provider', 'offline_phrasebook')
            ->assertJsonPath('data.translated_text', '食物アレルギーがあります。');

        // 2. Custom phrase NOT in offline phrasebook is rejected with 422 cloud_consent_required when consent_cloud = false
        $this->postJson('/api/v1/translation/translate', [
            'text' => 'No peanuts please',
            'target_language' => 'ja',
            'consent_cloud' => false,
        ])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'cloud_consent_required');

        // 3. With consent_cloud = true, delegates to deterministic translation provider
        $this->postJson('/api/v1/translation/translate', [
            'text' => 'No peanuts please',
            'target_language' => 'ja',
            'consent_cloud' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.is_offline_match', false)
            ->assertJsonPath('data.provider', 'deterministic_test_adapter')
            ->assertJsonPath('data.translated_text', 'ピーナッツは入れないでください。');

        // 4. Provider unavailability returns honest 503 translation_unavailable
        $this->postJson('/api/v1/translation/translate', [
            'text' => '[unavailable]',
            'target_language' => 'ja',
            'consent_cloud' => true,
        ])
            ->assertStatus(503)
            ->assertJsonPath('error.code', 'translation_unavailable');
    }
}
