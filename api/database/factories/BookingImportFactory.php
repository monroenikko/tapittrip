<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\BookingImport;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<BookingImport>
 */
final class BookingImportFactory extends Factory
{
    protected $model = BookingImport::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'user_id' => User::factory(),
            'source' => 'paste_text',
            'booking_type' => 'flight',
            'raw_text' => 'Flight confirmation PR 101 MNL -> NRT',
            'extraction_status' => 'extracted',
            'extracted_data' => [
                'booking_type' => 'flight',
                'confidence' => 0.95,
                'summary' => 'Philippine Airlines PR 101 (MNL → NRT)',
                'flight' => [
                    'airline' => 'Philippine Airlines',
                    'booking_reference' => 'PR-CONF-8899',
                    'segments' => [
                        [
                            'flight_number' => 'PR 101',
                            'origin_airport' => 'MNL',
                            'destination_airport' => 'NRT',
                            'scheduled_departure_utc' => '2027-04-10T08:00:00Z',
                            'scheduled_arrival_utc' => '2027-04-10T13:30:00Z',
                            'origin_timezone' => 'Asia/Manila',
                            'destination_timezone' => 'Asia/Tokyo',
                            'terminal' => 'Terminal 2',
                            'gate' => null,
                        ],
                    ],
                ],
            ],
            'confidence_score' => 0.95,
            'confirmed_entity_type' => null,
            'confirmed_entity_id' => null,
            'reviewed_at' => null,
            'error_message' => null,
            'client_operation_id' => null,
            'version' => 1,
        ];
    }
}
