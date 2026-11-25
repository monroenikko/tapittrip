<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Imports;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ConfirmBookingImportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'base_version' => ['required', 'integer'],
            'booking_type' => ['sometimes', 'string', Rule::in(['flight', 'stay', 'activity'])],
            'flight' => ['nullable', 'array'],
            'flight.airline' => ['nullable', 'string', 'max:160'],
            'flight.booking_reference' => ['nullable', 'string', 'max:160'],
            'flight.segments' => ['required_with:flight', 'array', 'min:1', 'max:8'],
            'flight.segments.*.flight_number' => ['required_with:flight.segments', 'string', 'max:32'],
            'flight.segments.*.origin_airport' => ['required_with:flight.segments', 'string', 'size:3'],
            'flight.segments.*.destination_airport' => ['required_with:flight.segments', 'string', 'size:3'],
            'flight.segments.*.scheduled_departure_utc' => ['required_with:flight.segments', 'date'],
            'flight.segments.*.scheduled_arrival_utc' => ['required_with:flight.segments', 'date'],
            'flight.segments.*.origin_timezone' => ['required_with:flight.segments', 'string', 'timezone:all'],
            'flight.segments.*.destination_timezone' => ['required_with:flight.segments', 'string', 'timezone:all'],
            'flight.segments.*.terminal' => ['nullable', 'string', 'max:64'],
            'flight.segments.*.gate' => ['nullable', 'string', 'max:64'],

            'stay' => ['nullable', 'array'],
            'stay.name' => ['required_with:stay', 'string', 'max:160'],
            'stay.stay_type' => ['sometimes', 'string', 'max:32'],
            'stay.address' => ['nullable', 'string', 'max:255'],
            'stay.check_in_at' => ['nullable', 'date'],
            'stay.check_out_at' => ['nullable', 'date'],
            'stay.timezone' => ['sometimes', 'string', 'timezone:all'],
            'stay.phone' => ['nullable', 'string', 'max:64'],
            'stay.booking_reference' => ['nullable', 'string', 'max:160'],
            'stay.notes' => ['nullable', 'string', 'max:2000'],

            'activity' => ['nullable', 'array'],
            'activity.title' => ['required_with:activity', 'string', 'max:160'],
            'activity.kind' => ['sometimes', 'string', 'max:32'],
            'activity.starts_at_utc' => ['nullable', 'date'],
            'activity.ends_at_utc' => ['nullable', 'date'],
            'activity.timezone' => ['sometimes', 'string', 'timezone:all'],
            'activity.notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
