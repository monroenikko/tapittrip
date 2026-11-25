<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Itinerary;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class SmartReplanItineraryRequest extends FormRequest
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
            'trigger_reason' => ['required', 'string', Rule::in(['rain_weather', 'flight_delay', 'skipped_stop', 'tired_family_pacing'])],
            'trip_day_id' => ['nullable', 'uuid'],
            'apply' => ['sometimes', 'boolean'],
            'delay_minutes' => ['nullable', 'integer', 'min:15', 'max:720'],
        ];
    }
}
