<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Expenses;

use Illuminate\Foundation\Http\FormRequest;

final class CreateExpenseRequest extends FormRequest
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
            'payer_id' => ['nullable', 'uuid', 'exists:users,id'],
            'category' => ['required', 'string', 'in:dining,transport,accommodation,activities,shopping,other'],
            'title' => ['required', 'string', 'min:1', 'max:255'],
            'amount_minor' => ['required', 'integer', 'min:1'],
            'currency' => ['required', 'string', 'size:3'],
            'exchange_rate' => ['nullable', 'numeric', 'min:0.000001'],
            'expense_date' => ['required', 'date_format:Y-m-d'],
            'itinerary_item_id' => ['nullable', 'uuid', 'exists:itinerary_items,id'],
            'stay_id' => ['nullable', 'uuid', 'exists:stays,id'],
            'split_type' => ['nullable', 'string', 'in:single,equal,custom'],
            'splits' => ['nullable', 'array'],
            'splits.*.user_id' => ['required_with:splits', 'uuid', 'exists:users,id'],
            'splits.*.amount_minor' => ['required_with:splits', 'integer', 'min:1'],
            'splits.*.shares' => ['nullable', 'integer', 'min:1'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'receipt_url' => ['nullable', 'url', 'max:2048'],
        ];
    }
}
