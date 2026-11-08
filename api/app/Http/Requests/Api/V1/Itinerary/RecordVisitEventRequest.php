<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Itinerary;

use Illuminate\Foundation\Http\FormRequest;

final class RecordVisitEventRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'event_type' => ['required', 'string', 'in:suggested,confirmed,revoked'],
            'method' => ['sometimes', 'string', 'in:manual,geofence'],
            'accuracy_m' => ['sometimes', 'nullable', 'numeric', 'min:0'],
            'detected_at' => ['sometimes', 'nullable', 'date'],
        ];
    }
}

