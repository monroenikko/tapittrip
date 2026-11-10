<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Trip;
use App\Models\TripOwnershipTransfer;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TripOwnershipTransfer>
 */
class TripOwnershipTransferFactory extends Factory
{
    protected $model = TripOwnershipTransfer::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'from_user_id' => User::factory(),
            'to_user_id' => User::factory(),
            'former_owner_role' => 'editor',
            'status' => 'pending',
            'expires_at' => CarbonImmutable::now('UTC')->addDays(7),
            'responded_at' => null,
        ];
    }
}
