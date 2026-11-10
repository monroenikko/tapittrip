<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Country;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Country>
 */
final class CountryFactory extends Factory
{
    protected $model = Country::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'code' => fake()->unique()->lexify('??'),
            'name' => fake()->country(),
            'currency_code' => fake()->currencyCode(),
            'flag_emoji' => '🌐',
            'is_zero_decimal' => false,
            'aliases' => [fake()->city(), fake()->city()],
        ];
    }
}
