<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Flight;
use App\Models\Trip;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<Flight> */
final class FlightFactory extends Factory
{
    protected $model = Flight::class;

    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'airline' => 'Sample Air',
            'booking_reference' => 'DEMO-'.fake()->bothify('###???'),
            'version' => 1,
        ];
    }
}
