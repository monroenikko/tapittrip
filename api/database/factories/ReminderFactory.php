<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Notifications\Models\Reminder;
use App\Domain\Trips\Models\Trip;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Reminder>
 */
final class ReminderFactory extends Factory
{
    protected $model = Reminder::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $type = fake()->randomElement(['morning_summary', 'activity_reminder', 'departure_checklist', 'stay_checkin', 'stay_checkout']);

        return [
            'trip_id' => Trip::factory(),
            'itinerary_item_id' => null,
            'checklist_id' => null,
            'type' => $type,
            'title' => fake()->sentence(3),
            'body' => fake()->sentence(8),
            'trigger_at_utc' => now()->addHours(2),
            'timezone' => 'Asia/Tokyo',
            'delivery_channel' => 'local',
            'status' => 'scheduled',
            'dedupe_key' => fake()->uuid(),
            'source_version' => 1,
        ];
    }
}

