<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Lounges\Models\Airport;
use App\Domain\Lounges\Models\AirportTerminal;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AirportTerminal>
 */
final class AirportTerminalFactory extends Factory
{
    protected $model = AirportTerminal::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $num = fake()->numberBetween(1, 4);

        return [
            'airport_id' => Airport::factory(),
            'name' => "Terminal {$num}",
            'code' => "T{$num}",
        ];
    }
}
