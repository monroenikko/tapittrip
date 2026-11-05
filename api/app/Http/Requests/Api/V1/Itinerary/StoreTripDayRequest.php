<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Itinerary;

use Illuminate\Foundation\Http\FormRequest;

final class StoreTripDayRequest extends FormRequest
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
            'local_date' => ['required', 'date_format:Y-m-d'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
