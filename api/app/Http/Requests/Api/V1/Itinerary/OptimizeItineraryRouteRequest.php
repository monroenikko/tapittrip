<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Itinerary;

use Illuminate\Foundation\Http\FormRequest;

final class OptimizeItineraryRouteRequest extends FormRequest
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
            'trip_day_id' => ['nullable', 'uuid'],
            'apply' => ['sometimes', 'boolean'],
            'preserve_fixed_times' => ['sometimes', 'boolean'],
            'max_walking_meters_per_leg' => ['sometimes', 'integer', 'min:200', 'max:10000'],
            'expected_versions' => ['sometimes', 'array'],
            'expected_versions.*' => ['integer', 'min:1'],
        ];
    }
}
