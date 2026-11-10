<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Trip;
use App\Models\TripInvitation;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TripInvitation>
 */
final class TripInvitationFactory extends Factory
{
    protected $model = TripInvitation::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'trip_id' => Trip::factory(),
            'inviter_id' => User::factory(),
            'invite_type' => 'link',
            'token_hash' => hash('sha256', fake()->unique()->uuid().bin2hex(random_bytes(8))),
            'proposed_role' => 'viewer',
            'status' => 'active',
            'max_uses' => 1,
            'use_count' => 0,
            'expires_at' => now()->addDays(7),
            'revoked_at' => null,
        ];
    }
}
