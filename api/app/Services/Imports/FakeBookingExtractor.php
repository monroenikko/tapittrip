<?php

declare(strict_types=1);

namespace App\Services\Imports;

use App\Contracts\BookingExtractorInterface;
use App\DTOs\Imports\ExtractedBookingData;

final class FakeBookingExtractor implements BookingExtractorInterface
{
    public function extract(string $text, ?string $hintType = null): ?ExtractedBookingData
    {
        $trimmed = trim($text);
        if ($trimmed === '' || strtolower($trimmed) === '[unparseable]') {
            return null;
        }

        $lower = strtolower($trimmed);

        // Determine booking type
        $type = $hintType;
        if ($type === null || $type === '' || $type === 'auto') {
            if (str_contains($lower, 'flight') || str_contains($lower, 'airline') || preg_match('/\b[A-Z]{3}\s*(?:→|->|–|-)\s*[A-Z]{3}\b/i', $trimmed)) {
                $type = 'flight';
            } elseif (str_contains($lower, 'hotel') || str_contains($lower, 'stay') || str_contains($lower, 'check-in') || str_contains($lower, 'resort')) {
                $type = 'stay';
            } elseif (str_contains($lower, 'tour') || str_contains($lower, 'ticket') || str_contains($lower, 'museum') || str_contains($lower, 'activity')) {
                $type = 'activity';
            } else {
                $type = 'flight'; // default candidate
            }
        }

        if ($type === 'stay') {
            return $this->extractStay($trimmed);
        }

        if ($type === 'activity') {
            return $this->extractActivity($trimmed);
        }

        return $this->extractFlight($trimmed);
    }

    private function extractFlight(string $text): ExtractedBookingData
    {
        // Extract PNR / reference
        $bookingRef = null;
        if (preg_match('/(?:pnr|booking|reservation|confirmation)(?:[ \t]+(?:reference|code|number|id))?[ \t]*[:#][ \t]*([A-Z0-9-]{4,24})/i', $text, $matches)) {
            $bookingRef = strtoupper(trim($matches[1]));
        }

        // Extract Airline
        $airline = 'Philippine Airlines';
        if (preg_match('/\b(Philippine Airlines|All Nippon Airways|Japan Airlines|Cebu Pacific|Singapore Airlines|Delta Air Lines|United Airlines)\b/i', $text, $matches)) {
            $airline = trim($matches[1]);
        } elseif (preg_match('/^(?:airline|carrier)\s*[:#]?\s*([^\n\r]{2,80})/im', $text, $matches)) {
            $airline = trim($matches[1]);
        }

        // Extract Flight Number
        $flightNumber = 'PR 101';
        if (preg_match('/\b([A-Z0-9]{2}\s?\d{1,4}[A-Z]?)\b/i', $text, $matches)) {
            $flightNumber = strtoupper(trim($matches[1]));
        }

        // Extract Route (e.g. MNL -> NRT or MNL-NRT)
        $originAirport = 'MNL';
        $destinationAirport = 'NRT';
        if (preg_match('/\b([A-Z]{3})\s*(?:→|->|–|-)\s*([A-Z]{3})\b/i', $text, $matches)) {
            $originAirport = strtoupper(trim($matches[1]));
            $destinationAirport = strtoupper(trim($matches[2]));
        }

        // Dates / Departure times
        $departureUtc = '2027-04-10T08:00:00Z';
        $arrivalUtc = '2027-04-10T13:30:00Z';
        if (preg_match('/(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)/i', $text, $matches)) {
            $departureUtc = $matches[1];
        }

        $segment = [
            'flight_number' => $flightNumber,
            'origin_airport' => $originAirport,
            'destination_airport' => $destinationAirport,
            'scheduled_departure_utc' => $departureUtc,
            'scheduled_arrival_utc' => $arrivalUtc,
            'origin_timezone' => 'Asia/Manila',
            'destination_timezone' => 'Asia/Tokyo',
            'terminal' => 'Terminal 2',
            'gate' => null,
        ];

        return new ExtractedBookingData(
            bookingType: 'flight',
            confidence: 0.95,
            summary: "{$airline} {$flightNumber} ({$originAirport} → {$destinationAirport})",
            flight: [
                'airline' => $airline,
                'booking_reference' => $bookingRef ?? 'PR-CONF-8899',
                'segments' => [$segment],
            ],
            rawExtracted: [
                'raw_text_length' => strlen($text),
                'parser' => 'fake_booking_extractor',
            ],
        );
    }

    private function extractStay(string $text): ExtractedBookingData
    {
        $hotelName = 'Shinjuku Granbell Hotel';
        if (preg_match('/(?:hotel(?:\s+name)?|property|stay|resort)(?:\s+(?:reservation|booking))?\s*[:#]\s*([^\n\r]{3,80})/i', $text, $matches)) {
            $hotelName = trim($matches[1]);
        } elseif (preg_match('/(?:hotel|property|stay|resort)\s*[:#]?\s*([^\n\r]{3,80})/i', $text, $matches)) {
            $val = trim($matches[1]);
            $val = (string) preg_replace('/^(?:reservation|booking|confirmation)\s*[:#]?\s*/i', '', $val);
            if ($val !== '') {
                $hotelName = $val;
            }
        }

        $bookingRef = 'HTL-998811';
        if (preg_match('/(?:pnr|booking|reservation|confirmation)(?:[ \t]+(?:reference|code|number|id))?[ \t]*[:#][ \t]*([A-Z0-9-]{4,24})/i', $text, $matches)) {
            $bookingRef = strtoupper(trim($matches[1]));
        }

        $address = '2-14-5 Kabukicho, Shinjuku, Tokyo 160-0021';
        if (preg_match('/(?:address|location)\s*[:#]?\s*([^\n\r]{5,120})/i', $text, $matches)) {
            $address = trim($matches[1]);
        }

        $checkIn = '2027-04-10T15:00:00Z';
        $checkOut = '2027-04-15T11:00:00Z';

        return new ExtractedBookingData(
            bookingType: 'stay',
            confidence: 0.92,
            summary: "Stay at {$hotelName}",
            stay: [
                'name' => $hotelName,
                'stay_type' => 'hotel',
                'address' => $address,
                'check_in_at' => $checkIn,
                'check_out_at' => $checkOut,
                'timezone' => 'Asia/Tokyo',
                'phone' => '+81 3 5155 2666',
                'booking_reference' => $bookingRef,
                'notes' => 'Non-smoking double room, breakfast included',
            ],
            rawExtracted: [
                'raw_text_length' => strlen($text),
                'parser' => 'fake_booking_extractor',
            ],
        );
    }

    private function extractActivity(string $text): ExtractedBookingData
    {
        $title = 'teamLab Planets Tokyo Admission';
        if (preg_match('/(?:activity|tour|experience|ticket|event)(?:\s+(?:ticket|pass|voucher|booking))?\s*[:#]\s*([^\n\r]{3,80})/i', $text, $matches)) {
            $title = trim($matches[1]);
        } elseif (preg_match('/(?:activity|tour|experience|ticket)\s*[:#]?\s*([^\n\r]{3,80})/i', $text, $matches)) {
            $val = trim($matches[1]);
            $val = (string) preg_replace('/^(?:ticket|pass|voucher|booking|reservation)\s*[:#]?\s*/i', '', $val);
            if ($val !== '') {
                $title = $val;
            }
        }

        return new ExtractedBookingData(
            bookingType: 'activity',
            confidence: 0.90,
            summary: "Activity: {$title}",
            activity: [
                'title' => $title,
                'kind' => 'attraction',
                'place_name' => 'teamLab Planets TOKYO DMM',
                'starts_at_utc' => '2027-04-12T10:00:00Z',
                'ends_at_utc' => '2027-04-12T12:00:00Z',
                'timezone' => 'Asia/Tokyo',
                'notes' => 'Arrive 15 minutes before entry time slot.',
            ],
            rawExtracted: [
                'raw_text_length' => strlen($text),
                'parser' => 'fake_booking_extractor',
            ],
        );
    }
}
