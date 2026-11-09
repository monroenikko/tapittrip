<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Trips;

use Illuminate\Foundation\Http\FormRequest;

final class StoreTripRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'start_date' => ['nullable', 'date_format:Y-m-d'],
            'end_date' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:start_date'],
            'primary_timezone' => ['nullable', 'string', 'timezone:all'],
            'origin_country' => ['nullable', 'string', 'max:100'],
            'destination_country' => ['nullable', 'string', 'max:100'],
            'trip_type' => ['nullable', 'string', 'in:leisure,business,family,solo,group'],
            'planning_mode' => ['nullable', 'string', 'in:diy,existing,guided,simple'],
        ];
    }
}
