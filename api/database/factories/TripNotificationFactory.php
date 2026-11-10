<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Trip;
use App\Models\TripNotification;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TripNotification>
 */
final class TripNotificationFactory extends Factory
{
    protected $model = TripNotification::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'user_id' => User::factory(),
            'announcement_id' => null,
            'category' => 'circle_announcement',
            'title' => fake()->sentence(4),
            'body' => fake()->sentence(8),
            'scheduled_for_utc' => now(),
            'timezone' => 'UTC',
            'trip_local_time_label' => now()->format('M j, H:i T'),
            'status' => 'pending',
            'dedupe_key' => 'notice:'.fake()->uuid(),
            'read_at' => null,
        ];
    }
}

