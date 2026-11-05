<?php

declare(strict_types=1);

namespace App\Application\Itinerary\Services;

use App\Application\Itinerary\Data\CreatePlaceData;
use App\Domain\Itinerary\Models\Place;
use Illuminate\Support\Facades\DB;

final class CreatePlaceService
{
    public function handle(CreatePlaceData $data): Place
    {
        return DB::transaction(function () use ($data): Place {
            if ($data->providerPlaceId !== null && $data->provider !== 'manual') {
                /** @var Place|null $existing */
                $existing = Place::query()
                    ->where('provider', $data->provider)
                    ->where('provider_place_id', $data->providerPlaceId)
                    ->first();

                if ($existing !== null) {
                    $existing->update([
                        'name' => $data->name,
                        'formatted_address' => $data->formattedAddress ?? $existing->formatted_address,
                        'country_code' => $data->countryCode ?? $existing->country_code,
                        'latitude' => $data->latitude ?? $existing->latitude,
                        'longitude' => $data->longitude ?? $existing->longitude,
                        'photo_reference' => $data->photoReference ?? $existing->photo_reference,
                        'attribution' => $data->attribution ?? $existing->attribution,
                        'last_refreshed_at' => now(),
                    ]);

                    return $existing;
                }
            }

            return Place::query()->create([
                'provider' => $data->provider,
                'provider_place_id' => $data->providerPlaceId,
                'name' => $data->name,
                'formatted_address' => $data->formattedAddress,
                'country_code' => $data->countryCode,
                'latitude' => $data->latitude,
                'longitude' => $data->longitude,
                'photo_reference' => $data->photoReference,
                'attribution' => $data->attribution,
                'last_refreshed_at' => now(),
            ]);
        });
    }
}
