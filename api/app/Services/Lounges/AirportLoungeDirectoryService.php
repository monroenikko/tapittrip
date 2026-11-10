<?php

declare(strict_types=1);

namespace App\Services\Lounges;

use App\Models\Airport;
use App\Models\AirportLounge;
use App\Models\AirportTerminal;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

final class AirportLoungeDirectoryService
{
    /**
     * Get the airport catalog data from database/data storage.
     *
     * @return array{
     *     directory: array<string, array{airport: array<string, mixed>, terminals: array<string, string>, lounges: list<array<string, mixed>>}>,
     *     global_catalog: array<string, array{name: string, city: string, country: string, timezone: string, latitude: float, longitude: float, terminals: array<string, string>}>,
     *     search_aliases: array<string, string>
     * }
     */
    public static function getCatalogData(): array
    {
        return Cache::rememberForever('airports_catalog_data', function (): array {
            $path = database_path('data/airports_catalog.json');
            if (File::exists($path)) {
                $decoded = json_decode((string) File::get($path), true);
                if (is_array($decoded)) {
                    return [
                        'directory' => $decoded['directory'] ?? [],
                        'global_catalog' => $decoded['global_catalog'] ?? [],
                        'search_aliases' => $decoded['search_aliases'] ?? [],
                    ];
                }
            }

            return ['directory' => [], 'global_catalog' => [], 'search_aliases' => []];
        });
    }

    /**
     * Resolve a query or IATA code to canonical 3-letter IATA code.
     */
    public static function resolveIata(string $query): string
    {
        $clean = strtoupper(trim($query));

        if (strlen($clean) === 3) {
            return $clean;
        }

        $catalog = self::getCatalogData();
        foreach ($catalog['search_aliases'] as $alias => $code) {
            if (str_contains($clean, (string) $alias) || str_contains((string) $alias, $clean)) {
                return (string) $code;
            }
        }

        return $clean;
    }

    /**
     * Automatically provisions an airport, its terminals, and lounges into database if known.
     */
    public static function autoProvision(string $iataCode): ?Airport
    {
        $iata = self::resolveIata($iataCode);
        $catalog = self::getCatalogData();

        // 1. Direct rich directory match
        if (isset($catalog['directory'][$iata])) {
            $config = $catalog['directory'][$iata];

            return DB::transaction(function () use ($config, $iata): Airport {
                /** @var Airport $airport */
                $airport = Airport::updateOrCreate(
                    ['iata_code' => $iata],
                    $config['airport']
                );

                $terminals = [];
                foreach ($config['terminals'] as $code => $name) {
                    $terminals[$code] = AirportTerminal::updateOrCreate(
                        ['airport_id' => $airport->id, 'code' => (string) $code],
                        ['name' => $name]
                    );
                }

                foreach ($config['lounges'] as $loungeData) {
                    $termCode = $loungeData['terminal'];
                    $terminal = $terminals[$termCode] ?? null;

                    if ($terminal === null) {
                        continue;
                    }

                    $attrs = $loungeData;
                    unset($attrs['terminal']);

                    AirportLounge::updateOrCreate(
                        [
                            'airport_id' => $airport->id,
                            'terminal_id' => $terminal->id,
                            'name' => $loungeData['name'],
                        ],
                        $attrs
                    );
                }

                return $airport->load('terminals.lounges');
            });
        }

        // 2. Global Catalog Airport match
        if (isset($catalog['global_catalog'][$iata])) {
            $meta = $catalog['global_catalog'][$iata];

            return DB::transaction(function () use ($meta, $iata): Airport {
                /** @var Airport $airport */
                $airport = Airport::updateOrCreate(
                    ['iata_code' => $iata],
                    [
                        'iata_code' => $iata,
                        'name' => $meta['name'],
                        'city' => $meta['city'],
                        'country' => $meta['country'],
                        'timezone' => $meta['timezone'],
                        'latitude' => $meta['latitude'],
                        'longitude' => $meta['longitude'],
                    ]
                );

                foreach ($meta['terminals'] as $code => $name) {
                    $terminal = AirportTerminal::updateOrCreate(
                        ['airport_id' => $airport->id, 'code' => (string) $code],
                        ['name' => $name]
                    );

                    AirportLounge::updateOrCreate(
                        [
                            'airport_id' => $airport->id,
                            'terminal_id' => $terminal->id,
                            'name' => "{$meta['city']} Executive Lounge ({$name})",
                        ],
                        [
                            'operator' => 'Global Lounge Network & Partners',
                            'location_description' => "Post-security departures concourse, {$name}",
                            'is_airside' => true,
                            'opening_hours' => ['open' => '05:00', 'close' => '23:00', 'is_24h' => false],
                            'amenities' => ['buffet', 'beverages', 'wifi', 'charging_ports', 'showers'],
                            'access_methods' => ['priority_pass', 'lounge_key', 'dragon_pass', 'paid_walkin'],
                            'estimated_price' => ['amount_cents' => 4500, 'currency' => 'USD'],
                            'booking_url' => 'https://tapittrip.local/lounges',
                            'transit_warning' => null,
                            'disclaimer' => 'Valid departure boarding pass and photo identification required.',
                        ]
                    );
                }

                return $airport->load('terminals.lounges');
            });
        }

        return null;
    }

    /**
     * Search and list all supported airports and their terminals worldwide.
     *
     * @return list<array<string, mixed>>
     */
    public static function listGlobalAirports(?string $query = null): array
    {
        $results = [];
        $q = $query !== null ? strtoupper(trim($query)) : null;
        $catalog = self::getCatalogData();

        $all = [];
        foreach ($catalog['directory'] as $iata => $data) {
            $all[$iata] = [
                'iata_code' => $iata,
                'name' => $data['airport']['name'],
                'city' => $data['airport']['city'],
                'country' => $data['airport']['country'],
                'timezone' => $data['airport']['timezone'],
                'terminals' => array_map(
                    fn ($code, $name) => ['code' => (string) $code, 'name' => $name],
                    array_keys($data['terminals']),
                    array_values($data['terminals'])
                ),
            ];
        }

        foreach ($catalog['global_catalog'] as $iata => $meta) {
            if (! isset($all[$iata])) {
                $all[$iata] = [
                    'iata_code' => $iata,
                    'name' => $meta['name'],
                    'city' => $meta['city'],
                    'country' => $meta['country'],
                    'timezone' => $meta['timezone'],
                    'terminals' => array_map(
                        fn ($code, $name) => ['code' => (string) $code, 'name' => $name],
                        array_keys($meta['terminals']),
                        array_values($meta['terminals'])
                    ),
                ];
            }
        }

        foreach ($all as $item) {
            if ($q === null || $q === '') {
                $results[] = $item;

                continue;
            }

            $haystack = strtoupper("{$item['iata_code']} {$item['name']} {$item['city']} {$item['country']}");
            if (str_contains($haystack, $q)) {
                $results[] = $item;
            }
        }

        return $results;
    }

    /**
     * Provision all known directory airports into the database.
     */
    public static function provisionAll(): void
    {
        $catalog = self::getCatalogData();
        foreach (array_keys($catalog['directory']) as $iata) {
            self::autoProvision((string) $iata);
        }
        foreach (array_keys($catalog['global_catalog']) as $iata) {
            self::autoProvision((string) $iata);
        }
    }
}
