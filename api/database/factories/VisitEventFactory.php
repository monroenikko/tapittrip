<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Itinerary\Models\VisitEvent;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<VisitEvent>
 */
final class VisitEventFactory extends Factory
{
    protected $model = VisitEvent::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'itinerary_item_id' => ItineraryItem::factory(),
            'user_id' => User::factory(),
            'event_type' => 'confirmed',
            'method' => 'manual',
            'detected_at' => now(),
            'accuracy_m' => 15.5,
        ];
    }
}
