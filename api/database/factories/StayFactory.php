<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Itinerary\Models\Place;
use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Stay>
 */
final class StayFactory extends Factory
{
    protected $model = Stay::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'place_id' => null,
            'name' => fake()->company().' Hotel',
            'stay_type' => fake()->randomElement(['hotel', 'hostel', 'rental', 'friends_family']),
            'address' => fake()->streetAddress().', '.fake()->city(),
            'latitude' => fake()->latitude(34.0, 36.0),
            'longitude' => fake()->longitude(135.0, 140.0),
            'check_in_at' => now()->addDays(1)->setTime(15, 0),
            'check_out_at' => now()->addDays(4)->setTime(11, 0),
            'timezone' => 'Asia/Tokyo',
            'phone' => fake()->phoneNumber(),
            'booking_reference' => 'BK-'.fake()->bothify('??###??'),
            'notes' => fake()->optional()->sentence(),
            'luggage_profile' => [
                'party_size' => 2,
                'backpacks' => 2,
                'carry_ons' => 2,
                'checked_bags' => 1,
                'oversized' => 0,
                'stroller' => false,
            ],
            'version' => 1,
        ];
    }

    /**
     * Associate with a place.
     */
    public function withPlace(?Place $place = null): static
    {
        return $this->state(fn () => [
            'place_id' => $place?->id ?? Place::factory(),
        ]);
    }
}
