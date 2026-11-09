<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Itinerary;

use Illuminate\Foundation\Http\FormRequest;

final class ApplyAiItineraryRequest extends FormRequest
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
            'days' => ['required', 'array', 'min:1'],
            'days.*.day_number' => ['required', 'integer', 'min:1'],
            'days.*.title' => ['nullable', 'string', 'max:255'],
            'days.*.theme' => ['nullable', 'string', 'max:255'],
            'days.*.primary_neighborhood' => ['nullable', 'string', 'max:255'],
            'days.*.activities' => ['required', 'array', 'min:1'],
            'days.*.activities.*.title' => ['required', 'string', 'max:255'],
            'days.*.activities.*.kind' => ['nullable', 'string', 'max:50'],
            'days.*.activities.*.description' => ['nullable', 'string'],
            'days.*.activities.*.place_name' => ['nullable', 'string', 'max:255'],
            'days.*.activities.*.place_address' => ['nullable', 'string', 'max:500'],
            'days.*.activities.*.planned_start_time' => ['nullable', 'string'],
            'days.*.activities.*.planned_end_time' => ['nullable', 'string'],
            'days.*.activities.*.latitude' => ['nullable', 'numeric'],
            'days.*.activities.*.longitude' => ['nullable', 'numeric'],
            'days.*.activities.*.cost_estimate' => ['nullable', 'array'],
            'days.*.activities.*.accessibility_note' => ['nullable', 'string'],
        ];
    }
}
