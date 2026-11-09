<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Journal\Models\JournalEntry;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<JournalEntry>
 */
final class JournalEntryFactory extends Factory
{
    protected $model = JournalEntry::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'user_id' => User::factory(),
            'title' => fake()->sentence(3),
            'content' => fake()->paragraphs(2, true),
            'entry_date' => fake()->date(),
            'location_name' => fake()->city(),
            'weather' => fake()->randomElement(['sunny', 'cloudy', 'rainy', 'snowy']),
            'mood' => fake()->randomElement(['amazed', 'happy', 'peaceful', 'excited', 'tired']),
            'is_shared' => false,
            'photos' => [],
        ];
    }

    public function shared(): self
    {
        return $this->state(fn () => ['is_shared' => true]);
    }
}
