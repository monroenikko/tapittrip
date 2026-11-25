<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Itinerary;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ListFoodSuggestionsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'meal_type' => ['nullable', 'string', Rule::in(['all', 'breakfast', 'lunch', 'dinner', 'cafe'])],
            'dietary' => ['nullable', 'string', Rule::in(['vegetarian', 'halal', 'kid_friendly', 'local_specialty'])],
            'near' => ['nullable', 'string', Rule::in(['stay', 'itinerary'])],
        ];
    }
}
