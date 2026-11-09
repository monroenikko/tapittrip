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

        // District / City keywords
        $this->assertSame('KRW', CountryCurrencyResolver::resolve('Myeongdong'));
        $this->assertSame('KRW', CountryCurrencyResolver::resolve('Seoul'));
        $this->assertSame('HKD', CountryCurrencyResolver::resolve('Hong Kong'));
        $this->assertSame('HKD', CountryCurrencyResolver::resolve('迪士尼 Disney'));
        $this->assertSame('PHP', CountryCurrencyResolver::resolve('BGC Taguig'));

        // Trip currency resolution with fallback to title
        $this->assertSame('KRW', CountryCurrencyResolver::resolveTripCurrency('Myeongdong', 'Korea'));
        $this->assertSame('KRW', CountryCurrencyResolver::resolveTripCurrency('', 'Korea Trip'));
        $this->assertSame('HKD', CountryCurrencyResolver::resolveTripCurrency('Hong Kong', 'Family Vacation'));
        $this->assertSame('PHP', CountryCurrencyResolver::resolveTripCurrency(null, 'BGC Taguig Trip'));
        $this->assertSame('USD', CountryCurrencyResolver::resolveTripCurrency(null, null));
    }

    public function test_trip_resource_includes_destination_currency(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $trip = Trip::factory()->create([
            'owner_id' => $user->id,
            'title' => 'Korea',
            'destination_country' => 'Myeongdong',
        ]);

        $response = $this->getJson("/api/v1/trips/{$trip->id}");

        $response
            ->assertOk()
            ->assertJsonPath('data.destination_country', 'Myeongdong')
            ->assertJsonPath('data.destination_currency', 'KRW');
    }

    public function test_currency_minor_conversion_handles_zero_decimal_scales(): void
    {
        // 1,000 JPY to PHP at rate 0.3980: 1000 JPY = 398.00 PHP -> 39,800 centavos
        $phpMinor = CountryCurrencyResolver::convertAmountMinor(1000, 'JPY', 'PHP', 0.3980);
        $this->assertSame(39800, $phpMinor);

        // 3,000 JPY to USD at rate 0.0067: 3000 JPY = $20.10 USD -> 2010 cents
        $usdMinor = CountryCurrencyResolver::convertAmountMinor(3000, 'JPY', 'USD', 0.0067);
        $this->assertSame(2010, $usdMinor);

        // 398.00 PHP (39800 centavos) to JPY at rate 2.51: 398 * 2.51 = 998.98 -> 999 JPY
        $jpyMinor = CountryCurrencyResolver::convertAmountMinor(39800, 'PHP', 'JPY', 2.51);
        $this->assertSame(999, $jpyMinor);

        // 10.00 USD (1000 cents) to PHP at rate 58.50: 10 * 58.50 = 585.00 PHP -> 58,500 centavos
        $phpFromUsd = CountryCurrencyResolver::convertAmountMinor(1000, 'USD', 'PHP', 58.50);
        $this->assertSame(58500, $phpFromUsd);

        // Same currency returns exact amount
        $same = CountryCurrencyResolver::convertAmountMinor(5000, 'PHP', 'PHP', 1.0);
        $this->assertSame(5000, $same);
    }
}
