<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Expense>
 */
final class ExpenseFactory extends Factory
{
    protected $model = Expense::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $amount = fake()->numberBetween(500, 25000); // e.g. $5.00 to $250.00
        $currency = 'USD';

        return [
            'trip_id' => Trip::factory(),
            'payer_id' => User::factory(),
            'category' => fake()->randomElement(['dining', 'transport', 'accommodation', 'activities', 'shopping', 'other']),
            'title' => fake()->words(3, true),
            'amount_minor' => $amount,
            'currency' => $currency,
            'exchange_rate' => 1.0,
            'base_amount_minor' => $amount,
            'expense_date' => now()->toDateString(),
            'itinerary_item_id' => null,
            'stay_id' => null,
            'split_type' => 'single',
            'notes' => fake()->optional()->sentence(),
            'receipt_url' => null,
            'version' => 1,
        ];
    }
}
