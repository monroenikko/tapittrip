<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\User;
use App\Services\Identity\LiveOAuthTokenVerifier;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

final class OAuthExchangeTest extends TestCase
{
    use DatabaseTransactions;

    public function test_google_oauth_exchange_creates_new_user_and_reuses_identity_on_repeat_sign_in(): void
    {
        $first = $this->postJson('/api/v1/auth/google/exchange', [
            'id_token' => 'valid-google-token:google-sub-1001|maria.traveler@example.com|Maria Cruz',
            'device_name' => 'iPhone 16 Pro',
            'locale' => 'en',
            'home_timezone' => 'Asia/Manila',
        ]);

        $first
            ->assertCreated()
            ->assertJsonPath('data.token_type', 'Bearer')
            ->assertJsonPath('data.is_new_user', true)
            ->assertJsonPath('data.user.email', 'maria.traveler@example.com')
            ->assertJsonPath('data.user.display_name', 'Maria Cruz');

        $userId = $first->json('data.user.id');
        $this->assertNotEmpty($first->json('data.token'));

        $this->assertDatabaseHas('user_oauth_identities', [
            'user_id' => $userId,
            'provider' => 'google',
            'provider_subject' => 'google-sub-1001',
            'email' => 'maria.traveler@example.com',
            'email_verified' => true,
        ]);

        // Second exchange with same Google subject returns 200 and same user
        $second = $this->postJson('/api/v1/auth/google/exchange', [
            'id_token' => 'valid-google-token:google-sub-1001|maria.traveler@example.com|Maria Cruz',
        ]);

        $second
            ->assertOk()
            ->assertJsonPath('data.is_new_user', false)
            ->assertJsonPath('data.user.id', $userId);
    }

    public function test_verified_apple_email_links_to_existing_account_while_unverified_email_is_blocked(): void
    {
        /** @var User $existing */
        $existing = User::factory()->create([
            'email' => 'existing.user@example.com',
        ]);

        // Unverified OAuth email must NEVER auto-link to an existing password account
        $this->postJson('/api/v1/auth/google/exchange', [
            'id_token' => 'unverified-google-token:google-sub-unv|existing.user@example.com|Spoofed User',
        ])->assertStatus(422);

        // Verified Apple email links cleanly to existing user
        $linked = $this->postJson('/api/v1/auth/apple/exchange', [
            'id_token' => 'valid-apple-token:apple-sub-777|existing.user@example.com|Existing User',
        ]);

        $linked
            ->assertOk()
            ->assertJsonPath('data.is_new_user', false)
            ->assertJsonPath('data.user.id', $existing->id);

        $this->assertDatabaseHas('user_oauth_identities', [
            'user_id' => $existing->id,
            'provider' => 'apple',
            'provider_subject' => 'apple-sub-777',
        ]);
    }

    public function test_invalid_token_and_unsupported_provider_are_rejected(): void
    {
        $this->postJson('/api/v1/auth/google/exchange', [
            'id_token' => 'invalid-garbage-token-value',
        ])->assertStatus(422);

        $this->postJson('/api/v1/auth/facebook/exchange', [
            'id_token' => 'valid-facebook-token:fb-1|user@example.com|User',
        ])->assertUnprocessable();
    }

    public function test_live_google_verifier_validates_audience_and_rejects_mismatched_aud(): void
    {
        config()->set('services.google.oauth_client_id', 'tapittrip-google-client-id.apps.googleusercontent.com');

        Http::fake([
            'https://oauth2.googleapis.com/tokeninfo*' => Http::sequence()
                ->push([
                    'aud' => 'tapittrip-google-client-id.apps.googleusercontent.com',
                    'sub' => 'google-live-sub-42',
                    'email' => 'live@example.com',
                    'email_verified' => 'true',
                    'name' => 'Live Traveler',
                ], 200)
                ->push([
                    'aud' => 'wrong-other-app-client-id',
                    'sub' => 'google-live-sub-99',
                    'email' => 'attacker@example.com',
                    'email_verified' => 'true',
                ], 200),
        ]);

        $verifier = new LiveOAuthTokenVerifier;

        $valid = $verifier->verify('google', 'mock-google-jwt-token');
        $this->assertNotNull($valid);
        $this->assertSame('google-live-sub-42', $valid->providerSubject);
        $this->assertTrue($valid->emailVerified);

        $wrongAud = $verifier->verify('google', 'mock-wrong-aud-jwt-token');
        $this->assertNull($wrongAud);
    }
}
