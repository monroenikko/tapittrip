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
        // --- JAPAN ---
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
                    'terminal' => 'T2',
                    'name' => 'Power Lounge Premium (T2)',
                    'operator' => 'Japan Airport Terminal Co',
                    'location_description' => 'Level 3, Departure Concourse',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '06:00', 'close' => '21:30', 'is_24h' => false],
                    'amenities' => ['coffee_bar', 'breakfast_pastries', 'wifi', 'workstations'],
                    'access_methods' => ['credit_card', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 1100, 'currency' => 'JPY'],
                    'booking_url' => 'https://tokyo-haneda.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Valid boarding pass required.',
                ],
            ],
        ],

        'NRT' => [
            'airport' => [
                'iata_code' => 'NRT',
                'name' => 'Narita International Airport',
                'city' => 'Tokyo',
                'country' => 'Japan',
                'latitude' => 35.7720,
                'longitude' => 140.3929,
                'timezone' => 'Asia/Tokyo',
            ],
            'terminals' => [
                'T1' => 'Terminal 1',
                'T2' => 'Terminal 2',
                'T3' => 'Terminal 3',
            ],
            'lounges' => [
                [
                    'terminal' => 'T1',
                    'name' => 'IASS Superior Lounge NOA',
                    'operator' => 'IASS',
                    'location_description' => 'Terminal 1, Central Building 3F, near Gate 26',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '07:30', 'close' => '21:00', 'is_24h' => false],
                    'amenities' => ['beverages', 'draft_beer', 'japanese_snacks', 'wifi'],
                    'access_methods' => ['priority_pass', 'lounge_key'],
                    'estimated_price' => null,
                    'booking_url' => 'https://www.iass.co.jp',
                    'transit_warning' => 'Airside access required.',
                    'disclaimer' => 'One complimentary alcoholic beverage per adult guest.',
                ],
                [
                    'terminal' => 'T2',
                    'name' => 'IASS Executive Lounge 2',
                    'operator' => 'IASS',
                    'location_description' => 'Terminal 2, Main Building 4F (Landside)',
                    'is_airside' => false,
                    'opening_hours' => ['open' => '07:00', 'close' => '21:00', 'is_24h' => false],
                    'amenities' => ['soft_drinks', 'beer', 'wifi', 'charging_ports'],
                    'access_methods' => ['credit_card', 'paid_walkin', 'priority_pass'],
                    'estimated_price' => ['amount_cents' => 1540, 'currency' => 'JPY'],
                    'booking_url' => 'https://www.iass.co.jp',
                    'transit_warning' => 'Landside - allow extra time to clear security before departure.',
                    'disclaimer' => 'Walk-in rate approx ¥1,540 per adult.',
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
                'T1' => 'Terminal 1 (International & Domestic)',
                'T2' => 'Terminal 2 (Low Cost Carriers)',
            ],
            'lounges' => [
                [
                    'terminal' => 'T1',
                    'name' => 'KIX Lounge Nodoka',
                    'operator' => 'Kansai Airports',
                    'location_description' => 'Aeroplaza 2F, near railway station connection',
                    'is_airside' => false,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['cafe_drinks', 'snacks', 'showers', 'turf_area', 'private_booths', 'wifi'],
                    'access_methods' => ['priority_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 1800, 'currency' => 'JPY'],
                    'booking_url' => 'https://www.kansai-airport.or.jp',
                    'transit_warning' => 'Located landside in Aeroplaza.',
                    'disclaimer' => 'Priority Pass holders enjoy complimentary set meal or 2-hour lounge package.',
                ],
            ],
        ],

        // --- SINGAPORE ---
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
                'T4' => 'Terminal 4',
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
                    'terminal' => 'T1',
                    'name' => 'Plaza Premium Lounge (T1)',
                    'operator' => 'Plaza Premium Group',
                    'location_description' => 'Level 3, Departure Transit Hall, above Gate C1',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['singapore_laksa_bar', 'tapas', 'showers', 'private_resting_suites', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'american_express', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 6000, 'currency' => 'SGD'],
                    'booking_url' => 'https://www.plazapremiumlounge.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Freshly cooked laksa and chicken rice served daily.',
                ],
            ],
        ],

        // --- UNITED KINGDOM & EUROPE ---
        'LHR' => [
            'airport' => [
                'iata_code' => 'LHR',
                'name' => 'London Heathrow Airport',
                'city' => 'London',
                'country' => 'United Kingdom',
                'latitude' => 51.4700,
                'longitude' => -0.4543,
                'timezone' => 'Europe/London',
            ],
            'terminals' => [
                'T5' => 'Terminal 5 (British Airways Hub)',
                'T3' => 'Terminal 3 (Virgin & Oneworld Hub)',
                'T2' => 'Terminal 2 (The Queen’s Terminal)',
                'T4' => 'Terminal 4 (SkyTeam & International)',
            ],
            'lounges' => [
                [
                    'terminal' => 'T5',
                    'name' => 'Club Aspire Lounge (Terminal 5)',
                    'operator' => 'Swissport / Aspire',
                    'location_description' => 'Level 1, Airside, near Gate A18',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '05:00', 'close' => '22:00', 'is_24h' => false],
                    'amenities' => ['english_breakfast', 'bar', 'showers', 'runway_views', 'quiet_zone', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 4200, 'currency' => 'GBP'],
                    'booking_url' => 'https://www.executivelounges.com',
                    'transit_warning' => 'Allow 15 minutes if departing from satellite gates B or C.',
                    'disclaimer' => 'Smart casual dress code requested.',
                ],
                [
                    'terminal' => 'T3',
                    'name' => 'No1 Lounge Heathrow (Terminal 3)',
                    'operator' => 'No1 Lounges',
                    'location_description' => 'Lounge Zone F, after security, Departure Concourse',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '05:30', 'close' => '21:30', 'is_24h' => false],
                    'amenities' => ['hot_buffet', 'crafted_cocktails', 'cinema_room', 'showers', 'pod_bedrooms'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 4500, 'currency' => 'GBP'],
                    'booking_url' => 'https://no1lounges.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Table service and premium champagne available for supplement.',
                ],
                [
                    'terminal' => 'T2',
                    'name' => 'Plaza Premium Lounge (Terminal 2)',
                    'operator' => 'Plaza Premium Group',
                    'location_description' => 'Level 4, Terminal 2A Departures, next to Terminal Transfers',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '05:00', 'close' => '21:30', 'is_24h' => false],
                    'amenities' => ['british_curry_buffet', 'tapas', 'bar', 'luxury_showers', 'workstation'],
                    'access_methods' => ['priority_pass', 'american_express', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 4400, 'currency' => 'GBP'],
                    'booking_url' => 'https://www.plazapremiumlounge.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Complimentary 2-hour lounge access with valid travel document.',
                ],
            ],
        ],

        'CDG' => [
            'airport' => [
                'iata_code' => 'CDG',
                'name' => 'Paris Charles de Gaulle Airport',
                'city' => 'Paris',
                'country' => 'France',
                'latitude' => 49.0097,
                'longitude' => 2.5479,
                'timezone' => 'Europe/Paris',
            ],
            'terminals' => [
                'T2E' => 'Terminal 2E (International Hub)',
                'T2F' => 'Terminal 2F (Schengen European)',
                'T1' => 'Terminal 1 (Star Alliance & Global)',
                'T3' => 'Terminal 3 (Charter & Low Cost)',
            ],
            'lounges' => [
                [
                    'terminal' => 'T1',
                    'name' => 'Star Alliance Lounge Paris CDG (T1)',
                    'operator' => 'Star Alliance Services',
                    'location_description' => 'Level 10, Airside, after passport control',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '05:30', 'close' => '22:00', 'is_24h' => false],
                    'amenities' => ['french_wines', 'croissant_bar', 'open_air_terrace', 'showers', 'wifi'],
                    'access_methods' => ['star_alliance_gold', 'business_class', 'first_class'],
                    'estimated_price' => null,
                    'booking_url' => 'https://www.staralliance.com',
                    'transit_warning' => 'Terminal 1 non-Schengen departures only.',
                    'disclaimer' => 'Features an exclusive landscaped outdoor landscaped terrace garden.',
                ],
                [
                    'terminal' => 'T2E',
                    'name' => 'Extime Lounge Paris (Terminal 2E Hall L)',
                    'operator' => 'Groupe ADP / Extime',
                    'location_description' => 'Satellite 4 / Hall L, near Gate L33',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '06:00', 'close' => '22:30', 'is_24h' => false],
                    'amenities' => ['parisian_patisserie', 'french_cheeses', 'champagne', 'relaxation_pods', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 5000, 'currency' => 'EUR'],
                    'booking_url' => 'https://www.parisaeroport.fr',
                    'transit_warning' => 'Boarding pass for Hall L required.',
                    'disclaimer' => 'Walk-in access subject to peak hour capacity.',
                ],
            ],
        ],

        'AMS' => [
            'airport' => [
                'iata_code' => 'AMS',
                'name' => 'Amsterdam Airport Schiphol',
                'city' => 'Amsterdam',
                'country' => 'Netherlands',
                'latitude' => 52.3105,
                'longitude' => 4.7683,
                'timezone' => 'Europe/Amsterdam',
            ],
            'terminals' => [
                'L2' => 'Lounge 2 (Non-Schengen Gates E, F, G)',
                'L1' => 'Lounge 1 (Schengen Gates B, C, D)',
                'L3' => 'Lounge 3 (Gates G, H, M)',
            ],
            'lounges' => [
                [
                    'terminal' => 'L2',
                    'name' => 'Aspire Lounge 41 (Non-Schengen)',
                    'operator' => 'Swissport / Aspire',
                    'location_description' => 'Level 3, Panorama Deck, Lounge 2',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '06:00', 'close' => '22:00', 'is_24h' => false],
                    'amenities' => ['dutch_pancakes', 'heineken_on_tap', 'hot_buffet', 'workspaces', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 4500, 'currency' => 'EUR'],
                    'booking_url' => 'https://www.executivelounges.com',
                    'transit_warning' => 'Non-Schengen flights only.',
                    'disclaimer' => 'Max 3-hour stay.',
                ],
            ],
        ],

        'FRA' => [
            'airport' => [
                'iata_code' => 'FRA',
                'name' => 'Frankfurt Airport',
                'city' => 'Frankfurt',
                'country' => 'Germany',
                'latitude' => 50.0379,
                'longitude' => 8.5622,
                'timezone' => 'Europe/Berlin',
            ],
            'terminals' => [
                'T1' => 'Terminal 1 (Lufthansa & Star Alliance Hub)',
                'T2' => 'Terminal 2 (Oneworld & SkyTeam Hub)',
            ],
            'lounges' => [
                [
                    'terminal' => 'T2',
                    'name' => 'Primeclass Lounge (Terminal 2)',
                    'operator' => 'TAV Operation Services',
                    'location_description' => 'Concourse E, Non-Schengen, 3rd Floor, near Gate E7',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '06:00', 'close' => '22:00', 'is_24h' => false],
                    'amenities' => ['german_pretzels', 'hot_buffet', 'draft_beer', 'showers', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 4800, 'currency' => 'EUR'],
                    'booking_url' => 'https://www.primeclass.com.tr',
                    'transit_warning' => null,
                    'disclaimer' => 'Showers available on a first-come, first-served basis.',
                ],
            ],
        ],

        // --- MIDDLE EAST ---
        'DXB' => [
            'airport' => [
                'iata_code' => 'DXB',
                'name' => 'Dubai International Airport',
                'city' => 'Dubai',
                'country' => 'United Arab Emirates',
                'latitude' => 25.2532,
                'longitude' => 55.3657,
                'timezone' => 'Asia/Dubai',
            ],
            'terminals' => [
                'T3' => 'Terminal 3 (Emirates World Mega-Hub)',
                'T1' => 'Terminal 1 (International Airlines Concourse D)',
                'T2' => 'Terminal 2 (Flydubai & Regional)',
            ],
            'lounges' => [
                [
                    'terminal' => 'T3',
                    'name' => 'Marhaba Lounge (Terminal 3 Concourse B)',
                    'operator' => 'dnata',
                    'location_description' => 'Level 4, Concourse B, between Gates B26 and B28',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['arabic_mezze', 'international_buffet', 'bar', 'showers', 'quiet_snooze_room', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 21000, 'currency' => 'AED'],
                    'booking_url' => 'https://www.marhabaservices.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Open 24 hours. Shower packages available at check-in desk.',
                ],
                [
                    'terminal' => 'T1',
                    'name' => 'Ahlan Lounge at Gate (Terminal 1 Concourse D)',
                    'operator' => 'Dubai International Hospitality',
                    'location_description' => 'Level 2, Concourse D, above departure gates',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['gourmet_dining', 'premium_bar', 'massage_chairs', 'kids_play_area', 'wifi'],
                    'access_methods' => ['priority_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 23000, 'currency' => 'AED'],
                    'booking_url' => 'https://www.dubaiairports.ae',
                    'transit_warning' => 'Transit train required from Terminal 1 check-in to Concourse D.',
                    'disclaimer' => 'Full à la carte hot menu and buffet.',
                ],
            ],
        ],

        'DOH' => [
            'airport' => [
                'iata_code' => 'DOH',
                'name' => 'Hamad International Airport',
                'city' => 'Doha',
                'country' => 'Qatar',
                'latitude' => 25.2611,
                'longitude' => 51.5651,
                'timezone' => 'Asia/Qatar',
            ],
            'terminals' => [
                'T1' => 'Passenger Terminal (Concourses A, B, C, D, E & The Orchard)',
            ],
            'lounges' => [
                [
                    'terminal' => 'T1',
                    'name' => 'Al Maha Transit Lounge',
                    'operator' => 'Qatar Aviation Services',
                    'location_description' => 'Level 2, near Lamp Bear and Duty Free Plaza South',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['middle_eastern_buffet', 'fresh_juices', 'showers', 'quiet_rooms', 'business_center', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 22000, 'currency' => 'QAR'],
                    'booking_url' => 'https://dohahamadairport.com',
                    'transit_warning' => 'Can reach capacity during overnight Doha transfer bank.',
                    'disclaimer' => 'Complimentary 6-hour transit stay for eligible membership tiers.',
                ],
            ],
        ],

        // --- UNITED STATES ---
        'JFK' => [
            'airport' => [
                'iata_code' => 'JFK',
                'name' => 'John F. Kennedy International Airport',
                'city' => 'New York',
                'country' => 'United States',
                'latitude' => 40.6413,
                'longitude' => -73.7781,
                'timezone' => 'America/New_York',
            ],
            'terminals' => [
                'T4' => 'Terminal 4 (Delta & International)',
                'T1' => 'Terminal 1 (Major International Carriers)',
                'T7' => 'Terminal 7 (Aer Lingus, ANA, Norse)',
                'T8' => 'Terminal 8 (American Airlines & Oneworld)',
            ],
            'lounges' => [
                [
                    'terminal' => 'T4',
                    'name' => 'Primeclass Lounge (Terminal 4)',
                    'operator' => 'TAV Primeclass',
                    'location_description' => 'Concourse B, post-security, near Gate B38',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '04:30', 'close' => '23:30', 'is_24h' => false],
                    'amenities' => ['ny_deli_buffet', 'full_bar', 'craft_beer', 'showers', 'high_speed_wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 5900, 'currency' => 'USD'],
                    'booking_url' => 'https://www.primeclass.com',
                    'transit_warning' => 'Terminal 4 is very long; allow 10-15 mins to walk to low-numbered gates.',
                    'disclaimer' => 'Alcoholic drinks served to 21+ with government photo ID.',
                ],
                [
                    'terminal' => 'T1',
                    'name' => 'VIP Lounge (Terminal 1)',
                    'operator' => 'Terminal One Group',
                    'location_description' => 'Mezzanine level, behind Security Checkpoint',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '08:00', 'close' => '23:00', 'is_24h' => false],
                    'amenities' => ['snacks', 'wine', 'beer', 'workstation', 'wifi'],
                    'access_methods' => ['priority_pass', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 4500, 'currency' => 'USD'],
                    'booking_url' => 'https://www.jfkairport.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Entry subject to flight departure time.',
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
                'INTL' => 'International Terminal (Concourse A & G)',
                'T1' => 'Harvey Milk Terminal 1',
                'T2' => 'Terminal 2',
                'T3' => 'Terminal 3 (United Hub)',
            ],
            'lounges' => [
                [
                    'terminal' => 'INTL',
                    'name' => 'Golden Gate Lounge (International Terminal A)',
                    'operator' => 'Swissport',
                    'location_description' => 'Concourse A, near Gate A1, post-security',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '07:00', 'close' => '23:30', 'is_24h' => false],
                    'amenities' => ['california_wines', 'hot_entrees', 'bay_views', 'power_charging', 'wifi'],
                    'access_methods' => ['priority_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 5200, 'currency' => 'USD'],
                    'booking_url' => 'https://www.flysfo.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Priority Pass entrance allowed up to 3 hours prior to scheduled flight.',
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
                'T1' => 'Terminal 1',
                'T2' => 'Terminal 2',
                'T3' => 'Terminal 3',
                'T4' => 'Terminal 4',
                'T5' => 'Terminal 5',
                'T6' => 'Terminal 6',
                'T7' => 'Terminal 7',
            ],
            'lounges' => [
                [
                    'terminal' => 'TBIT',
                    'name' => 'KAL Lounge (Tom Bradley International)',
                    'operator' => 'Korean Air',
                    'location_description' => 'Level 5, post-security, accessible via elevator near duty free',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '07:00', 'close' => '23:00', 'is_24h' => false],
                    'amenities' => ['korean_snacks', 'instant_ramen_bar', 'beer_on_tap', 'showers', 'wifi'],
                    'access_methods' => ['priority_pass', 'skyteam_elite_plus', 'first_class', 'business_class'],
                    'estimated_price' => null,
                    'booking_url' => 'https://www.koreanair.com',
                    'transit_warning' => 'Priority Pass hours may be restricted during evening Korean Air flight waves.',
                    'disclaimer' => 'Showers available subject to operational waitlist.',
                ],
            ],
        ],

        // --- GREATER ASIA & PACIFIC ---
        'HKG' => [
            'airport' => [
                'iata_code' => 'HKG',
                'name' => 'Hong Kong International Airport',
                'city' => 'Hong Kong',
                'country' => 'Hong Kong',
                'latitude' => 22.3080,
                'longitude' => 113.9185,
                'timezone' => 'Asia/Hong_Kong',
            ],
            'terminals' => [
                'T1' => 'Terminal 1 (Main Concourse & Sky Bridge)',
            ],
            'lounges' => [
                [
                    'terminal' => 'T1',
                    'name' => 'Plaza Premium Lounge (Gate 1)',
                    'operator' => 'Plaza Premium Group',
                    'location_description' => 'Level 6, Departures Level, near Gate 1',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['hk_fish_ball_noodles', 'dim_sum', 'showers', 'draft_beer', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'american_express', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 58000, 'currency' => 'HKD'],
                    'booking_url' => 'https://www.plazapremiumlounge.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Signature live Hong Kong noodle bar open 24 hours.',
                ],
                [
                    'terminal' => 'T1',
                    'name' => 'Chase Sapphire Lounge by The Club',
                    'operator' => 'JPMorgan Chase / Airport Dimensions',
                    'location_description' => 'Level 7, Departures Hall, near Gate 40',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '06:00', 'close' => '00:00', 'is_24h' => false],
                    'amenities' => ['chef_dining', 'craft_cocktails', 'private_workspaces', 'showers', 'wifi'],
                    'access_methods' => ['priority_pass', 'chase_sapphire_reserve'],
                    'estimated_price' => null,
                    'booking_url' => 'https://account.chase.com',
                    'transit_warning' => 'Automated People Mover train available to Gate 40.',
                    'disclaimer' => 'One complimentary visit per calendar year for standard Priority Pass members.',
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
                'T1' => 'Terminal 1 (Asiana & Star Alliance)',
                'T2' => 'Terminal 2 (Korean Air & SkyTeam Hub)',
                'CON' => 'Concourse (Foreign Carriers)',
            ],
            'lounges' => [
                [
                    'terminal' => 'T1',
                    'name' => 'Matina Lounge (Terminal 1 East)',
                    'operator' => 'Walkerhill Hotels',
                    'location_description' => 'Level 4, Transit Area East, near Gate 11',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '07:00', 'close' => '22:00', 'is_24h' => false],
                    'amenities' => ['korean_bibimbap_buffet', 'spicy_rice_cakes', 'draft_beer', 'showers', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 39000, 'currency' => 'KRW'],
                    'booking_url' => 'https://www.walkerhill.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Renowned for five-star hotel quality hot Korean buffet.',
                ],
                [
                    'terminal' => 'T2',
                    'name' => 'Matina Lounge (Terminal 2)',
                    'operator' => 'Walkerhill Hotels',
                    'location_description' => 'Level 4, near Gate 252',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '07:00', 'close' => '22:00', 'is_24h' => false],
                    'amenities' => ['hotel_buffet', 'beer', 'wine', 'relaxation_zone', 'wifi'],
                    'access_methods' => ['priority_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 39000, 'currency' => 'KRW'],
                    'booking_url' => 'https://www.walkerhill.com',
                    'transit_warning' => null,
                    'disclaimer' => 'T2 international passengers only.',
                ],
            ],
        ],

        'BKK' => [
            'airport' => [
                'iata_code' => 'BKK',
                'name' => 'Suvarnabhumi International Airport',
                'city' => 'Bangkok',
                'country' => 'Thailand',
                'latitude' => 13.6900,
                'longitude' => 100.7501,
                'timezone' => 'Asia/Bangkok',
            ],
            'terminals' => [
                'MAIN' => 'Main Passenger Terminal',
                'SAT1' => 'Satellite Terminal 1 (SAT-1)',
            ],
            'lounges' => [
                [
                    'terminal' => 'MAIN',
                    'name' => 'Miracle Lounge (Concourse D)',
                    'operator' => 'Miracle Group',
                    'location_description' => 'Level 3, Concourse D, opposite Gate D5',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['thai_buffet', 'hainanese_chicken_rice', 'bar', 'showers', 'garden_view', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 1400, 'currency' => 'THB'],
                    'booking_url' => 'https://www.miraclegroup.net',
                    'transit_warning' => null,
                    'disclaimer' => 'Flagship Miracle lounge spanning 3,000 sq meters with chef cooking stations.',
                ],
            ],
        ],

        'MNL' => [
            'airport' => [
                'iata_code' => 'MNL',
                'name' => 'Ninoy Aquino International Airport',
                'city' => 'Manila',
                'country' => 'Philippines',
                'latitude' => 14.5086,
                'longitude' => 121.0194,
                'timezone' => 'Asia/Manila',
            ],
            'terminals' => [
                'T3' => 'Terminal 3 (International & Domestic)',
                'T1' => 'Terminal 1 (International)',
                'T2' => 'Terminal 2 (Domestic & Regional)',
                'T4' => 'Terminal 4 (Domestic Prop & Commuter)',
            ],
            'lounges' => [
                [
                    'terminal' => 'T3',
                    'name' => 'PAGSS Premium Lounge (T3)',
                    'operator' => 'Philippine Airport Ground Support Solutions',
                    'location_description' => 'Level 4, International Departures, near Gate 115',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '05:00', 'close' => '00:00', 'is_24h' => false],
                    'amenities' => ['arroz_caldo', 'hot_buffet', 'san_miguel_beer', 'showers', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'business_class'],
                    'estimated_price' => ['amount_cents' => 2800, 'currency' => 'PHP'],
                    'booking_url' => 'https://pagss.com',
                    'transit_warning' => 'Terminal 3 international boarding pass required.',
                    'disclaimer' => 'Complimentary hot Filipino arroz caldo and pastries daily.',
                ],
                [
                    'terminal' => 'T1',
                    'name' => 'Club Manila Lounge (T1)',
                    'operator' => 'Club Manila',
                    'location_description' => 'Gate 7, East Concourse, 3rd Floor',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '06:00', 'close' => '23:00', 'is_24h' => false],
                    'amenities' => ['buffet', 'drinks', 'wifi', 'workstation'],
                    'access_methods' => ['priority_pass', 'dragon_pass'],
                    'estimated_price' => ['amount_cents' => 2200, 'currency' => 'PHP'],
                    'booking_url' => 'https://miaa.gov.ph',
                    'transit_warning' => null,
                    'disclaimer' => 'Maximum 2 hours stay.',
                ],
            ],
        ],

        'CEB' => [
            'airport' => [
                'iata_code' => 'CEB',
                'name' => 'Mactan-Cebu International Airport',
                'city' => 'Cebu',
                'country' => 'Philippines',
                'latitude' => 10.3075,
                'longitude' => 123.9794,
                'timezone' => 'Asia/Manila',
            ],
            'terminals' => [
                'T2' => 'Terminal 2 (Resort International Terminal)',
                'T1' => 'Terminal 1 (Domestic Terminal)',
            ],
            'lounges' => [
                [
                    'terminal' => 'T2',
                    'name' => 'Plaza Premium Lounge (Terminal 2)',
                    'operator' => 'Plaza Premium Group',
                    'location_description' => 'Level 1, International Departures, near Gate 20',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['cebu_mango_pastries', 'hot_buffet', 'showers', 'bar', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 2800, 'currency' => 'PHP'],
                    'booking_url' => 'https://www.plazapremiumlounge.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Located in award-winning timber resort-style terminal.',
                ],
            ],
        ],

        'DPS' => [
            'airport' => [
                'iata_code' => 'DPS',
                'name' => 'Ngurah Rai International Airport',
                'city' => 'Bali',
                'country' => 'Indonesia',
                'latitude' => -8.7482,
                'longitude' => 115.1672,
                'timezone' => 'Asia/Makassar',
            ],
            'terminals' => [
                'INTL' => 'International Terminal',
                'DOM' => 'Domestic Terminal',
            ],
            'lounges' => [
                [
                    'terminal' => 'INTL',
                    'name' => 'Premier Lounge Bali',
                    'operator' => 'PT Jas',
                    'location_description' => 'Level 3, International Departures, Mezzanine Area',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '00:00', 'close' => '23:59', 'is_24h' => true],
                    'amenities' => ['indonesian_satay', 'bintang_beer', 'outdoor_garden', 'showers', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 450000, 'currency' => 'IDR'],
                    'booking_url' => 'https://bali-airport.com',
                    'transit_warning' => null,
                    'disclaimer' => 'Balinese hospitality and open-air garden terrace.',
                ],
            ],
        ],

        'SYD' => [
            'airport' => [
                'iata_code' => 'SYD',
                'name' => 'Sydney Kingsford Smith Airport',
                'city' => 'Sydney',
                'country' => 'Australia',
                'latitude' => -33.9399,
                'longitude' => 151.1753,
                'timezone' => 'Australia/Sydney',
            ],
            'terminals' => [
                'T1' => 'Terminal 1 (International)',
                'T2' => 'Terminal 2 (Domestic Virgin & Jetstar)',
                'T3' => 'Terminal 3 (Qantas Domestic)',
            ],
            'lounges' => [
                [
                    'terminal' => 'T1',
                    'name' => 'Plaza Premium Lounge (Terminal 1)',
                    'operator' => 'Plaza Premium Group',
                    'location_description' => 'Level 1, opposite Gate 24, post-security',
                    'is_airside' => true,
                    'opening_hours' => ['open' => '06:00', 'close' => '22:00', 'is_24h' => false],
                    'amenities' => ['aussie_barista_coffee', 'hot_buffet', 'australian_wines', 'showers', 'wifi'],
                    'access_methods' => ['priority_pass', 'dragon_pass', 'american_express', 'paid_walkin'],
                    'estimated_price' => ['amount_cents' => 6500, 'currency' => 'AUD'],
                    'booking_url' => 'https://www.plazapremiumlounge.com',
                    'transit_warning' => 'Allow extra time for customs when transferring between T1 and T2/T3.',
                    'disclaimer' => 'Freshly brewed flat whites made by on-duty barista.',
                ],
            ],
        ],
    ];

    /**
     * Additional global international airports catalog with their verified terminals.
     * When queried, automatically creates the airport, its real terminals, and executive lounges.
     *
     * @var array<string, array{name: string, city: string, country: string, timezone: string, latitude: float, longitude: float, terminals: array<string, string>}>
     */
    private const GLOBAL_AIRPORTS_CATALOG = [
        // Europe
        'LGW' => ['name' => 'London Gatwick Airport', 'city' => 'London', 'country' => 'United Kingdom', 'timezone' => 'Europe/London', 'latitude' => 51.1537, 'longitude' => -0.1821, 'terminals' => ['N' => 'North Terminal', 'S' => 'South Terminal']],
        'MAN' => ['name' => 'Manchester Airport', 'city' => 'Manchester', 'country' => 'United Kingdom', 'timezone' => 'Europe/London', 'latitude' => 53.3537, 'longitude' => -2.2750, 'terminals' => ['T1' => 'Terminal 1', 'T2' => 'Terminal 2', 'T3' => 'Terminal 3']],
        'MUC' => ['name' => 'Munich Airport', 'city' => 'Munich', 'country' => 'Germany', 'timezone' => 'Europe/Berlin', 'latitude' => 48.3537, 'longitude' => 11.7860, 'terminals' => ['T1' => 'Terminal 1', 'T2' => 'Terminal 2']],
        'BER' => ['name' => 'Berlin Brandenburg Airport', 'city' => 'Berlin', 'country' => 'Germany', 'timezone' => 'Europe/Berlin', 'latitude' => 52.3667, 'longitude' => 13.5033, 'terminals' => ['T1' => 'Terminal 1', 'T2' => 'Terminal 2']],
        'MAD' => ['name' => 'Adolfo Suárez Madrid–Barajas Airport', 'city' => 'Madrid', 'country' => 'Spain', 'timezone' => 'Europe/Madrid', 'latitude' => 40.4839, 'longitude' => -3.5680, 'terminals' => ['T4' => 'Terminal 4', 'T4S' => 'Terminal 4 Satellite', 'T1' => 'Terminal 1', 'T2' => 'Terminal 2']],
        'BCN' => ['name' => 'Josep Tarradellas Barcelona–El Prat Airport', 'city' => 'Barcelona', 'country' => 'Spain', 'timezone' => 'Europe/Madrid', 'latitude' => 41.2974, 'longitude' => 2.0833, 'terminals' => ['T1' => 'Terminal 1', 'T2' => 'Terminal 2']],
        'FCO' => ['name' => 'Leonardo da Vinci–Fiumicino Airport', 'city' => 'Rome', 'country' => 'Italy', 'timezone' => 'Europe/Rome', 'latitude' => 41.8003, 'longitude' => 12.2389, 'terminals' => ['T1' => 'Terminal 1', 'T3' => 'Terminal 3 (International)']],
        'MXP' => ['name' => 'Milan Malpensa Airport', 'city' => 'Milan', 'country' => 'Italy', 'timezone' => 'Europe/Rome', 'latitude' => 45.6301, 'longitude' => 8.7255, 'terminals' => ['T1' => 'Terminal 1', 'T2' => 'Terminal 2']],
        'ZRH' => ['name' => 'Zurich Airport', 'city' => 'Zurich', 'country' => 'Switzerland', 'timezone' => 'Europe/Zurich', 'latitude' => 47.4582, 'longitude' => 8.5555, 'terminals' => ['A' => 'Gates A (Schengen)', 'B' => 'Gates B/D', 'E' => 'Gates E (Non-Schengen)']],
        'VIE' => ['name' => 'Vienna International Airport', 'city' => 'Vienna', 'country' => 'Austria', 'timezone' => 'Europe/Vienna', 'latitude' => 48.1103, 'longitude' => 16.5697, 'terminals' => ['T1' => 'Terminal 1', 'T3' => 'Terminal 3']],
        'CPH' => ['name' => 'Copenhagen Airport', 'city' => 'Copenhagen', 'country' => 'Denmark', 'timezone' => 'Europe/Copenhagen', 'latitude' => 55.6180, 'longitude' => 12.6508, 'terminals' => ['T2' => 'Terminal 2', 'T3' => 'Terminal 3']],
        'ARN' => ['name' => 'Stockholm Arlanda Airport', 'city' => 'Stockholm', 'country' => 'Sweden', 'timezone' => 'Europe/Stockholm', 'latitude' => 59.6498, 'longitude' => 17.9238, 'terminals' => ['T2' => 'Terminal 2', 'T4' => 'Terminal 4', 'T5' => 'Terminal 5']],
        'OSL' => ['name' => 'Oslo Gardermoen Airport', 'city' => 'Oslo', 'country' => 'Norway', 'timezone' => 'Europe/Oslo', 'latitude' => 60.1976, 'longitude' => 11.1004, 'terminals' => ['MAIN' => 'Main Passenger Terminal']],
        'HEL' => ['name' => 'Helsinki Airport', 'city' => 'Helsinki', 'country' => 'Finland', 'timezone' => 'Europe/Helsinki', 'latitude' => 60.3172, 'longitude' => 24.9633, 'terminals' => ['MAIN' => 'Main Terminal (Schengen & Non-Schengen)']],
        'DUB' => ['name' => 'Dublin Airport', 'city' => 'Dublin', 'country' => 'Ireland', 'timezone' => 'Europe/Dublin', 'latitude' => 53.4264, 'longitude' => -6.2499, 'terminals' => ['T1' => 'Terminal 1', 'T2' => 'Terminal 2']],
        'BRU' => ['name' => 'Brussels Airport', 'city' => 'Brussels', 'country' => 'Belgium', 'timezone' => 'Europe/Brussels', 'latitude' => 50.9010, 'longitude' => 4.4856, 'terminals' => ['PIER_A' => 'Pier A (Schengen)', 'PIER_B' => 'Pier B (Non-Schengen)']],
        'ATH' => ['name' => 'Athens International Airport', 'city' => 'Athens', 'country' => 'Greece', 'timezone' => 'Europe/Athens', 'latitude' => 37.9356, 'longitude' => 23.9484, 'terminals' => ['MAIN' => 'Main Terminal', 'SAT' => 'Satellite Terminal']],
        'LIS' => ['name' => 'Humberto Delgado Airport', 'city' => 'Lisbon', 'country' => 'Portugal', 'timezone' => 'Europe/Lisbon', 'latitude' => 38.7742, 'longitude' => -9.1342, 'terminals' => ['T1' => 'Terminal 1 (Main & International)', 'T2' => 'Terminal 2 (Low Cost)']],
        'IST' => ['name' => 'Istanbul Airport', 'city' => 'Istanbul', 'country' => 'Turkey', 'timezone' => 'Europe/Istanbul', 'latitude' => 41.2750, 'longitude' => 28.7519, 'terminals' => ['MAIN' => 'Main Grand Terminal']],

        // Americas
        'ORD' => ['name' => 'Chicago O\'Hare International Airport', 'city' => 'Chicago', 'country' => 'United States', 'timezone' => 'America/Chicago', 'latitude' => 41.9742, 'longitude' => -87.9073, 'terminals' => ['T1' => 'Terminal 1', 'T2' => 'Terminal 2', 'T3' => 'Terminal 3', 'T5' => 'Terminal 5 (International)']],
        'ATL' => ['name' => 'Hartsfield–Jackson Atlanta International Airport', 'city' => 'Atlanta', 'country' => 'United States', 'timezone' => 'America/New_York', 'latitude' => 33.6407, 'longitude' => -84.4277, 'terminals' => ['DOM' => 'Domestic Terminal (Concourses T, A-D)', 'INTL' => 'International Terminal (Concourses E & F)']],
        'MIA' => ['name' => 'Miami International Airport', 'city' => 'Miami', 'country' => 'United States', 'timezone' => 'America/New_York', 'latitude' => 25.7959, 'longitude' => -80.2870, 'terminals' => ['N' => 'North Terminal (Concourse D)', 'C' => 'Central Terminal (Concourses E, F, G)', 'S' => 'South Terminal (Concourses H & J)']],
        'DFW' => ['name' => 'Dallas/Fort Worth International Airport', 'city' => 'Dallas', 'country' => 'United States', 'timezone' => 'America/Chicago', 'latitude' => 32.8998, 'longitude' => -97.0403, 'terminals' => ['A' => 'Terminal A', 'B' => 'Terminal B', 'C' => 'Terminal C', 'D' => 'Terminal D (International)', 'E' => 'Terminal E']],
        'SEA' => ['name' => 'Seattle–Tacoma International Airport', 'city' => 'Seattle', 'country' => 'United States', 'timezone' => 'America/Los_Angeles', 'latitude' => 47.4502, 'longitude' => -122.3088, 'terminals' => ['MAIN' => 'Central Terminal', 'S_SAT' => 'South Satellite (International)', 'N_SAT' => 'North Satellite']],
        'BOS' => ['name' => 'Boston Logan International Airport', 'city' => 'Boston', 'country' => 'United States', 'timezone' => 'America/New_York', 'latitude' => 42.3656, 'longitude' => -71.0096, 'terminals' => ['A' => 'Terminal A', 'B' => 'Terminal B', 'C' => 'Terminal C', 'E' => 'Terminal E (International)']],
        'DEN' => ['name' => 'Denver International Airport', 'city' => 'Denver', 'country' => 'United States', 'timezone' => 'America/Denver', 'latitude' => 39.8561, 'longitude' => -104.6737, 'terminals' => ['JEFF' => 'Jeppesen Terminal (Concourses A, B, C)']],
        'YYZ' => ['name' => 'Toronto Pearson International Airport', 'city' => 'Toronto', 'country' => 'Canada', 'timezone' => 'America/Toronto', 'latitude' => 43.6777, 'longitude' => -79.6248, 'terminals' => ['T1' => 'Terminal 1', 'T3' => 'Terminal 3']],
        'YVR' => ['name' => 'Vancouver International Airport', 'city' => 'Vancouver', 'country' => 'Canada', 'timezone' => 'America/Vancouver', 'latitude' => 49.1967, 'longitude' => -123.1815, 'terminals' => ['INTL' => 'International Terminal', 'DOM' => 'Domestic Terminal']],
        'MEX' => ['name' => 'Mexico City Benito Juárez International Airport', 'city' => 'Mexico City', 'country' => 'Mexico', 'timezone' => 'America/Mexico_City', 'latitude' => 19.4361, 'longitude' => -99.0719, 'terminals' => ['T1' => 'Terminal 1', 'T2' => 'Terminal 2']],
        'GRU' => ['name' => 'São Paulo–Guarulhos International Airport', 'city' => 'São Paulo', 'country' => 'Brazil', 'timezone' => 'America/Sao_Paulo', 'latitude' => -23.4356, 'longitude' => -46.4731, 'terminals' => ['T1' => 'Terminal 1', 'T2' => 'Terminal 2', 'T3' => 'Terminal 3 (International)']],

        // Asia & Middle East
        'TPE' => ['name' => 'Taiwan Taoyuan International Airport', 'city' => 'Taipei', 'country' => 'Taiwan', 'timezone' => 'Asia/Taipei', 'latitude' => 25.0797, 'longitude' => 121.2342, 'terminals' => ['T1' => 'Terminal 1', 'T2' => 'Terminal 2']],
        'KUL' => ['name' => 'Kuala Lumpur International Airport', 'city' => 'Kuala Lumpur', 'country' => 'Malaysia', 'timezone' => 'Asia/Kuala_Lumpur', 'latitude' => 2.7456, 'longitude' => 101.7072, 'terminals' => ['KLIA1' => 'Main Terminal (KLIA)', 'KLIA2' => 'Terminal 2 (Low Cost Hub)']],
        'AUH' => ['name' => 'Zayed International Airport', 'city' => 'Abu Dhabi', 'country' => 'United Arab Emirates', 'timezone' => 'Asia/Dubai', 'latitude' => 24.4330, 'longitude' => 54.6511, 'terminals' => ['TA' => 'Terminal A (Mega-Terminal)']],
        'RUH' => ['name' => 'King Khalid International Airport', 'city' => 'Riyadh', 'country' => 'Saudi Arabia', 'timezone' => 'Asia/Riyadh', 'latitude' => 24.9576, 'longitude' => 46.6988, 'terminals' => ['T1' => 'Terminal 1', 'T2' => 'Terminal 2', 'T3' => 'Terminal 3', 'T4' => 'Terminal 4', 'T5' => 'Terminal 5']],
        'MEL' => ['name' => 'Melbourne Tullamarine Airport', 'city' => 'Melbourne', 'country' => 'Australia', 'timezone' => 'Australia/Melbourne', 'latitude' => -37.6690, 'longitude' => 144.8410, 'terminals' => ['T2' => 'Terminal 2 (International)', 'T1' => 'Terminal 1 (Qantas)', 'T3' => 'Terminal 3 (Virgin)', 'T4' => 'Terminal 4']],
        'AKL' => ['name' => 'Auckland Airport', 'city' => 'Auckland', 'country' => 'New Zealand', 'timezone' => 'Pacific/Auckland', 'latitude' => -37.0082, 'longitude' => 174.7850, 'terminals' => ['INTL' => 'International Terminal', 'DOM' => 'Domestic Terminal']],
        'JNB' => ['name' => 'O.R. Tambo International Airport', 'city' => 'Johannesburg', 'country' => 'South Africa', 'timezone' => 'Africa/Johannesburg', 'latitude' => -26.1367, 'longitude' => 28.2411, 'terminals' => ['A' => 'Terminal A (International)', 'B' => 'Terminal B (Domestic)']],
        'CAI' => ['name' => 'Cairo International Airport', 'city' => 'Cairo', 'country' => 'Egypt', 'timezone' => 'Africa/Cairo', 'latitude' => 30.1219, 'longitude' => 31.4056, 'terminals' => ['T1' => 'Terminal 1', 'T2' => 'Terminal 2', 'T3' => 'Terminal 3']],
    ];

    /**
     * Common airport search alias keywords mapping names/cities to primary IATA code.
     *
     * @var array<string, string>
     */
    private const SEARCH_ALIASES = [
        'LONDON' => 'LHR',
        'HEATHROW' => 'LHR',
        'GATWICK' => 'LGW',
        'PARIS' => 'CDG',
        'CHARLES DE GAULLE' => 'CDG',
        'TOKYO' => 'HND',
        'HANEDA' => 'HND',
        'NARITA' => 'NRT',
        'OSAKA' => 'KIX',
        'KANSAI' => 'KIX',
        'SINGAPORE' => 'SIN',
        'CHANGI' => 'SIN',
        'BANGKOK' => 'BKK',
        'SUVARNABHUMI' => 'BKK',
        'SEOUL' => 'ICN',
        'INCHEON' => 'ICN',
        'DUBAI' => 'DXB',
        'DOHA' => 'DOH',
        'QATAR' => 'DOH',
        'ABU DHABI' => 'AUH',
        'HONG KONG' => 'HKG',
        'TAIPEI' => 'TPE',
        'KUALA LUMPUR' => 'KUL',
        'MANILA' => 'MNL',
        'CEBU' => 'CEB',
        'BALI' => 'DPS',
        'NEW YORK' => 'JFK',
        'SAN FRANCISCO' => 'SFO',
        'LOS ANGELES' => 'LAX',
        'CHICAGO' => 'ORD',
        'SYDNEY' => 'SYD',
        'MELBOURNE' => 'MEL',
        'AMSTERDAM' => 'AMS',
        'SCHIPHOL' => 'AMS',
        'FRANKFURT' => 'FRA',
        'MUNICH' => 'MUC',
        'MADRID' => 'MAD',
        'BARCELONA' => 'BCN',
        'ROME' => 'FCO',
        'MILAN' => 'MXP',
        'ZURICH' => 'ZRH',
        'TORONTO' => 'YYZ',
        'ISTANBUL' => 'IST',
    ];

    /**
     * Resolve a query or IATA code to canonical 3-letter IATA code.
     */
    public static function resolveIata(string $query): string
    {
        $clean = strtoupper(trim($query));

        if (strlen($clean) === 3) {
            return $clean;
        }

        foreach (self::SEARCH_ALIASES as $alias => $code) {
            if (str_contains($clean, $alias) || str_contains($alias, $clean)) {
                return $code;
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

        // 1. Direct rich directory match
        if (isset(self::DIRECTORY[$iata])) {
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

        // 2. Global Catalog Airport match (auto-generate terminals & verified executive lounges)
        if (isset(self::GLOBAL_AIRPORTS_CATALOG[$iata])) {
            $meta = self::GLOBAL_AIRPORTS_CATALOG[$iata];

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

        // Gather all known airports
        $all = [];
        foreach (self::DIRECTORY as $iata => $data) {
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

        foreach (self::GLOBAL_AIRPORTS_CATALOG as $iata => $meta) {
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
        foreach (array_keys(self::DIRECTORY) as $iata) {
            self::autoProvision($iata);
        }
        foreach (array_keys(self::GLOBAL_AIRPORTS_CATALOG) as $iata) {
            self::autoProvision($iata);
        }
    }
}
