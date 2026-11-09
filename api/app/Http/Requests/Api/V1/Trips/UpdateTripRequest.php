<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Trips;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

final class UpdateTripRequest extends FormRequest
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
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'start_date' => ['nullable', 'date_format:Y-m-d'],
            'end_date' => ['nullable', 'date_format:Y-m-d'],
            'primary_timezone' => ['nullable', 'string', 'timezone:all'],
            'origin_country' => ['nullable', 'string', 'max:100'],
            'destination_country' => ['nullable', 'string', 'max:100'],
            'trip_type' => ['nullable', 'string', 'in:leisure,business,family,solo,group'],
            'planning_mode' => ['nullable', 'string', 'in:diy,existing,guided,simple'],
            'status' => ['nullable', 'string', 'in:planned,active,completed,archived'],
        ];
    }

    /**
     * Configure the validator instance.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $startDate = $this->input('start_date', $this->route('trip')?->start_date?->format('Y-m-d'));
            $endDate = $this->input('end_date', $this->route('trip')?->end_date?->format('Y-m-d'));

            if ($startDate && $endDate && $endDate < $startDate) {
                $validator->errors()->add('end_date', trans('validation.after_or_equal', [
                    'attribute' => 'end date',
                    'date' => 'start date',
                ]));
            }
        });
    }
}
