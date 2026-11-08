<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Expenses\Models\Expense;
use App\Domain\Expenses\Models\ExpenseSplit;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ExpenseSplit>
 */
final class ExpenseSplitFactory extends Factory
{
    protected $model = ExpenseSplit::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'expense_id' => Expense::factory(),
            'user_id' => User::factory(),
            'amount_minor' => 1500,
            'base_amount_minor' => 1500,
            'shares' => 1,
            'settled' => false,
        ];
    }
}
