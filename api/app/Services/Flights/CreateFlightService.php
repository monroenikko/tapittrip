<?php

declare(strict_types=1);

namespace App\Services\Flights;

use App\Exceptions\VersionConflictException;
use App\Models\Flight;
use App\Models\Trip;
use App\Services\Notifications\NotificationService;
use Illuminate\Support\Facades\DB;

final class CreateFlightService
{
    public function __construct(
        private readonly NotificationService $notificationService,
    ) {}

    /** @param array<string, mixed> $data */
    public function handle(Trip $trip, array $data): Flight
    {
        return DB::transaction(function () use ($trip, $data): Flight {
            $flight = Flight::query()->create([
                'trip_id' => $trip->id,
                'airline' => $data['airline'] ?? null,
                'booking_reference' => $data['booking_reference'] ?? null,
                'client_operation_id' => $data['client_operation_id'] ?? null,
            ]);
            foreach ($data['segments'] as $segment) {
                $flight->segments()->create([
                    ...$segment,
                    'origin_airport' => strtoupper($segment['origin_airport']),
                    'destination_airport' => strtoupper($segment['destination_airport']),
                ]);
            }

            $fresh = $flight->fresh('segments');
            $this->notificationService->syncRemindersForFlight($fresh);

            return $fresh;
        });
    }

    /** @param array<string, mixed> $data */
    public function update(Flight $flight, array $data): Flight
    {
        return DB::transaction(function () use ($flight, $data): Flight {
            $flight->refresh();

            if ($flight->version !== $data['base_version']) {
                throw new VersionConflictException(
                    $flight->version,
                    ['id' => $flight->id, 'version' => $flight->version],
                );
            }

            $flight->fill(array_intersect_key($data, array_flip(['airline', 'booking_reference'])));
            $flight->version++;
            $flight->save();
            if (array_key_exists('segments', $data)) {
                $flight->segments()->delete();
                foreach ($data['segments'] as $segment) {
                    $flight->segments()->create([...$segment, 'origin_airport' => strtoupper($segment['origin_airport']), 'destination_airport' => strtoupper($segment['destination_airport'])]);
                }
            }

            $fresh = $flight->fresh('segments');
            $this->notificationService->syncRemindersForFlight($fresh);

            return $fresh;
        });
    }

    public function delete(Flight $flight): void
    {
        DB::transaction(function () use ($flight): void {
            $this->notificationService->cancelRemindersForFlight($flight);
            $flight->delete();
        });
    }
}
