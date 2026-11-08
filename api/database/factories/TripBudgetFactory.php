<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Expenses\Models\TripBudget;
use App\Domain\Trips\Models\Trip;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TripBudget>
 */
final class TripBudgetFactory extends Factory
{
    protected $model = TripBudget::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'currency' => fake()->randomElement(['USD', 'EUR', 'PHP', 'JPY', 'SGD']),
            'total_budget_minor' => fake()->numberBetween(50000, 500000), // e.g. $500.00 to $5000.00
            'daily_budget_minor' => fake()->numberBetween(10000, 50000),
        ];
    }
}
