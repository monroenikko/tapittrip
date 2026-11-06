<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Checklists\Models\Checklist;
use App\Domain\Trips\Models\Trip;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Checklist>
 */
final class ChecklistFactory extends Factory
{
    protected $model = Checklist::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'title' => fake()->randomElement(['Main Packing List', 'Documents & Currency', 'Electronics & Gadgets', 'Return Checklist']),
            'type' => fake()->randomElement(['packing', 'documents', 'departure', 'return', 'custom']),
            'description' => fake()->optional()->sentence(),
            'sort_order' => 0,
        ];
    }
}
