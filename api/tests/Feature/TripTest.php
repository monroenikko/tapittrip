<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Domain\Trips\Actions\CreateTrip;
use App\Domain\Trips\Data\CreateTripData;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

final class TripTest extends TestCase
{
    use DatabaseTransactions;

    /**
     * @return array<string, array<int, string>>
     */
    public static function planningModesProvider(): array
    {
        return [
            'DIY planning mode' => ['diy'],
            'Already booked mode' => ['existing'],
            'Guided tour mode' => ['guided'],
            'Simple organization mode' => ['simple'],
        ];
    }

    #[DataProvider('planningModesProvider')]
    public function test_user_can_create_trip_in_all_four_planning_modes(string $mode): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $payload = [
            'title' => "My {$mode} Vacation",
            'start_date' => '2026-12-01',
            'end_date' => '2026-12-10',
            'primary_timezone' => 'Asia/Tokyo',
            'origin_country' => 'PH',
            'destination_country' => 'JP',
            'trip_type' => 'leisure',
            'planning_mode' => $mode,
        ];

        $response = $this->postJson('/api/v1/trips', $payload);

        $response
            ->assertCreated()
            ->assertJson([
                'data' => [
                    'title' => "My {$mode} Vacation",
                    'owner_id' => $user->id,
                    'start_date' => '2026-12-01',
                    'end_date' => '2026-12-10',
                    'primary_timezone' => 'Asia/Tokyo',
                    'origin_country' => 'PH',
                    'destination_country' => 'JP',
                    'trip_type' => 'leisure',
                    'planning_mode' => $mode,
                    'status' => 'planned',
                    'version' => 1,
                    'role' => 'owner',
                ],
            ]);

        $tripId = $response->json('data.id');

        $this->assertDatabaseHas('trips', [
            'id' => $tripId,
            'owner_id' => $user->id,
            'planning_mode' => $mode,
        ]);

        $this->assertDatabaseHas('trip_members', [
            'trip_id' => $tripId,
            'user_id' => $user->id,
            'role' => 'owner',
        ]);
    }

    public function test_trip_creation_validates_required_fields_and_date_ordering(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // Missing title
        $response = $this->postJson('/api/v1/trips', []);
        $response
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'validation_failed')
            ->assertJsonStructure(['error' => ['details' => ['fields' => ['title']]]]);

        // End date before start date
        $response = $this->postJson('/api/v1/trips', [
            'title' => 'Invalid Dates Trip',
            'start_date' => '2026-12-10',
            'end_date' => '2026-12-01',
        ]);
        $response
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'validation_failed')
            ->assertJsonStructure(['error' => ['details' => ['fields' => ['end_date']]]]);
    }

    public function test_user_can_list_only_trips_they_are_a_member_of(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();

        $createTrip = app(CreateTrip::class);
        $tripA = $createTrip->handle($userA, CreateTripData::from(['title' => 'Trip of User A']));
        $tripB = $createTrip->handle($userB, CreateTripData::from(['title' => 'Trip of User B']));

        Sanctum::actingAs($userA);

        $response = $this->getJson('/api/v1/trips');

        $response->assertOk();
        $tripIds = collect($response->json('data'))->pluck('id')->all();

        $this->assertContains($tripA->id, $tripIds);
        $this->assertNotContains($tripB->id, $tripIds);
    }

    public function test_user_can_view_trip_they_belong_to(): void
    {
        $user = User::factory()->create();
        $trip = app(CreateTrip::class)->handle($user, CreateTripData::from(['title' => 'Kyoto Autumn Walk']));

        Sanctum::actingAs($user);

        $response = $this->getJson("/api/v1/trips/{$trip->id}");

        $response
            ->assertOk()
            ->assertJson([
                'data' => [
                    'id' => $trip->id,
                    'title' => 'Kyoto Autumn Walk',
                    'role' => 'owner',
                ],
            ]);
    }

    public function test_user_cannot_view_another_users_trip(): void
    {
        $owner = User::factory()->create();
        $outsider = User::factory()->create();

        $trip = app(CreateTrip::class)->handle($owner, CreateTripData::from(['title' => 'Secret Trip']));

        Sanctum::actingAs($outsider);

        $response = $this->getJson("/api/v1/trips/{$trip->id}");

        $response->assertForbidden();
    }

    public function test_owner_and_editor_can_update_trip_and_increment_version(): void
    {
        $owner = User::factory()->create();
        $editor = User::factory()->create();

        $trip = app(CreateTrip::class)->handle($owner, CreateTripData::from([
            'title' => 'Original Trip Title',
            'planning_mode' => 'diy',
        ]));

        $trip->members()->create([
            'user_id' => $editor->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        // Editor updates trip title and switches planning mode
        Sanctum::actingAs($editor);

        $response = $this->patchJson("/api/v1/trips/{$trip->id}", [
            'title' => 'Updated Trip Title',
            'planning_mode' => 'guided',
        ]);

        $response
            ->assertOk()
            ->assertJson([
                'data' => [
                    'id' => $trip->id,
                    'title' => 'Updated Trip Title',
                    'planning_mode' => 'guided',
                    'version' => 2,
                    'role' => 'editor',
                ],
            ]);

        $this->assertSame(2, $trip->fresh()->version);
    }

    public function test_viewer_cannot_update_trip(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();

        $trip = app(CreateTrip::class)->handle($owner, CreateTripData::from(['title' => 'Family Tour']));

        $trip->members()->create([
            'user_id' => $viewer->id,
            'role' => 'viewer',
            'invitation_status' => 'accepted',
        ]);

        Sanctum::actingAs($viewer);

        $response = $this->patchJson("/api/v1/trips/{$trip->id}", [
            'title' => 'Hacked Title',
        ]);

        $response->assertForbidden();
        $this->assertSame('Family Tour', $trip->fresh()->title);
    }

    public function test_non_owner_cannot_delete_trip(): void
    {
        $owner = User::factory()->create();
        $editor = User::factory()->create();

        $trip = app(CreateTrip::class)->handle($owner, CreateTripData::from(['title' => 'Protected Trip']));

        $trip->members()->create([
            'user_id' => $editor->id,
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ]);

        Sanctum::actingAs($editor);

        $response = $this->deleteJson("/api/v1/trips/{$trip->id}");

        $response->assertForbidden();
        $this->assertModelExists($trip);
    }

    public function test_trip_owner_can_delete_trip(): void
    {
        $owner = User::factory()->create();
        $trip = app(CreateTrip::class)->handle($owner, CreateTripData::from(['title' => 'Trip to Cancel']));

        Sanctum::actingAs($owner);

        $response = $this->deleteJson("/api/v1/trips/{$trip->id}");

        $response->assertNoContent();
        $this->assertSoftDeleted('trips', ['id' => $trip->id]);
    }

    public function test_unauthenticated_trip_requests_are_rejected(): void
    {
        $response = $this->getJson('/api/v1/trips');
        $response->assertUnauthorized();

        $response = $this->postJson('/api/v1/trips', ['title' => 'Test']);
        $response->assertUnauthorized();
    }

    public function test_user_can_create_and_update_trip_with_named_city_destination(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $createResponse = $this->postJson('/api/v1/trips', [
            'title' => 'BGC Taguig',
            'destination_country' => 'Taguig',
            'origin_country' => 'Manila',
            'start_date' => '2026-11-09',
            'end_date' => '2026-11-12',
            'trip_type' => 'solo',
            'planning_mode' => 'guided',
        ]);

        $createResponse->assertCreated()
            ->assertJsonPath('data.title', 'BGC Taguig')
            ->assertJsonPath('data.destination_country', 'Taguig')
            ->assertJsonPath('data.origin_country', 'Manila')
            ->assertJsonPath('data.destination_currency', 'PHP');

        $tripId = $createResponse->json('data.id');

        $updateResponse = $this->putJson("/api/v1/trips/{$tripId}", [
            'destination_country' => 'Tokyo, Japan',
        ]);

        $updateResponse->assertOk()
            ->assertJsonPath('data.destination_country', 'Tokyo, Japan')
            ->assertJsonPath('data.destination_currency', 'JPY');
    }
}
