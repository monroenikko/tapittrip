<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Itinerary;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class VoteItineraryItemRequest extends FormRequest
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
            'vote' => ['nullable', 'string', Rule::in(['up', 'down', 'none'])],
        ];
    }
}
