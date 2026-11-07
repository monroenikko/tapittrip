<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Checklists;

use Illuminate\Foundation\Http\FormRequest;

final class ApplyChecklistTemplateRequest extends FormRequest
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
            'template' => [
                'required',
                'string',
                'in:international_essentials,electronics_gear,clothing_apparel,toiletries_health,all_essentials,departure_day,return_trip',
            ],
        ];
    }
}
