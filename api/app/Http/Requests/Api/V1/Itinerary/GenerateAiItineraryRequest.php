<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Itinerary;

use Illuminate\Foundation\Http\FormRequest;

final class GenerateAiItineraryRequest extends FormRequest
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
            'destination' => ['nullable', 'string', 'max:255'],
            'duration_days' => ['nullable', 'integer', 'min:1', 'max:14'],
            'budget_tier' => ['nullable', 'string', 'in:low,moderate,luxury'],
            'travel_party' => ['nullable', 'string', 'in:solo,couple,friends,family_kids,seniors'],
            'pace' => ['nullable', 'string', 'in:relaxed,balanced,packed'],
            'interests' => ['nullable', 'array'],
            'interests.*' => ['string', 'max:50'],
        ];
    }
}
