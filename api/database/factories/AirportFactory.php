<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Lounges\Models\Airport;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Airport>
 */
final class AirportFactory extends Factory
{
    protected $model = Airport::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'iata_code' => strtoupper(fake()->unique()->lexify('???')),
            'name' => fake()->city().' International Airport',
            'city' => fake()->city(),
            'country' => fake()->country(),
            'latitude' => fake()->latitude(),
            'longitude' => fake()->longitude(),
            'timezone' => 'Asia/Manila',
        ];
    }
}
