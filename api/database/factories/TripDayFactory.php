<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Itinerary\Models\TripDay;
use App\Domain\Trips\Models\Trip;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TripDay>
 */
final class TripDayFactory extends Factory
{
    protected $model = TripDay::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'local_date' => fake()->date(),
            'notes' => fake()->optional()->sentence(),
        ];
    }
}
