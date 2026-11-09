<?php

declare(strict_types=1);

namespace App\Application\Lounges\Services;

use App\Domain\Lounges\Models\Airport;
use App\Domain\Lounges\Models\AirportLounge;
use App\Domain\Lounges\Models\AirportTerminal;
use Illuminate\Support\Facades\DB;

final class AirportLoungeDirectoryService
{
    /**
     * Known global airport hubs with terminals and lounges for instant auto-provisioning.
     *
     * @var array<string, array{airport: array<string, mixed>, terminals: array<string, string>, lounges: list<array<string, mixed>>}>
     */
    private const DIRECTORY = [
        'HND' => [
            'airport' => [
                'iata_code' => 'HND',
                'name' => 'Tokyo Haneda International Airport',
                'city' => 'Tokyo',
                'country' => 'Japan',
                'latitude' => 35.5494,
                'longitude' => 139.7798,
                'timezone' => 'Asia/Tokyo',
            ],
            'terminals' => [
                'T3' => 'Terminal 3 (International)',
                'T2' => 'Terminal 2',
                'T1' => 'Terminal 1',
            ],
            'lounges' => [
                [
                    'terminal' => 'T3',
                    'name' => 'TIAT Lounge (Terminal 3)',
                    'operator' => 'Tokyo International Air Terminal Corp',
                    'location_description' => 'Level 4, International Departures, near Gate 114',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['buffet', 'draft_beer', 'sake', 'showers', 'wifi', 'power_outlets', 'quiet_area'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 3850, 'currency' => 'JPY'],
                    'booking_url' => 'https://tokyo-haneda.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Showers require reservation at the front reception during peak hours.',
                ],
                [
                    'terminal' => 'T3',
                    'name' => 'Sky Lounge (Terminal 3)',
                    'operator' => 'TIAT',
                    'location_description' => 'Level 4, International Departures Central Area',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '06:00', 'close' => '01:00', 'is_24h' => false],
                    'amenities' => ['soft_drinks', 'snacks', 'wifi', 'power_outlets', 'runway_views'],
                    'access_methods' => ['credit_card', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 1050, 'currency' => 'JPY'],
                    'booking_url' => 'https://tokyo-haneda.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Alcoholic beverages available for purchase.',
                ],
                [
                    'terminal' => 'T3',
                    'name' => 'ANA Lounge (Terminal 3)',
                    'operator' => 'All Nippon Airways',
                    'location_description' => 'Level 4, near Gate 110',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '05:00', 'close' => '01:00', 'is_24h' => false],
                    'amenities' => ['noodle_bar', 'japanese_buffet', 'sake_bar', 'showers', 'wifi', 'quiet_zone'],
                    'access_methods' => ['star_alliance_gold', 'business_class', 'first_class', 'ana_diamond'],
                    'estimated_price' => null,
                    'booking_url' => 'https://www.ana.co.jp',
                    'transit_warning' => 'Allow 15 minutes to reach gates 140–148.',
                    'disclaimer' => 'Star Alliance international departure ticket required.',
                ],
                [
                    'terminal' => 'T3',
                    'name' => 'JAL Sakura Lounge (Terminal 3)',
                    'operator' => 'Japan Airlines',
                    'location_description' => 'Level 4, near Gate 112',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '04:30', 'close' => '02:00', 'is_24h' => false],
                    'amenities' => ['dining_buffet', 'beef_curry', 'showers', 'massage_chairs', 'bar', 'wifi'],
                    'access_methods' => ['oneworld_sapphire', 'oneworld_emerald', 'business_class', 'first_class'],
                    'estimated_price' => null,
                    'booking_url' => 'https://www.jal.co.jp',
                    'transit_warning' => null,
                    'disclaimer' => 'Oneworld departure boarding pass required.',
                ],
            ],
        ],
        'SIN' => [
            'airport' => [
                'iata_code' => 'SIN',
                'name' => 'Singapore Changi Airport',
                'city' => 'Singapore',
                'country' => 'Singapore',
                'latitude' => 1.3644,
                'longitude' => 103.9915,
                'timezone' => 'Asia/Singapore',
            ],
            'terminals' => [
                'T3' => 'Terminal 3',
                'T1' => 'Terminal 1',
                'T2' => 'Terminal 2',
            ],
            'lounges' => [
                [
                    'terminal' => 'T3',
                    'name' => 'Marhaba Lounge (T3)',
                    'operator' => 'dnata / Marhaba',
                    'location_description' => 'Level 3, Departure Transit Hall, near Gate A',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['hot_buffet', 'bar', 'showers', 'wifi', 'power_outlets', 'quiet_area'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 5500, 'currency' => 'SGD'],
                    'booking_url' => 'https://www.marhabaservices.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Complimentary 3-hour stay per Priority Pass entry.',
                ],
                [
                    'terminal' => 'T3',
                    'name' => 'SATS Premier Lounge (T3)',
                    'operator' => 'SATS Ltd',
                    'location_description' => 'Level 3, Departure Transit Hall, opposite gate A',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['laksa_station', 'buffet', 'massage_chairs', 'showers', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'business_class'],
                    'estimated_price' => ['amount_cents' => 6000, 'currency' => 'SGD'],
                    'booking_url' => 'https://www.sats.com.sg',
                    'transit_warning' => null,
                    'disclaimer' => 'Self-service laksa station available around the clock.',
                ],
                [
                    'terminal' => 'T1',
                    'name' => 'Plaza Premium Lounge (T1)',
                    'operator' => 'Plaza Premium Group',
                    'location_description' => 'Level 3, Departure Hall, above Gate C1',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['live_cooking', 'showers', 'singapore_chicken_rice', 'runway_views', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 6500, 'currency' => 'SGD'],
                    'booking_url' => 'https://www.plazapremiumlounge.com',
                    'transit_warning' => 'Inter-terminal skytrain connects T1, T2, and T3 inside airside security.',
                    'disclaimer' => 'Private nap suites available for an additional fee.',
                ],
            ],
        ],
        'BKK' => [
            'airport' => [
                'iata_code' => 'BKK',
                'name' => 'Suvarnabhumi Airport',
                'city' => 'Bangkok',
                'country' => 'Thailand',
                'latitude' => 13.6900,
                'longitude' => 100.7501,
                'timezone' => 'Asia/Bangkok',
            ],
            'terminals' => [
                'MT' => 'Main Terminal',
            ],
            'lounges' => [
                [
                    'terminal' => 'MT',
                    'name' => 'Miracle Lounge (Concourse D)',
                    'operator' => 'Miracle Group',
                    'location_description' => 'Level 3, Concourse D, opposite Gate D5',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['thai_buffet', 'open_bar', 'showers', 'wifi', 'outdoor_bamboo_garden'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 150000, 'currency' => 'THB'],
                    'booking_url' => 'https://www.miracletransithotel.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Largest independent lounge at BKK airport.',
                ],
                [
                    'terminal' => 'MT',
                    'name' => 'Coral Executive Lounge (Concourse C)',
                    'operator' => 'The Coral Lounge',
                    'location_description' => 'Level 3, Concourse C',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '06:00', 'close' => '00:00', 'is_24h' => false],
                    'amenities' => ['neck_shoulder_massage', 'afternoon_tea', 'buffet', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 140000, 'currency' => 'THB'],
                    'booking_url' => 'https://www.corallounge.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Complimentary 15-minute neck & shoulder massage included for guests.',
                ],
            ],
        ],
        'ICN' => [
            'airport' => [
                'iata_code' => 'ICN',
                'name' => 'Incheon International Airport',
                'city' => 'Seoul',
                'country' => 'South Korea',
                'latitude' => 37.4602,
                'longitude' => 126.4407,
                'timezone' => 'Asia/Seoul',
            ],
            'terminals' => [
                'T1' => 'Terminal 1',
                'T2' => 'Terminal 2',
            ],
            'lounges' => [
                [
                    'terminal' => 'T1',
                    'name' => 'Matina Lounge (Terminal 1)',
                    'operator' => 'Walkerhill',
                    'location_description' => '4th Floor, near Gate 11',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '07:00', 'close' => '22:00', 'is_24h' => false],
                    'amenities' => ['korean_buffet', 'bibimbap_bar', 'draft_beer', 'showers', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 39000, 'currency' => 'KRW'],
                    'booking_url' => 'https://www.walkerhill.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Awarded best airport lounge food in Korea.',
                ],
                [
                    'terminal' => 'T1',
                    'name' => 'Sky Hub Lounge (Terminal 1)',
                    'operator' => 'Pulmuone Food & Culture',
                    'location_description' => '4th Floor, East Wing near Gate 11',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '07:00', 'close' => '21:30', 'is_24h' => false],
                    'amenities' => ['korean_comfort_food', 'spicy_rice_cake', 'beverages', 'wifi'],
                    'access_methods' => ['priority_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 38000, 'currency' => 'KRW'],
                    'booking_url' => null,
                    'transit_warning' => null,
                    'disclaimer' => 'Peak wait times occur between 17:00 and 19:00.',
                ],
            ],
        ],
        'KIX' => [
            'airport' => [
                'iata_code' => 'KIX',
                'name' => 'Kansai International Airport',
                'city' => 'Osaka',
                'country' => 'Japan',
                'latitude' => 34.4347,
                'longitude' => 135.2442,
                'timezone' => 'Asia/Tokyo',
            ],
            'terminals' => [
                'T1' => 'Terminal 1',
            ],
            'lounges' => [
                [
                    'terminal' => 'T1',
                    'name' => 'KIX Airport Lounge NODOKA',
                    'operator' => 'Kansai Airports',
                    'location_description' => 'Aero Plaza 2nd Floor (Landside)',
                    'is_airside' => false,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['tatami_mats', 'shower_booths', 'soft_drinks', 'wifi', 'comic_library'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'credit_card', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 1650, 'currency' => 'JPY'],
                    'booking_url' => 'https://www.kansai-airport.or.jp',
                    'transit_warning' => 'Located LANDSIDE outside security in Aeroplaza. Allow 30 mins to clear security before flight.',
                    'disclaimer' => 'Boarding pass and valid ID required.',
                ],
            ],
        ],
        'DPS' => [
            'airport' => [
                'iata_code' => 'DPS',
                'name' => 'Ngurah Rai International Airport',
                'city' => 'Denpasar / Bali',
                'country' => 'Indonesia',
                'latitude' => -8.7482,
                'longitude' => 115.1672,
                'timezone' => 'Asia/Makassar',
            ],
            'terminals' => [
                'INT' => 'International Terminal',
            ],
            'lounges' => [
                [
                    'terminal' => 'INT',
                    'name' => 'Concordia Lounge Bali',
                    'operator' => 'PT Angkasa Pura Hotel',
                    'location_description' => 'Level 3, International Departure Hall, near Gate 2',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '06:00', 'close' => '01:00', 'is_24h' => false],
                    'amenities' => ['indonesian_buffet', 'bar', 'showers', 'wifi', 'reflexology_massage'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 35000000, 'currency' => 'IDR'],
                    'booking_url' => null,
                    'transit_warning' => null,
                    'disclaimer' => 'Showers and massage available on a first-come basis.',
                ],
            ],
        ],
        'SFO' => [
            'airport' => [
                'iata_code' => 'SFO',
                'name' => 'San Francisco International Airport',
                'city' => 'San Francisco',
                'country' => 'United States',
                'latitude' => 37.6213,
                'longitude' => -122.3790,
                'timezone' => 'America/Los_Angeles',
            ],
            'terminals' => [
                'INTL_A' => 'International Terminal A',
                'INTL_G' => 'International Terminal G',
            ],
            'lounges' => [
                [
                    'terminal' => 'INTL_A',
                    'name' => 'Golden Gate Lounge',
                    'operator' => 'SFO Airport Concessions',
                    'location_description' => 'International Terminal A, Concourse Level near Gate A1',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '07:00', 'close' => '23:30', 'is_24h' => false],
                    'amenities' => ['california_buffet', 'craft_beer', 'wine_bar', 'wifi', 'showers'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 5000, 'currency' => 'USD'],
                    'booking_url' => 'https://www.flysfo.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Accessible only from International Concourse A.',
                ],
            ],
        ],
        'LAX' => [
            'airport' => [
                'iata_code' => 'LAX',
                'name' => 'Los Angeles International Airport',
                'city' => 'Los Angeles',
                'country' => 'United States',
                'latitude' => 33.9416,
                'longitude' => -118.4085,
                'timezone' => 'America/Los_Angeles',
            ],
            'terminals' => [
                'TBIT' => 'Tom Bradley International Terminal',
            ],
            'lounges' => [
                [
                    'terminal' => 'TBIT',
                    'name' => 'KAL Lounge (TBIT)',
                    'operator' => 'Korean Air',
                    'location_description' => 'Level 5, Tom Bradley Terminal, above central atrium',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '07:30', 'close' => '23:00', 'is_24h' => false],
                    'amenities' => ['buffet', 'showers', 'outdoor_terrace', 'wifi', 'bar'],
                    'access_methods' => ['priority_pass', 'skyteam_elite_plus', 'business_class'],
                    'estimated_price' => null,
                    'booking_url' => 'https://www.koreanair.com',
                    'transit_warning' => 'Priority Pass access may be restricted during peak morning hours.',
                    'disclaimer' => 'Subject to capacity limits.',
                ],
            ],
        ],
    ];

    /**
     * Auto-provision an airport and its lounges on demand if not present in DB.
     */
    public static function autoProvision(string $iataCode): ?Airport
    {
        $iata = strtoupper(trim($iataCode));

        if (! isset(self::DIRECTORY[$iata])) {
            return null;
        }

        $config = self::DIRECTORY[$iata];

        return DB::transaction(function () use ($config, $iata): Airport {
            /** @var Airport $airport */
            $airport = Airport::updateOrCreate(
                ['iata_code' => $iata],
                $config['airport']
            );

            $terminals = [];
            foreach ($config['terminals'] as $code => $name) {
                $terminals[$code] = AirportTerminal::updateOrCreate(
                    ['airport_id' => $airport->id, 'code' => $code],
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

    /**
     * Provision all known directory airports into the database.
     */
    public static function provisionAll(): void
    {
        foreach (array_keys(self::DIRECTORY) as $iata) {
            self::autoProvision($iata);
        }
    }
}
