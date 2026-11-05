<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Itinerary;

use Illuminate\Foundation\Http\FormRequest;

final class StorePlaceRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:255'],
            'provider' => ['nullable', 'string', 'max:32'],
            'provider_place_id' => ['nullable', 'string', 'max:255'],
            'formatted_address' => ['nullable', 'string', 'max:1000'],
            'country_code' => ['nullable', 'string', 'size:2'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'photo_reference' => ['nullable', 'string', 'max:500'],
            'attribution' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
