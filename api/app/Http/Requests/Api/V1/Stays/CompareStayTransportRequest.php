<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Stays;

use Illuminate\Foundation\Http\FormRequest;

final class CompareStayTransportRequest extends FormRequest
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
            'origin' => ['nullable', 'string', 'max:255'],
            'origin_name' => ['nullable', 'string', 'max:255'],
            'origin_latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'origin_longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'party_size' => ['nullable', 'integer', 'min:1', 'max:50'],
            'luggage_preset' => ['nullable', 'string', 'in:light,standard,heavy,custom'],
            'backpacks' => ['nullable', 'integer', 'min:0', 'max:20'],
            'carry_ons' => ['nullable', 'integer', 'min:0', 'max:20'],
            'checked_bags' => ['nullable', 'integer', 'min:0', 'max:20'],
            'oversized' => ['nullable', 'integer', 'min:0', 'max:10'],
            'stroller' => ['nullable', 'boolean'],
        ];
    }
}
