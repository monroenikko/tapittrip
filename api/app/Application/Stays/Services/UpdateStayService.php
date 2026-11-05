<?php

declare(strict_types=1);

namespace App\Application\Stays\Services;

use App\Application\Stays\Data\UpdateStayData;
use App\Domain\Stays\Models\Stay;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class UpdateStayService
{
    public function handle(Stay $stay, UpdateStayData $data): Stay
    {
        $newCheckIn = $data->checkInAt ?? $stay->check_in_at;
        $newCheckOut = $data->checkOutAt ?? $stay->check_out_at;

        if ($newCheckIn !== null && $newCheckOut !== null && $newCheckIn >= $newCheckOut) {
            throw ValidationException::withMessages([
                'check_out_at' => ['Check-out time must be after check-in time.'],
            ]);
        }

        return DB::transaction(function () use ($stay, $data): Stay {
            $updates = [
                'version' => $stay->version + 1,
            ];

            if ($data->name !== null) {
                $updates['name'] = $data->name;
            }
            if ($data->stayType !== null) {
                $updates['stay_type'] = $data->stayType;
            }
            if ($data->address !== null) {
                $updates['address'] = $data->address;
            }
            if ($data->latitude !== null) {
                $updates['latitude'] = $data->latitude;
            }
            if ($data->longitude !== null) {
                $updates['longitude'] = $data->longitude;
            }
            if ($data->checkInAt !== null) {
                $updates['check_in_at'] = $data->checkInAt;
            }
            if ($data->checkOutAt !== null) {
                $updates['check_out_at'] = $data->checkOutAt;
            }
            if ($data->timezone !== null) {
                $updates['timezone'] = $data->timezone;
            }
            if ($data->phone !== null) {
                $updates['phone'] = $data->phone;
            }
            if ($data->bookingReference !== null) {
                $updates['booking_reference'] = $data->bookingReference;
            }
            if ($data->notes !== null) {
                $updates['notes'] = $data->notes;
            }
            if ($data->luggageProfile !== null) {
                $updates['luggage_profile'] = $data->luggageProfile;
            }
            if ($data->placeId !== null) {
                $updates['place_id'] = $data->placeId;
            }

            $stay->update($updates);

            // Update linked check-in and check-out itinerary item titles/times if name or dates changed
            if ($data->name !== null || $data->checkInAt !== null || $data->checkOutAt !== null) {
                foreach ($stay->itineraryItems as $item) {
                    if (str_starts_with($item->title, 'Check-in:')) {
                        $item->update([
                            'title' => 'Check-in: '.$stay->name,
                            'starts_at_utc' => $stay->check_in_at?->copy()->utc() ?? $item->starts_at_utc,
                        ]);
                    } elseif (str_starts_with($item->title, 'Check-out:')) {
                        $item->update([
                            'title' => 'Check-out: '.$stay->name,
                            'starts_at_utc' => $stay->check_out_at?->copy()->utc() ?? $item->starts_at_utc,
                        ]);
                    }
                }
            }

            return $stay->fresh(['place', 'itineraryItems']);
        });
    }
}
