<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Circles;

use App\Models\Trip;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

final class UpdateTripLocationShareRequest extends FormRequest
{
    public function authorize(): bool
    {
        $trip = $this->route('trip');

        return $this->user() !== null
            && $trip instanceof Trip
            && ($trip->owner_id === $this->user()->id || $trip->hasMember($this->user()));
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'enabled' => ['sometimes', 'boolean'],
            'duration_minutes' => ['sometimes', 'integer', 'in:60,240,480,1440'],
            'audience' => ['sometimes', 'string', 'in:circle,organizer_only'],
            'latitude' => ['sometimes', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'numeric', 'between:-180,180'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $hasLatitude = $this->has('latitude');
            $hasLongitude = $this->has('longitude');

            if ($hasLatitude !== $hasLongitude) {
                $validator->errors()->add(
                    $hasLatitude ? 'longitude' : 'latitude',
                    'Latitude and longitude must be provided together.',
                );
            }

            if ($this->has('enabled') && $this->boolean('enabled') && ! ($hasLatitude && $hasLongitude)) {
                $validator->errors()->add(
                    'latitude',
                    'Coordinates are required when starting location sharing.',
                );
            }

            if (! $this->hasAny(['enabled', 'duration_minutes', 'audience', 'latitude', 'longitude'])) {
                $validator->errors()->add('request', 'Provide a location-sharing change.');
            }
        });
    }
}
