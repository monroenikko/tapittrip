<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Expenses;

use Illuminate\Foundation\Http\FormRequest;

final class UpdateExpenseRequest extends FormRequest
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
            'category' => ['nullable', 'string', 'in:dining,transport,accommodation,activities,shopping,other'],
            'title' => ['nullable', 'string', 'min:1', 'max:255'],
            'amount_minor' => ['nullable', 'integer', 'min:1'],
            'currency' => ['nullable', 'string', 'size:3'],
            'exchange_rate' => ['nullable', 'numeric', 'min:0.000001'],
            'rate_source' => ['nullable', 'string', 'in:identity,open_exchange_rates,cached_snapshot,user_manual,fake,unavailable'],
            'rate_captured_at' => ['nullable', 'date'],
            'conversion_status' => ['nullable', 'string', 'in:converted,unavailable'],
            'expense_date' => ['nullable', 'date_format:Y-m-d'],
            'itinerary_item_id' => ['nullable', 'uuid', 'exists:itinerary_items,id'],
            'stay_id' => ['nullable', 'uuid', 'exists:stays,id'],
            'split_type' => ['nullable', 'string', 'in:single,equal,selected,custom'],
            'visibility' => ['nullable', 'string', 'in:private,shared'],
            'participant_ids' => ['nullable', 'array'],
            'participant_ids.*' => ['required_with:participant_ids', 'uuid', 'exists:users,id'],
            'splits' => ['nullable', 'array'],
            'splits.*.user_id' => ['required_with:splits', 'uuid', 'exists:users,id'],
            'splits.*.amount_minor' => ['required_with:splits', 'integer', 'min:1'],
            'splits.*.shares' => ['nullable', 'integer', 'min:1'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'receipt_url' => ['nullable', 'url', 'max:2048'],
            'base_version' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
