<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Sync;

use Illuminate\Foundation\Http\FormRequest;

final class PushSyncOperationsRequest extends FormRequest
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
            'device_key' => ['required', 'string', 'max:255'],
            'operations' => ['required', 'array', 'min:1'],
            'operations.*.operation_id' => ['required', 'uuid'],
            'operations.*.trip_id' => ['nullable', 'uuid'],
            'operations.*.entity_type' => ['required', 'string', 'in:trip,itinerary_item,stay,checklist_item'],
            'operations.*.entity_id' => ['required', 'uuid'],
            'operations.*.operation_type' => ['required', 'string', 'in:create,update,delete'],
            'operations.*.payload' => ['nullable', 'array'],
            'operations.*.base_version' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
