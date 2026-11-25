<?php

declare(strict_types=1);

namespace App\Domain\Stays;

use App\Models\Stay;
use App\Models\User;

final class StayPrivacy
{
    public static function isOwner(Stay $stay, ?User $viewer): bool
    {
        if ($viewer === null) {
            return false;
        }

        $ownerId = $stay->relationLoaded('trip')
            ? $stay->trip?->owner_id
            : $stay->trip()->value('owner_id');

        return $ownerId === $viewer->id;
    }

    public static function hidesPrivateAddress(Stay $stay, ?User $viewer): bool
    {
        return ! self::isOwner($stay, $viewer) && $stay->stay_type === 'friends_family';
    }

    /**
     * Build a safe server snapshot for sync conflict responses and API payloads.
     *
     * @return array<string, mixed>
     */
    public static function redactServerPayload(Stay $stay, ?User $viewer): array
    {
        $isOwner = self::isOwner($stay, $viewer);
        $hidePrivateLocation = self::hidesPrivateAddress($stay, $viewer);

        return [
            'id' => $stay->id,
            'trip_id' => $stay->trip_id,
            'place_id' => $stay->place_id,
            'name' => $stay->name,
            'stay_type' => $stay->stay_type,
            'address' => $hidePrivateLocation ? null : $stay->address,
            'latitude' => $hidePrivateLocation ? null : $stay->latitude,
            'longitude' => $hidePrivateLocation ? null : $stay->longitude,
            'check_in_at' => $stay->check_in_at?->toIso8601String(),
            'check_out_at' => $stay->check_out_at?->toIso8601String(),
            'timezone' => $stay->timezone,
            'phone' => $isOwner ? $stay->phone : null,
            'booking_reference' => $isOwner ? $stay->booking_reference : null,
            'notes' => $hidePrivateLocation ? null : $stay->notes,
            'luggage_profile' => $stay->luggage_profile,
            'version' => $stay->version,
            'updated_at' => $stay->updated_at?->toIso8601String(),
        ];
    }
}
