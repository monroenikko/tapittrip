<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Expenses;

use Illuminate\Foundation\Http\FormRequest;

final class SetTripBudgetRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, list<string>>
     */
    public function rules(): array
    {
        return [
            'currency' => ['required', 'string', 'size:3'],
            'total_budget_minor' => ['required', 'integer', 'min:1'],
            'daily_budget_minor' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
