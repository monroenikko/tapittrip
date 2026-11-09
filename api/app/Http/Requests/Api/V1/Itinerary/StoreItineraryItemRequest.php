<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Itinerary;

use Illuminate\Foundation\Http\FormRequest;

final class StoreItineraryItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('kind') && is_string($this->input('kind'))) {
            $kind = strtolower(trim((string) $this->input('kind')));
            $normalized = match ($kind) {
                'sightseeing', 'activity', 'nature', 'culture', 'shopping' => 'attraction',
                'dining', 'food', 'restaurant', 'cafe', 'bar' => 'meal',
                'transit', 'train', 'bus', 'taxi', 'rideshare' => 'transport',
                'stay', 'accommodation', 'resort' => 'hotel',
                default => $kind,
            };
            $this->merge(['kind' => $normalized]);
        }
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'kind' => ['nullable', 'string', 'in:attraction,meal,transport,flight,hotel,custom,sightseeing,activity,nature,culture,shopping,dining,food,restaurant,cafe,bar,transit,train,bus,taxi,rideshare,stay,accommodation,resort'],
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
            'ends_at_utc' => ['nullable', 'date', 'after_or_equal:starts_at_utc'],
            'timezone' => ['nullable', 'string', 'timezone:all'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'status' => ['nullable', 'string', 'in:planned,visited,skipped'],
        ];
    }
}
