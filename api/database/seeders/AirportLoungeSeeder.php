<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Application\Lounges\Services\AirportLoungeDirectoryService;
use App\Domain\Lounges\Models\Airport;
use App\Domain\Lounges\Models\AirportLounge;
use App\Domain\Lounges\Models\AirportTerminal;
use Illuminate\Database\Seeder;

final class AirportLoungeSeeder extends Seeder
{
    public function run(): void
    {
        // 1. MNL - Manila Ninoy Aquino International Airport
        $mnl = Airport::updateOrCreate(
            ['iata_code' => 'MNL'],
            [
                'name' => 'Ninoy Aquino International Airport',
                'city' => 'Manila',
                'country' => 'Philippines',
                'latitude' => 14.5086,
                'longitude' => 121.0194,
                'timezone' => 'Asia/Manila',
            ]
        );

        $mnlT3 = AirportTerminal::updateOrCreate(
            ['airport_id' => $mnl->id, 'code' => 'T3'],
            ['name' => 'Terminal 3']
        );

        $mnlT1 = AirportTerminal::updateOrCreate(
            ['airport_id' => $mnl->id, 'code' => 'T1'],
            ['name' => 'Terminal 1']
        );

        AirportLounge::updateOrCreate(
            ['airport_id' => $mnl->id, 'terminal_id' => $mnlT3->id, 'name' => 'PAGSS Premium Lounge (T3)'],
            [
                'operator' => 'Philippine Airport Ground Support Solutions',
                'location_description' => 'Level 4, International Departures, near Gate 115',
                'is_airside' => true,
                'opening_hours' => ['open' => '05:00', 'close' => '00:00', 'is_24h' => false],
                'amenities' => ['buffet', 'bar', 'showers', 'wifi', 'power_outlets', 'quiet_area'],
                'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'business_class', 'paid_walkin'],
                'estimated_price' => ['amount_cents' => 2800, 'currency' => 'PHP'],
                'booking_url' => 'https://www.pagss.com',
                'transit_warning' => null,
                'disclaimer' => 'Accessible only to passengers departing on international flights from Terminal 3.',
            ]
        );

        AirportLounge::updateOrCreate(
            ['airport_id' => $mnl->id, 'terminal_id' => $mnlT3->id, 'name' => 'Marhaba Lounge (T3)'],
            [
                'operator' => 'dnata / Marhaba',
                'location_description' => 'Level 4, International Departures, near Gate 116',
                'is_airside' => true,
                'opening_hours' => ['open' => '06:00', 'close' => '23:30', 'is_24h' => false],
                'amenities' => ['buffet', 'bar', 'showers', 'wifi', 'power_outlets', 'family_room'],
                'access_methods' => ['priority_pass', 'dragon_pass', 'lounge_key', 'paid_walkin'],
                'estimated_price' => ['amount_cents' => 3100, 'currency' => 'PHP'],
                'booking_url' => 'https://www.marhabaservices.com',
                'transit_warning' => null,
                'disclaimer' => 'Showers subject to availability upon arrival.',
            ]
        );

        AirportLounge::updateOrCreate(
            ['airport_id' => $mnl->id, 'terminal_id' => $mnlT1->id, 'name' => 'PAGSS Lounge (T1)'],
            [
                'operator' => 'PAGSS',
                'location_description' => 'East Concourse, beside Gate 7',
                'is_airside' => true,
                'opening_hours' => ['open' => '06:00', 'close' => '23:00', 'is_24h' => false],
                'amenities' => ['buffet', 'bar', 'wifi', 'power_outlets'],
                'access_methods' => ['priority_pass', 'lounge_key', 'business_class'],
                'estimated_price' => null,
                'booking_url' => null,
                'transit_warning' => 'Passengers in Terminal 3 cannot access Terminal 1 without exiting immigration and catching inter-terminal transfer.',
                'disclaimer' => 'Terminal 1 departures only.',
            ]
        );

        // 2. NRT - Tokyo Narita International Airport
        $nrt = Airport::updateOrCreate(
            ['iata_code' => 'NRT'],
            [
                'name' => 'Narita International Airport',
                'city' => 'Tokyo',
                'country' => 'Japan',
                'latitude' => 35.7720,
                'longitude' => 140.3929,
                'timezone' => 'Asia/Tokyo',
            ]
        );

        $nrtT1 = AirportTerminal::updateOrCreate(
            ['airport_id' => $nrt->id, 'code' => 'T1'],
            ['name' => 'Terminal 1']
        );

        AirportLounge::updateOrCreate(
            ['airport_id' => $nrt->id, 'terminal_id' => $nrtT1->id, 'name' => 'Narita TraveLounge (T1)'],
            [
                'operator' => 'Narita International Airport Corporation',
                'location_description' => 'Terminal 1, Central Building 3F, past passport control, near Gate 26',
                'is_airside' => true,
                'opening_hours' => ['open' => '07:00', 'close' => '21:00', 'is_24h' => false],
                'amenities' => ['buffet', 'drinks', 'wifi', 'power_outlets'],
                'access_methods' => ['paid_walkin', 'priority_pass'],
                'estimated_price' => ['amount_cents' => 1540, 'currency' => 'JPY'],
                'booking_url' => 'https://www.narita-airport.jp',
                'transit_warning' => null,
                'disclaimer' => 'Walk-in rate approx ¥1,540 per adult.',
            ]
        );

        // Provision major international hub airports (HND, SIN, BKK, ICN, KIX, DPS, SFO, LAX)
        AirportLoungeDirectoryService::provisionAll();
    }
}
