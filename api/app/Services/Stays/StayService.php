<?php

declare(strict_types=1);

namespace App\Services\Stays;

use App\Domain\Stays\StayPrivacy;
use App\DTOs\Stays\CompareStayTransportData;
use App\DTOs\Stays\CreateStayData;
use App\DTOs\Stays\UpdateStayData;
use App\Exceptions\VersionConflictException;
use App\Models\ItineraryItem;
use App\Models\Stay;
use App\Models\Trip;
use App\Models\User;
use App\Services\Itinerary\ItineraryService;
use App\Services\Itinerary\PlaceService;
use App\Services\Notifications\NotificationService;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class StayService
{
    public function __construct(
        private readonly PlaceService $placeService,
        private readonly ItineraryService $itineraryService,
        private readonly CompareStayTransportService $compareStayTransportService,
    ) {}

    /**
     * List all stays for a trip.
     *
     * @return Collection<int, Stay>
     */
    public function getTripStays(Trip $trip): Collection
    {
        return $trip->stays()->with(['trip', 'place', 'itineraryItems'])->get();
    }

    /**
     * Create a new stay / accommodation for a trip.
     */
    public function create(Trip $trip, CreateStayData $data): Stay
    {
        if ($data->checkInAt !== null && $data->checkOutAt !== null && $data->checkInAt >= $data->checkOutAt) {
            throw ValidationException::withMessages([
                'check_out_at' => ['Check-out time must be after check-in time.'],
            ]);
        }

        return DB::transaction(function () use ($trip, $data): Stay {
            $placeId = $data->placeId;

            if ($data->place !== null) {
                $place = $this->placeService->createPlace($data->place);
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
                    $inDay = $this->itineraryService->ensureTripDay($trip, $inLocalDate);

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
                    $outDay = $this->itineraryService->ensureTripDay($trip, $outLocalDate);

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

            $fresh = $stay->load(['place', 'itineraryItems']);
            app(NotificationService::class)->syncRemindersForStay($fresh);

            return $fresh;
        });
    }

    /**
     * Update an existing stay.
     */
    public function update(Stay $stay, UpdateStayData $data, ?User $actor = null): Stay
    {
        return DB::transaction(function () use ($stay, $data, $actor): Stay {
            /** @var Stay $locked */
            $locked = Stay::query()
                ->with(['trip', 'itineraryItems'])
                ->whereKey($stay->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($data->baseVersion !== null && $data->baseVersion !== $locked->version) {
                throw new VersionConflictException(
                    serverVersion: (int) $locked->version,
                    serverPayload: StayPrivacy::redactServerPayload($locked, $actor),
                );
            }

            $newCheckIn = $data->checkInAt ?? $locked->check_in_at;
            $newCheckOut = $data->checkOutAt ?? $locked->check_out_at;

            if ($newCheckIn !== null && $newCheckOut !== null && $newCheckIn >= $newCheckOut) {
                throw ValidationException::withMessages([
                    'check_out_at' => ['Check-out time must be after check-in time.'],
                ]);
            }

            $updates = [
                'version' => $locked->version + 1,
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

            $locked->update($updates);

            // Update linked check-in and check-out itinerary item titles/times/timezones if changed
            if ($data->name !== null || $data->checkInAt !== null || $data->checkOutAt !== null || $data->timezone !== null) {
                foreach ($locked->itineraryItems as $item) {
                    if (str_starts_with($item->title, 'Check-in:')) {
                        $item->update([
                            'title' => 'Check-in: '.$locked->name,
                            'starts_at_utc' => $locked->check_in_at?->copy()->utc() ?? $item->starts_at_utc,
                            'timezone' => $locked->timezone,
                            'version' => $item->version + 1,
                        ]);
                    } elseif (str_starts_with($item->title, 'Check-out:')) {
                        $item->update([
                            'title' => 'Check-out: '.$locked->name,
                            'starts_at_utc' => $locked->check_out_at?->copy()->utc() ?? $item->starts_at_utc,
                            'timezone' => $locked->timezone,
                            'version' => $item->version + 1,
                        ]);
                    }
                }
            }

            $fresh = $locked->fresh(['trip', 'place', 'itineraryItems']);
            if ($fresh !== null) {
                app(NotificationService::class)->syncRemindersForStay($fresh);
            }

            return $fresh ?? $locked;
        });
    }

    /**
     * Delete an existing stay.
     */
    public function delete(Stay $stay): void
    {
        DB::transaction(function () use ($stay): void {
            app(NotificationService::class)->cancelRemindersForStay($stay);

            // Decouple linked itinerary items so they are never orphaned or deleted
            $stay->itineraryItems()->update(['stay_id' => null]);

            $stay->delete();
        });
    }

    /**
     * Compare luggage-aware airport/origin to stay transportation options.
     *
     * @return array<string, mixed>
     */
    public function compareTransport(Stay $stay, CompareStayTransportData $data, ?User $viewer = null): array
    {
        return $this->compareStayTransportService->handle($stay, $data, $viewer);
    }
}
