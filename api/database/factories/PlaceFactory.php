<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Itinerary\Models\Place;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Place>
 */
final class PlaceFactory extends Factory
{
    protected $model = Place::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'provider' => 'manual',
            'provider_place_id' => fake()->optional()->uuid(),
            'name' => fake()->company().' Spot',
            'formatted_address' => fake()->address(),
            'country_code' => 'JP',
            'latitude' => fake()->latitude(35.0, 36.0),
            'longitude' => fake()->longitude(139.0, 140.0),
            'attribution' => 'TapItTrip Manual Place',
            'last_refreshed_at' => now(),
        ];
    }
}
