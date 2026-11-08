<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Sync\Models\SyncOperation;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<SyncOperation>
 */
final class SyncOperationFactory extends Factory
{
    protected $model = SyncOperation::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'operation_id' => (string) Str::uuid(),
            'user_id' => User::factory(),
            'trip_id' => Trip::factory(),
            'device_key' => 'device_'.Str::random(12),
            'entity_type' => 'checklist_item',
            'entity_id' => (string) Str::uuid(),
            'operation_type' => 'update',
            'payload' => ['title' => fake()->sentence(3), 'is_packed' => true],
            'base_version' => 1,
            'status' => 'accepted',
            'conflict_details' => null,
            'processed_at' => now(),
        ];
    }
}
