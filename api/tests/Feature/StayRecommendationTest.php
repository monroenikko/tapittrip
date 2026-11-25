<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Contracts\StayRecommendationProvider;
use App\DTOs\Itinerary\TripAssistantResult;
use App\Models\ItineraryItem;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\TripMember;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

final class StayRecommendationTest extends TestCase
{
    use DatabaseTransactions;

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.gemini.api_key' => 'fake-key']);
        Http::preventStrayRequests();
    }

    private function trip(): Trip
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        return Trip::factory()->create(['owner_id' => $user->id]);
    }

    private function fakeIdeas(): void
    {
        Http::fake(['generativelanguage.googleapis.com/*' => Http::response([
            'candidates' => [['content' => ['parts' => [['text' => json_encode([
                'reply' => 'Research the station area for your planned stops.',
                'category' => 'general',
                'suggested_actions' => [
                    ['label' => 'Hotel', 'kind' => 'add_activity', 'payload' => ['title' => 'Example Hotel', 'kind' => 'hotel', 'place_name' => 'Example Hotel', 'notes' => '<b>Research this base.</b>', 'url' => 'javascript:alert(1)']],
                    ['label' => 'Duplicate', 'kind' => 'add_activity', 'payload' => ['title' => 'Other title', 'kind' => 'hotel', 'place_name' => 'example hotel']],
                    ['label' => 'Lunch', 'kind' => 'add_activity', 'payload' => ['title' => 'Lunch', 'kind' => 'meal']],
                ],
            ])]]]]],
        ])]);
    }

    public function test_generates_lodging_only_using_saved_context_without_mutation(): void
    {
        $trip = $this->trip();
        ItineraryItem::factory()->create(['trip_id' => $trip->id, 'title' => 'My museum stop']);
        ItineraryItem::factory()->create(['title' => 'Other trip stop']);
        $this->fakeIdeas();

        $response = $this->postJson("/api/v1/trips/{$trip->id}/stay-recommendations");
        $response->assertOk()->assertHeader('Cache-Control', 'no-store, private')
            ->assertJsonPath('data.context_summary.status', 'ready')
            ->assertJsonPath('data.context_summary.source', 'gemini')
            ->assertJsonPath('data.context_summary.verified', false)
            ->assertJsonCount(1, 'data.suggested_actions')
            ->assertJsonPath('data.suggested_actions.0.payload.notes', 'Research this base.')
            ->assertJsonMissingPath('data.suggested_actions.0.payload.url');
        Http::assertSent(fn ($request): bool => str_contains($request['contents'][0]['parts'][0]['text'], 'My museum stop')
            && ! str_contains($request['contents'][0]['parts'][0]['text'], 'Other trip stop'));
        $this->assertSame(0, $trip->stays()->count());
        $this->assertSame(1, $trip->itineraryItems()->count());
    }

    public function test_saved_stay_skips_provider(): void
    {
        $trip = $this->trip();
        Stay::factory()->create(['trip_id' => $trip->id]);
        $this->postJson("/api/v1/trips/{$trip->id}/stay-recommendations")->assertOk()
            ->assertJsonPath('data.context_summary.status', 'stay_exists')->assertJsonCount(0, 'data.suggested_actions');
        Http::assertNothingSent();
    }

    #[DataProvider('modes')]
    public function test_all_planning_modes_work_without_itinerary(string $mode): void
    {
        $trip = $this->trip();
        $trip->update(['planning_mode' => $mode]);
        $this->fakeIdeas();
        $this->postJson("/api/v1/trips/{$trip->id}/stay-recommendations")->assertOk()->assertJsonPath('data.context_summary.status', 'ready');
    }

    public static function modes(): array
    {
        return [['diy'], ['existing'], ['guided'], ['simple']];
    }

    public function test_stay_saved_during_generation_suppresses_result(): void
    {
        $trip = $this->trip();
        $this->mock(StayRecommendationProvider::class)->shouldReceive('recommend')->once()->andReturnUsing(function (Trip $trip) {
            Stay::factory()->create(['trip_id' => $trip->id]);

            return new TripAssistantResult(reply: 'Stale ideas', category: 'general');
        });
        $this->postJson("/api/v1/trips/{$trip->id}/stay-recommendations")->assertOk()
            ->assertJsonPath('data.context_summary.status', 'stay_exists')->assertJsonPath('data.reply', '');
    }

    public function test_malformed_provider_response_is_unavailable(): void
    {
        $trip = $this->trip();
        Http::fake(['*' => Http::response(['candidates' => []])]);
        $this->postJson("/api/v1/trips/{$trip->id}/stay-recommendations")->assertOk()
            ->assertJsonPath('data.context_summary.status', 'unavailable');
    }

    public function test_missing_key_returns_honest_fallback(): void
    {
        $trip = $this->trip();
        config(['services.gemini.api_key' => '']);
        $this->postJson("/api/v1/trips/{$trip->id}/stay-recommendations")->assertOk()
            ->assertJsonPath('data.context_summary.status', 'unavailable')->assertJsonCount(0, 'data.suggested_actions');
        Http::assertNothingSent();
    }

    public function test_failed_provider_returns_fallback(): void
    {
        $trip = $this->trip();
        Http::fake(['*' => Http::response([], 503)]);
        $this->postJson("/api/v1/trips/{$trip->id}/stay-recommendations")->assertOk()->assertJsonPath('data.context_summary.status', 'unavailable');
    }

    public function test_unauthenticated_request_is_rejected(): void
    {
        $this->postJson('/api/v1/trips/00000000-0000-0000-0000-000000000000/stay-recommendations')
            ->assertUnauthorized()->assertJsonPath('error.code', 'unauthenticated');
        Http::assertNothingSent();
    }

    public function test_nonmember_cannot_generate_and_missing_trip_returns_404(): void
    {
        $this->trip();
        $other = Trip::factory()->create();
        $this->postJson("/api/v1/trips/{$other->id}/stay-recommendations")->assertForbidden()->assertJsonPath('error.code', 'forbidden');
        $this->postJson('/api/v1/trips/00000000-0000-0000-0000-000000000000/stay-recommendations')->assertNotFound()->assertJsonPath('error.code', 'not_found');
        Http::assertNothingSent();
    }

    public function test_accepted_viewer_can_request_advisory_ideas(): void
    {
        $trip = $this->trip();
        $viewer = User::factory()->create();
        TripMember::factory()->create(['trip_id' => $trip->id, 'user_id' => $viewer->id, 'role' => 'viewer']);
        Sanctum::actingAs($viewer);
        $this->fakeIdeas();
        $this->postJson("/api/v1/trips/{$trip->id}/stay-recommendations")->assertOk();
    }

    public function test_requests_are_rate_limited(): void
    {
        $trip = $this->trip();
        config(['services.gemini.api_key' => '']);
        for ($i = 0; $i < 6; $i++) {
            $this->postJson("/api/v1/trips/{$trip->id}/stay-recommendations")->assertOk();
        }
        $this->postJson("/api/v1/trips/{$trip->id}/stay-recommendations")->assertStatus(429)->assertJsonPath('error.code', 'rate_limited')->assertHeader('Retry-After');
    }

    public function test_unexpected_errors_use_safe_envelope(): void
    {
        $trip = $this->trip();
        $this->mock(StayRecommendationProvider::class)->shouldReceive('recommend')->once()->andThrow(new \RuntimeException('private provider details'));
        $this->postJson("/api/v1/trips/{$trip->id}/stay-recommendations")->assertStatus(500)
            ->assertJsonPath('error.code', 'internal_error')->assertDontSee('private provider details');
    }
}
