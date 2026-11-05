<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Itinerary\Models\Place;
use App\Domain\Itinerary\Models\TripDay;
use App\Domain\Trips\Models\Trip;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ItineraryItem>
 */
final class ItineraryItemFactory extends Factory
{
    protected $model = ItineraryItem::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'trip_day_id' => null,
            'place_id' => null,
            'kind' => fake()->randomElement(['attraction', 'meal', 'transport', 'hotel', 'custom']),
            'title' => fake()->sentence(3),
            'notes' => fake()->optional()->paragraph(),
            'starts_at_utc' => now()->addHours(2),
            'ends_at_utc' => now()->addHours(4),
            'timezone' => 'Asia/Tokyo',
            'sort_order' => 0,
            'status' => 'planned',
            'version' => 1,
        ];
    }

    /**
     * Link with a place.
     */
    public function withPlace(?Place $place = null): static
    {
        return $this->state(fn () => [
            'place_id' => $place?->id ?? Place::factory(),
        ]);
    }

    /**
     * Link with a day.
     */
    public function forDay(TripDay $day): static
    {
        return $this->state(fn () => [
            'trip_id' => $day->trip_id,
            'trip_day_id' => $day->id,
        ]);
    }
}
