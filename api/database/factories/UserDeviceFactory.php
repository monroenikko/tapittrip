<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Notifications\Models\UserDevice;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<UserDevice>
 */
final class UserDeviceFactory extends Factory
{
    protected $model = UserDevice::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'platform' => fake()->randomElement(['ios', 'android', 'web']),
            'device_key' => fake()->uuid(),
            'push_token' => 'fcm_token_'.fake()->sha256(),
            'last_seen_at' => now(),
        ];
    }
}

