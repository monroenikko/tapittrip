<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Expenses;

use Illuminate\Foundation\Http\FormRequest;

final class RecordSettlementRequest extends FormRequest
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
            'payer_id' => ['required', 'uuid', 'exists:users,id'],
            'payee_id' => ['required', 'uuid', 'exists:users,id', 'different:payer_id'],
            'amount_minor' => ['required', 'integer', 'min:1'],
            'currency' => ['required', 'string', 'size:3'],
            'exchange_rate' => ['nullable', 'numeric', 'min:0.000001'],
            'rate_source' => ['nullable', 'string', 'in:identity,open_exchange_rates,cached_snapshot,user_manual,fake'],
            'rate_captured_at' => ['nullable', 'date'],
            'settled_at' => ['nullable', 'date'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'client_operation_id' => ['nullable', 'uuid'],
        ];
    }
}
