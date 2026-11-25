<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Flights;

final class UpdateFlightRequest extends StoreFlightRequest
{
    public function rules(): array
    {
        return [
            'airline' => ['sometimes', 'nullable', 'string', 'max:120'],
            'booking_reference' => ['sometimes', 'nullable', 'string', 'max:255'],
            'base_version' => ['required', 'integer', 'min:1'],
            'segments' => ['sometimes', 'array', 'min:1', 'max:8'],
            'segments.*.flight_number' => ['required_with:segments', 'string', 'max:16'],
            'segments.*.origin_airport' => ['required_with:segments', 'string', 'size:3', 'alpha'],
            'segments.*.destination_airport' => ['required_with:segments', 'string', 'size:3', 'alpha'],
            'segments.*.scheduled_departure_utc' => ['required_with:segments', 'date'],
            'segments.*.scheduled_arrival_utc' => ['required_with:segments', 'date', 'after:segments.*.scheduled_departure_utc'],
            'segments.*.origin_timezone' => ['required_with:segments', 'timezone'],
            'segments.*.destination_timezone' => ['required_with:segments', 'timezone'],
            'segments.*.terminal' => ['nullable', 'string', 'max:32'],
            'segments.*.gate' => ['nullable', 'string', 'max:32'],
        ];
    }
}
