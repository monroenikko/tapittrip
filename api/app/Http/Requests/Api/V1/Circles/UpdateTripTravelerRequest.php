<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Circles;

use Illuminate\Foundation\Http\FormRequest;

final class UpdateTripTravelerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'display_name' => ['sometimes', 'string', 'min:1', 'max:120'],
            'traveler_category' => ['sometimes', 'string', 'in:adult,child,infant,companion'],
            'restricted_notes' => ['nullable', 'string', 'max:2000'],
            'base_version' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
