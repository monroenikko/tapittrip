<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Sync\Models\SyncCursor;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<SyncCursor>
 */
final class SyncCursorFactory extends Factory
{
    protected $model = SyncCursor::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'device_key' => 'device_'.Str::random(12),
            'trip_id' => Trip::factory(),
            'last_server_sequence' => 0,
        ];
    }
}
