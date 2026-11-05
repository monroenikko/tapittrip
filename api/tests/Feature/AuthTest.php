<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class AuthTest extends TestCase
{
    use DatabaseTransactions;

    public function test_user_can_register_with_valid_details(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'John Doe',
            'email' => 'john.doe@example.com',
            'password' => 'secret-pass-123',
            'device_name' => 'pixel-test',
            'home_timezone' => 'Asia/Tokyo',
        ]);

        $response
            ->assertCreated()
            ->assertJsonStructure([
                'data' => [
                    'token',
                    'token_type',
                    'user' => [
                        'id',
                        'name',
                        'display_name',
                        'email',
                        'avatar_url',
                        'locale',
                        'home_timezone',
                        'created_at',
                        'updated_at',
                    ],
                ],
            ]);

        $this->assertSame('Bearer', $response->json('data.token_type'));
        $this->assertSame('John Doe', $response->json('data.user.name'));
        $this->assertSame('john.doe@example.com', $response->json('data.user.email'));
        $this->assertSame('Asia/Tokyo', $response->json('data.user.home_timezone'));

        $this->assertDatabaseHas('users', [
            'email' => 'john.doe@example.com',
            'name' => 'John Doe',
            'home_timezone' => 'Asia/Tokyo',
        ]);

        $user = User::query()->where('email', 'john.doe@example.com')->firstOrFail();
        $this->assertTrue(Hash::check('secret-pass-123', (string) $user->password));
    }

    public function test_user_cannot_register_with_duplicate_email(): void
    {
        User::factory()->create([
            'email' => 'existing@example.com',
        ]);

        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Another User',
            'email' => 'existing@example.com',
            'password' => 'new-secret-123',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'validation_failed')
            ->assertJsonPath('error.details.fields.email.0', 'The email has already been taken.');
    }

    public function test_register_validation_fails_with_invalid_data(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => '',
            'email' => 'not-an-email',
            'password' => 'short',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'validation_failed')
            ->assertJsonStructure([
                'error' => [
                    'code',
                    'message',
                    'details' => [
                        'fields' => [
                            'name',
                            'email',
                            'password',
                        ],
                    ],
                ],
            ]);
    }

    public function test_user_can_login_with_valid_credentials(): void
    {
        $user = User::factory()->create([
            'email' => 'traveler@example.com',
            'password' => Hash::make('secret-pass-123'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'traveler@example.com',
            'password' => 'secret-pass-123',
            'device_name' => 'iphone-test',
        ]);

        $response
            ->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'token',
                    'token_type',
                    'user' => [
                        'id',
                        'name',
                        'display_name',
                        'email',
                        'avatar_url',
                        'locale',
                        'home_timezone',
                        'created_at',
                        'updated_at',
                    ],
                ],
            ]);

        $this->assertSame('Bearer', $response->json('data.token_type'));
        $this->assertSame($user->id, $response->json('data.user.id'));
    }

    public function test_auth_token_alias_remains_available(): void
    {
        $user = User::factory()->create([
            'email' => 'traveler@example.com',
            'password' => Hash::make('secret-pass-123'),
        ]);

        $response = $this->postJson('/api/v1/auth/token', [
            'email' => 'traveler@example.com',
            'password' => 'secret-pass-123',
            'device_name' => 'legacy-client',
        ]);

        $response->assertOk();
        $this->assertSame('Bearer', $response->json('data.token_type'));
        $this->assertSame($user->id, $response->json('data.user.id'));
    }

    public function test_user_cannot_login_with_invalid_credentials(): void
    {
        User::factory()->create([
            'email' => 'traveler@example.com',
            'password' => Hash::make('secret-pass-123'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'traveler@example.com',
            'password' => 'wrong-password',
        ]);

        $response
            ->assertUnprocessable()
            ->assertExactJson([
                'error' => [
                    'code' => 'invalid_credentials',
                    'message' => 'The provided credentials are incorrect.',
                ],
            ]);
    }

    public function test_login_request_validation_uses_standard_error_envelope(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'not-an-email',
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'validation_failed')
            ->assertJsonPath('error.message', 'The given data was invalid.')
            ->assertJsonStructure([
                'error' => [
                    'code',
                    'message',
                    'details' => [
                        'fields' => ['email', 'password'],
                    ],
                ],
            ]);
    }

    public function test_authenticated_user_can_view_profile(): void
    {
        $user = User::factory()->create([
            'display_name' => 'Solo Wanderer',
            'locale' => 'en',
            'home_timezone' => 'America/New_York',
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/me');

        $response
            ->assertOk()
            ->assertJson([
                'data' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'display_name' => 'Solo Wanderer',
                    'email' => $user->email,
                    'locale' => 'en',
                    'home_timezone' => 'America/New_York',
                ],
            ]);
    }

    public function test_unauthenticated_request_to_me_is_rejected(): void
    {
        $response = $this->getJson('/api/v1/me');

        $response
            ->assertUnauthorized()
            ->assertExactJson([
                'error' => [
                    'code' => 'unauthenticated',
                    'message' => 'Authentication is required.',
                ],
            ]);
    }

    public function test_authenticated_user_can_logout(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('logout-device');

        $response = $this->withHeader('Authorization', 'Bearer '.$token->plainTextToken)
            ->postJson('/api/v1/auth/logout');

        $response->assertNoContent();
        $this->assertDatabaseMissing('personal_access_tokens', [
            'id' => $token->accessToken->id,
        ]);
    }

    public function test_authenticated_user_can_delete_account(): void
    {
        $user = User::factory()->create();
        $token1 = $user->createToken('device-1');
        $token2 = $user->createToken('device-2');

        Sanctum::actingAs($user);

        $response = $this->deleteJson('/api/v1/me');

        $response->assertNoContent();

        $this->assertSoftDeleted('users', [
            'id' => $user->id,
        ]);

        $this->assertDatabaseMissing('personal_access_tokens', [
            'id' => $token1->accessToken->id,
        ]);
        $this->assertDatabaseMissing('personal_access_tokens', [
            'id' => $token2->accessToken->id,
        ]);
    }
}
