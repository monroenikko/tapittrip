<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Application\Expenses\Services\CountryCurrencyResolver;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

final class CurrencyTest extends TestCase
{
    use DatabaseTransactions;

    public function test_can_fetch_currency_exchange_rate(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/currencies/rates?from=JPY&to=PHP');

        $response
            ->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'from',
                    'to',
                    'rate',
                    'reciprocal_rate',
                    'as_of',
                    'provider',
                ],
            ])
            ->assertJsonPath('data.from', 'JPY')
            ->assertJsonPath('data.to', 'PHP');

        $this->assertEqualsWithDelta(0.3800, (float) $response->json('data.rate'), 0.05);
    }

    public function test_same_currency_returns_one(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/currencies/rates?from=USD&to=USD');

        $response->assertOk();
        $this->assertEquals(1.0, (float) $response->json('data.rate'));
        $this->assertEquals(1.0, (float) $response->json('data.reciprocal_rate'));
    }

    public function test_country_currency_resolver_resolves_accurately(): void
    {
        $this->assertSame('PHP', CountryCurrencyResolver::resolve('PH'));
        $this->assertSame('PHP', CountryCurrencyResolver::resolve('Philippines'));
        $this->assertSame('PHP', CountryCurrencyResolver::resolve('Manila'));

        $this->assertSame('JPY', CountryCurrencyResolver::resolve('JP'));
        $this->assertSame('JPY', CountryCurrencyResolver::resolve('Japan'));
        $this->assertSame('JPY', CountryCurrencyResolver::resolve('Tokyo'));

        $this->assertSame('EUR', CountryCurrencyResolver::resolve('FR'));
        $this->assertSame('EUR', CountryCurrencyResolver::resolve('France'));
        $this->assertSame('EUR', CountryCurrencyResolver::resolve('Paris'));

        $this->assertSame('SGD', CountryCurrencyResolver::resolve('SG'));
        $this->assertSame('SGD', CountryCurrencyResolver::resolve('Singapore'));

        $this->assertSame('GBP', CountryCurrencyResolver::resolve('GB'));
        $this->assertSame('GBP', CountryCurrencyResolver::resolve('London'));

        $this->assertSame('USD', CountryCurrencyResolver::resolve(null));
        $this->assertSame('USD', CountryCurrencyResolver::resolve(''));
    }

    public function test_trip_resource_includes_destination_currency(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'title' => 'Cherry Blossom Tour',
            'destination_country' => 'JP',
        ]);

        $response = $this->getJson("/api/v1/trips/{$trip->id}");

        $response
            ->assertOk()
            ->assertJsonPath('data.destination_country', 'JP')
            ->assertJsonPath('data.destination_currency', 'JPY');
    }
}
