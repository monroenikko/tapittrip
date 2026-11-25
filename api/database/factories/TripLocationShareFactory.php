<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Trip;
use App\Models\TripLocationShare;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TripLocationShare>
 */
final class TripLocationShareFactory extends Factory
{
    protected $model = TripLocationShare::class;

    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'user_id' => User::factory(),
            'enabled' => false,
            'duration_minutes' => 60,
            'expires_at' => CarbonImmutable::now('UTC')->addMinutes(60),
            'audience' => 'circle',
            'latitude' => null,
            'longitude' => null,
            'last_shared_at' => null,
        ];
    }

    public function active(): self
    {
        return $this->state(fn () => [
            'enabled' => true,
            'latitude' => 37.774929,
            'longitude' => -122.419416,
            'last_shared_at' => CarbonImmutable::now('UTC'),
            'expires_at' => CarbonImmutable::now('UTC')->addHours(2),
        ]);
    }
}
