<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Flights\StoreFlightRequest;
use App\Http\Requests\Api\V1\Flights\UpdateFlightRequest;
use App\Http\Resources\Api\V1\FlightResource;
use App\Models\Flight;
use App\Models\Trip;
use App\Services\Flights\CreateFlightService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Gate;

final class FlightController extends Controller
{
    public function index(Request $request, Trip $trip): AnonymousResourceCollection
    {
        Gate::authorize('view', $trip);

        return FlightResource::collection(
            Flight::query()
                ->where('trip_id', $trip->id)
                ->with(['segments', 'trip'])
                ->latest()
                ->get(),
        );
    }

    public function store(StoreFlightRequest $request, Trip $trip, CreateFlightService $service): JsonResponse
    {
        Gate::authorize('update', $trip);

        $data = $request->validated();
        $existing = isset($data['client_operation_id'])
            ? Flight::query()
                ->where('trip_id', $trip->id)
                ->where('client_operation_id', $data['client_operation_id'])
                ->first()
            : null;

        $flight = $existing ?? $service->handle($trip, $data);

        return (new FlightResource($flight->load(['segments', 'trip'])))
            ->response()
            ->setStatusCode($existing === null ? 201 : 200);
    }

    public function update(UpdateFlightRequest $request, Flight $flight, CreateFlightService $service): JsonResponse
    {
        Gate::authorize('update', $flight->trip);

        return (new FlightResource($service->update($flight, $request->validated())->load(['segments', 'trip'])))
            ->response();
    }

    public function destroy(Flight $flight, CreateFlightService $service): Response
    {
        Gate::authorize('update', $flight->trip);
        $service->delete($flight);

        return response()->noContent();
    }
}
