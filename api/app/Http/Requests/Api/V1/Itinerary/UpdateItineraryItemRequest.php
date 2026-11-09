<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Itinerary;

use Illuminate\Foundation\Http\FormRequest;

final class UpdateItineraryItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        // 1. Sanitize title if present
        if ($this->has('title') && is_string($this->input('title'))) {
            $title = trim((string) $this->input('title'));
            if ($title !== '') {
                $this->merge(['title' => $title]);
            }
        }

        // 2. Normalize kind: map arbitrary AI or natural categories into canonical kinds
        if ($this->has('kind') && is_string($this->input('kind'))) {
            $kind = strtolower(trim((string) $this->input('kind')));
            $normalized = match (true) {
                str_contains($kind, 'food') || str_contains($kind, 'dine') || str_contains($kind, 'dining') ||
                str_contains($kind, 'restaurant') || str_contains($kind, 'cafe') || str_contains($kind, 'bar') ||
                str_contains($kind, 'meal') || str_contains($kind, 'eat') || str_contains($kind, 'lunch') ||
                str_contains($kind, 'dinner') || str_contains($kind, 'breakfast') || str_contains($kind, 'bakery') ||
                str_contains($kind, 'snack') || str_contains($kind, 'coffee') || str_contains($kind, 'drink') => 'meal',

                str_contains($kind, 'flight') || str_contains($kind, 'airline') || str_contains($kind, 'airport') => 'flight',

                str_contains($kind, 'transit') || str_contains($kind, 'train') || str_contains($kind, 'bus') ||
                str_contains($kind, 'taxi') || str_contains($kind, 'rideshare') || str_contains($kind, 'subway') ||
                str_contains($kind, 'transport') || str_contains($kind, 'transfer') || str_contains($kind, 'ferry') => 'transport',

                str_contains($kind, 'stay') || str_contains($kind, 'hotel') || str_contains($kind, 'resort') ||
                str_contains($kind, 'accommodation') || str_contains($kind, 'hostel') || str_contains($kind, 'lodging') => 'hotel',

                $kind === 'custom' => 'custom',

                default => 'attraction',
            };
            $this->merge(['kind' => $normalized]);
        }

        // 3. Normalize place: ignore empty place names, map address to formatted_address, ensure provider
        if ($this->has('place') && is_array($this->input('place'))) {
            $place = $this->input('place');
            $placeName = trim((string) ($place['name'] ?? ''));
            if ($placeName === '') {
                $this->merge(['place' => null]);
            } else {
                $place['name'] = $placeName;
                if ((isset($place['address']) || isset($place['formatted_address'])) && empty($place['formatted_address'])) {
                    $place['formatted_address'] = trim((string) ($place['address'] ?? ''));
                }
                if (empty($place['provider'])) {
                    $place['provider'] = 'manual';
                }
                $this->merge(['place' => $place]);
            }
        }
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'string', 'max:255'],
            'kind' => ['sometimes', 'string', 'in:attraction,meal,transport,flight,hotel,custom'],
            'trip_day_id' => ['nullable', 'uuid', 'exists:trip_days,id'],
            'place_id' => ['nullable', 'uuid', 'exists:places,id'],
            'place' => ['nullable', 'array'],
            'place.name' => ['required_with:place', 'string', 'max:255'],
            'place.provider' => ['nullable', 'string', 'max:32'],
            'place.provider_place_id' => ['nullable', 'string', 'max:255'],
            'place.formatted_address' => ['nullable', 'string', 'max:1000'],
            'place.country_code' => ['nullable', 'string', 'size:2'],
            'place.latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'place.longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'place.photo_reference' => ['nullable', 'string', 'max:500'],
            'place.attribution' => ['nullable', 'string', 'max:1000'],
            'notes' => ['nullable', 'string', 'max:5000'],
            'starts_at_utc' => ['nullable', 'date'],
            'ends_at_utc' => ['nullable', 'date'],
            'timezone' => ['sometimes', 'string', 'timezone:all'],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
            'status' => ['sometimes', 'string', 'in:planned,visited,skipped'],
        ];
    }
}
