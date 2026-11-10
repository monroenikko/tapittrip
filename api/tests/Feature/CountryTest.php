<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Services\Expenses\CountryCurrencyResolver;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Tests\TestCase;

final class CountryTest extends TestCase
{
    use DatabaseTransactions;

    public function test_can_list_all_countries_publicly(): void
    {
        $response = $this->getJson('/api/v1/countries');

        $response
            ->assertOk()
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'code',
                        'name',
                        'currency_code',
                        'flag_emoji',
                        'is_zero_decimal',
                    ],
                ],
            ]);

        $this->assertGreaterThanOrEqual(180, count($response->json('data')));
    }

    public function test_can_search_countries(): void
    {
        $response = $this->getJson('/api/v1/countries?search=japan');

        $response
            ->assertOk()
            ->assertJsonPath('data.0.code', 'JP')
            ->assertJsonPath('data.0.currency_code', 'JPY')
            ->assertJsonPath('data.0.flag_emoji', '🇯🇵')
            ->assertJsonPath('data.0.is_zero_decimal', true);

        $codeResponse = $this->getJson('/api/v1/countries?search=PH');
        $codeResponse
            ->assertOk()
            ->assertJsonPath('data.0.code', 'PH')
            ->assertJsonPath('data.0.currency_code', 'PHP');
    }

    public function test_search_with_no_matches_returns_empty_collection(): void
    {
        $response = $this->getJson('/api/v1/countries?search=nonexistent_atlantis_9999');

        $response
            ->assertOk()
            ->assertJsonPath('data', []);
    }

    public function test_country_currency_resolver_falls_back_to_usd_for_unknown_or_null_locations(): void
    {
        $this->assertSame('USD', CountryCurrencyResolver::resolve('atlantis_nowhere'));
        $this->assertSame('USD', CountryCurrencyResolver::resolve(''));
        $this->assertSame('USD', CountryCurrencyResolver::resolve(null));
        $this->assertSame('EUR', CountryCurrencyResolver::resolve('atlantis_nowhere', 'EUR'));
    }
}
