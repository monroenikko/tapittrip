<?php

declare(strict_types=1);

namespace App\Application\Stays\Services;

use App\Application\Itinerary\Services\CreatePlaceService;
use App\Application\Itinerary\Services\EnsureTripDayService;
use App\Application\Stays\Data\CreateStayData;
use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Stays\Models\Stay;
use App\Domain\Trips\Models\Trip;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class CreateStayService
{
    public function __construct(
        private CreatePlaceService $createPlaceService,
        private EnsureTripDayService $ensureTripDayService,
    ) {}

    public function handle(Trip $trip, CreateStayData $data): Stay
    {
        if ($data->checkInAt !== null && $data->checkOutAt !== null && $data->checkInAt >= $data->checkOutAt) {
            throw ValidationException::withMessages([
                'check_out_at' => ['Check-out time must be after check-in time.'],
            ]);
        }

        return DB::transaction(function () use ($trip, $data): Stay {
            $placeId = $data->placeId;

            if ($data->place !== null) {
                $place = $this->createPlaceService->handle($data->place);
                $placeId = $place->id;
            }

            /** @var Stay $stay */
            $stay = Stay::query()->create([
                'trip_id' => $trip->id,
                'place_id' => $placeId,
                'name' => $data->name,
                'stay_type' => $data->stayType,
                'address' => $data->address,
                'latitude' => $data->latitude,
                'longitude' => $data->longitude,
                'check_in_at' => $data->checkInAt,
                'check_out_at' => $data->checkOutAt,
                'timezone' => $data->timezone,
                'phone' => $data->phone,
                'booking_reference' => $data->bookingReference,
                'notes' => $data->notes,
                'luggage_profile' => $data->luggageProfile,
                'version' => 1,
            ]);

            if ($data->createItineraryEvents) {
                if ($data->checkInAt !== null) {
                    $inLocalDate = $data->checkInAt->copy()->setTimezone($data->timezone)->format('Y-m-d');
                    $inDay = $this->ensureTripDayService->handle($trip, $inLocalDate);

                    ItineraryItem::query()->create([
                        'trip_id' => $trip->id,
                        'trip_day_id' => $inDay->id,
                        'place_id' => $placeId,
                        'stay_id' => $stay->id,
                        'kind' => 'hotel',
                        'title' => 'Check-in: '.$stay->name,
                        'starts_at_utc' => $data->checkInAt->copy()->utc(),
                        'timezone' => $data->timezone,
                        'status' => 'planned',
                        'sort_order' => 0,
                    ]);
                }

                if ($data->checkOutAt !== null) {
                    $outLocalDate = $data->checkOutAt->copy()->setTimezone($data->timezone)->format('Y-m-d');
                    $outDay = $this->ensureTripDayService->handle($trip, $outLocalDate);

                    ItineraryItem::query()->create([
                        'trip_id' => $trip->id,
                        'trip_day_id' => $outDay->id,
                        'place_id' => $placeId,
                        'stay_id' => $stay->id,
                        'kind' => 'hotel',
                        'title' => 'Check-out: '.$stay->name,
                        'starts_at_utc' => $data->checkOutAt->copy()->utc(),
                        'timezone' => $data->timezone,
                        'status' => 'planned',
                        'sort_order' => 999,
                    ]);
                }
            }

            return $stay->load(['place', 'itineraryItems']);
        });
    }
}
