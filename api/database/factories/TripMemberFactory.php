<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Trips\Models\Trip;
use App\Domain\Trips\Models\TripMember;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TripMember>
 */
final class TripMemberFactory extends Factory
{
    protected $model = TripMember::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'user_id' => User::factory(),
            'role' => 'editor',
            'invitation_status' => 'accepted',
        ];
    }
}
