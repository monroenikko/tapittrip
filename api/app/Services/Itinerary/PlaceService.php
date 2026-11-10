<?php

declare(strict_types=1);

namespace App\Services\Itinerary;

use App\DTOs\Itinerary\CreatePlaceData;
use App\Models\Place;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

final class PlaceService
{
    /**
     * Create or update a cached place in local storage.
     */
    public function createPlace(CreatePlaceData $data): Place
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

    /**
     * Search places from local storage and third-party geocoding providers.
     *
     * @return Collection<int, Place>
     */
    public function search(string $query): Collection
    {
        $trimmed = trim($query);
        if ($trimmed === '') {
            return Place::query()->latest()->limit(10)->get();
        }

        // 1. Fetch matching local places
        $localPlaces = Place::query()
            ->where('name', 'ilike', "%{$trimmed}%")
            ->orWhere('formatted_address', 'ilike', "%{$trimmed}%")
            ->limit(10)
            ->get();

        // 2. If short query or enough local results, return them
        if (mb_strlen($trimmed) < 3) {
            return $localPlaces;
        }

        // 3. Query 3rd party provider (Nominatim / OSM with Google Maps API key fallback)
        $externalPlaces = $this->queryExternalProvider($trimmed);

        // 4. Merge unique results
        $combined = $localPlaces->merge($externalPlaces)->unique('id')->values();

        return new Collection($combined->take(15)->all());
    }

    /**
     * @return Collection<int, Place>
     */
    private function queryExternalProvider(string $query): Collection
    {
        $googleKey = config('services.google.maps_api_key');

        if (! empty($googleKey)) {
            $places = $this->queryGooglePlaces($query, (string) $googleKey);
            if ($places->isNotEmpty()) {
                return $places;
            }
        }

        return $this->queryNominatim($query);
    }

    /**
     * @return Collection<int, Place>
     */
    private function queryNominatim(string $query): Collection
    {
        try {
            $response = Http::timeout(3)
                ->withHeaders([
                    'User-Agent' => 'TapItTrip/1.0 (https://tapittrip.internal; travel-companion)',
                    'Accept' => 'application/json',
                ])
                ->get('https://nominatim.openstreetmap.org/search', [
                    'q' => $query,
                    'format' => 'json',
                    'addressdetails' => 1,
                    'limit' => 5,
                ]);

            if (! $response->successful()) {
                return new Collection;
            }

            $items = $response->json();
            if (! is_array($items)) {
                return new Collection;
            }

            $created = [];
            foreach ($items as $item) {
                if (! isset($item['lat'], $item['lon'], $item['display_name'])) {
                    continue;
                }

                $displayName = (string) $item['display_name'];
                $parts = explode(',', $displayName);
                $name = ! empty($item['name']) ? (string) $item['name'] : trim($parts[0]);

                $countryCode = isset($item['address']['country_code'])
                    ? strtoupper((string) $item['address']['country_code'])
                    : null;

                $place = $this->createPlace(
                    new CreatePlaceData(
                        name: $name,
                        provider: 'osm',
                        providerPlaceId: (string) ($item['place_id'] ?? $item['osm_id'] ?? md5($displayName)),
                        formattedAddress: $displayName,
                        countryCode: $countryCode,
                        latitude: (float) $item['lat'],
                        longitude: (float) $item['lon'],
                        attribution: '© OpenStreetMap contributors',
                    )
                );

                $created[] = $place;
            }

            return new Collection($created);
        } catch (\Throwable $e) {
            Log::warning('Nominatim place search failed gracefully: '.$e->getMessage());

            return new Collection;
        }
    }

    /**
     * @return Collection<int, Place>
     */
    private function queryGooglePlaces(string $query, string $apiKey): Collection
    {
        try {
            $response = Http::timeout(3)->get('https://maps.googleapis.com/maps/api/place/textsearch/json', [
                'query' => $query,
                'key' => $apiKey,
            ]);

            if (! $response->successful()) {
                return new Collection;
            }

            $results = $response->json('results');
            if (! is_array($results)) {
                return new Collection;
            }

            $created = [];
            foreach (array_slice($results, 0, 5) as $result) {
                $lat = $result['geometry']['location']['lat'] ?? null;
                $lng = $result['geometry']['location']['lng'] ?? null;

                if ($lat === null || $lng === null) {
                    continue;
                }

                $place = $this->createPlace(
                    new CreatePlaceData(
                        name: (string) ($result['name'] ?? $query),
                        provider: 'google',
                        providerPlaceId: (string) ($result['place_id'] ?? ''),
                        formattedAddress: (string) ($result['formatted_address'] ?? ''),
                        latitude: (float) $lat,
                        longitude: (float) $lng,
                        attribution: 'Google Places',
                    )
                );

                $created[] = $place;
            }

            return new Collection($created);
        } catch (\Throwable $e) {
            Log::warning('Google Places search failed gracefully: '.$e->getMessage());

            return new Collection;
        }
    }
}
