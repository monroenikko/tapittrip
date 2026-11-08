<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Expenses\Models\ExpenseSettlement;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ExpenseSettlement>
 */
final class ExpenseSettlementFactory extends Factory
{
    protected $model = ExpenseSettlement::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'payer_id' => User::factory(),
            'payee_id' => User::factory(),
            'amount_minor' => 2500,
            'currency' => 'USD',
            'settled_at' => now(),
            'notes' => 'Settled via cash',
        ];
    }
}
