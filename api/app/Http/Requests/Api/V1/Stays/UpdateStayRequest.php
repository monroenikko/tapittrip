<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Stays;

use Illuminate\Foundation\Http\FormRequest;

final class UpdateStayRequest extends FormRequest
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
            'name' => ['nullable', 'string', 'max:255'],
            'stay_type' => ['nullable', 'string', 'in:hotel,hostel,rental,friends_family'],
            'address' => ['nullable', 'string', 'max:1000'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'check_in_at' => ['nullable', 'date'],
            'check_out_at' => ['nullable', 'date'],
            'timezone' => ['nullable', 'string', 'timezone:all'],
            'phone' => ['nullable', 'string', 'max:64'],
            'booking_reference' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:5000'],
            'luggage_profile' => ['nullable', 'array'],
            'luggage_profile.party_size' => ['nullable', 'integer', 'min:1'],
            'luggage_profile.backpacks' => ['nullable', 'integer', 'min:0'],
            'luggage_profile.carry_ons' => ['nullable', 'integer', 'min:0'],
            'luggage_profile.checked_bags' => ['nullable', 'integer', 'min:0'],
            'luggage_profile.oversized' => ['nullable', 'integer', 'min:0'],
            'luggage_profile.stroller' => ['nullable', 'boolean'],
            'place_id' => ['nullable', 'uuid', 'exists:places,id'],
        ];
    }
}
