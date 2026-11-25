<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Flights;

use Illuminate\Foundation\Http\FormRequest;

class StoreFlightRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'airline' => ['nullable', 'string', 'max:120'],
            'booking_reference' => ['nullable', 'string', 'max:255'],
            'client_operation_id' => ['nullable', 'uuid'],
            'segments' => ['required', 'array', 'min:1', 'max:8'],
            'segments.*.flight_number' => ['required', 'string', 'max:16'],
            'segments.*.origin_airport' => ['required', 'string', 'size:3', 'alpha'],
            'segments.*.destination_airport' => ['required', 'string', 'size:3', 'alpha'],
            'segments.*.scheduled_departure_utc' => ['required', 'date'],
            'segments.*.scheduled_arrival_utc' => ['required', 'date', 'after:segments.*.scheduled_departure_utc'],
            'segments.*.origin_timezone' => ['required', 'timezone'],
            'segments.*.destination_timezone' => ['required', 'timezone'],
            'segments.*.terminal' => ['nullable', 'string', 'max:32'],
            'segments.*.gate' => ['nullable', 'string', 'max:32'],
        ];
    }

    public function after(): array
    {
        return [function ($validator): void {
            foreach ($this->input('segments', []) as $index => $segment) {
                if (($segment['origin_airport'] ?? null) === ($segment['destination_airport'] ?? null)) {
                    $validator->errors()->add("segments.$index.destination_airport", 'The destination airport must differ from the origin airport.');
                }
            }
        }];
    }
}
