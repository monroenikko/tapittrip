<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Circles;

use App\Models\Trip;
use Illuminate\Foundation\Http\FormRequest;

final class StoreTripLocationShareRequest extends FormRequest
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
            'enabled' => ['required', 'accepted'],
            'duration_minutes' => ['required', 'integer', 'in:60,240,480,1440'],
            'audience' => ['required', 'string', 'in:circle,organizer_only'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ];
    }
}
