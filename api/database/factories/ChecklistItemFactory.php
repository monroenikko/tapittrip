<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Checklists\Models\Checklist;
use App\Domain\Checklists\Models\ChecklistItem;
use App\Domain\Trips\Models\Trip;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ChecklistItem>
 */
final class ChecklistItemFactory extends Factory
{
    protected $model = ChecklistItem::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'checklist_id' => Checklist::factory(),
            'trip_id' => fn (array $attributes) => Checklist::find($attributes['checklist_id'])?->trip_id ?? Trip::factory(),
            'title' => fake()->randomElement(['Passport', 'Universal Adapter', 'Rain Jacket', 'Toothbrush', 'Power Bank']),
            'category' => fake()->randomElement(['documents', 'clothing', 'electronics', 'toiletries', 'health', 'gear', 'other']),
            'is_packed' => false,
            'quantity' => fake()->numberBetween(1, 3),
            'notes' => fake()->optional()->sentence(),
            'photo_url' => null,
            'sort_order' => 0,
            'packed_at' => null,
            'version' => 1,
        ];
    }

    /**
     * Mark item as packed.
     */
    public function packed(): static
    {
        return $this->state(fn () => [
            'is_packed' => true,
            'packed_at' => now(),
        ]);
    }
}
