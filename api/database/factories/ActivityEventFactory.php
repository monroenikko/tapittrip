<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\ActivityEvent;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ActivityEvent>
 */
final class ActivityEventFactory extends Factory
{
    protected $model = ActivityEvent::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'actor_id' => User::factory(),
            'event_type' => 'journal_shared',
            'title' => fake()->sentence(4),
            'summary' => fake()->paragraph(),
            'entity_type' => 'journal_entry',
            'entity_id' => fake()->uuid(),
            'metadata' => [
                'mood' => 'amazed',
                'location' => 'Tokyo Tower',
            ],
            'occurred_at' => now(),
        ];
    }
}
