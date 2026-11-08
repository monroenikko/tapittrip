<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Lounges;

use Illuminate\Foundation\Http\FormRequest;

final class SearchAirportLoungesRequest extends FormRequest
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
            'terminal' => ['nullable', 'string', 'max:20'],
            'is_airside' => ['nullable', 'boolean'],
            'access_methods' => ['nullable', 'array'],
            'access_methods.*' => ['string'],
        ];
    }
}
