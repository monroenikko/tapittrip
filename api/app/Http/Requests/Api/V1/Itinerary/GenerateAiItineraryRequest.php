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

    protected function prepareForValidation(): void
    {
        $budgetTier = $this->input('budget_tier');
        if ($budgetTier === 'budget') {
            $this->merge(['budget_tier' => 'low']);
        }

        $party = $this->input('travel_party');
        if ($party === 'family') {
            $this->merge(['travel_party' => 'family_kids']);
        }

        $pace = $this->input('pace');
        if ($pace === 'fast' || $pace === 'high_energy') {
            $this->merge(['pace' => 'packed']);
        }
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'destination' => ['nullable', 'string', 'max:255'],
            'duration_days' => ['nullable', 'integer', 'min:1', 'max:14'],
            'budget_tier' => ['nullable', 'string', 'in:low,budget,moderate,luxury'],
            'travel_party' => ['nullable', 'string', 'in:solo,couple,friends,family,family_kids,seniors'],
            'pace' => ['nullable', 'string', 'in:relaxed,balanced,packed,fast,high_energy'],
            'interests' => ['nullable', 'array'],
            'interests.*' => ['string', 'max:50'],
        ];
    }
}
