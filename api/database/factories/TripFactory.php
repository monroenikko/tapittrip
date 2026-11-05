<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Trip>
 */
final class TripFactory extends Factory
{
    protected $model = Trip::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $startDate = fake()->dateTimeBetween('now', '+1 month');
        $endDate = (clone $startDate)->modify('+7 days');

        return [
            'owner_id' => User::factory(),
            'title' => fake()->sentence(3),
            'start_date' => $startDate->format('Y-m-d'),
            'end_date' => $endDate->format('Y-m-d'),
            'primary_timezone' => fake()->timezone(),
            'origin_country' => 'PH',
            'destination_country' => 'JP',
            'trip_type' => 'leisure',
            'planning_mode' => 'diy',
            'status' => 'planned',
            'version' => 1,
        ];
    }

    /**
     * Set the planning mode.
     */
    public function mode(string $mode): static
    {
        return $this->state(fn () => ['planning_mode' => $mode]);
    }
}
