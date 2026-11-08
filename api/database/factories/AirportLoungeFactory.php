<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Lounges\Models\Airport;
use App\Domain\Lounges\Models\AirportLounge;
use App\Domain\Lounges\Models\AirportTerminal;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AirportLounge>
 */
final class AirportLoungeFactory extends Factory
{
    protected $model = AirportLounge::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'airport_id' => Airport::factory(),
            'terminal_id' => function (array $attributes) {
                return AirportTerminal::factory()->create([
                    'airport_id' => $attributes['airport_id'],
                ])->id;
            },
            'name' => fake()->company().' Executive Lounge',
            'operator' => fake()->company(),
            'location_description' => 'Level 4, near Gate '.fake()->numberBetween(100, 130),
            'is_airside' => true,
            'opening_hours' => [
                'open' => '05:00',
                'close' => '23:00',
                'is_24h' => false,
            ],
            'amenities' => ['buffet', 'bar', 'showers', 'wifi', 'power_outlets', 'quiet_area'],
            'access_methods' => ['priority_pass', 'lounge_key', 'business_class', 'paid_walkin'],
            'estimated_price' => [
                'amount_cents' => 3000,
                'currency' => 'PHP',
            ],
            'booking_url' => fake()->url(),
            'transit_warning' => null,
            'disclaimer' => 'Actual access depends on capacity and airline status.',
        ];
    }
}
