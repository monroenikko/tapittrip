<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Trip;
use App\Models\TripTraveler;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TripTraveler>
 */
final class TripTravelerFactory extends Factory
{
    protected $model = TripTraveler::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'linked_member_id' => null,
            'managing_user_id' => User::factory(),
            'display_name' => fake()->firstName(),
            'traveler_category' => 'child',
            'restricted_notes' => null,
            'version' => 1,
        ];
    }
}
