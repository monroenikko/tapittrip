<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Circles;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class InitiateOwnershipTransferRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'target_member_id' => ['required', 'uuid'],
            'former_owner_role' => ['sometimes', 'string', Rule::in(['editor', 'viewer'])],
        ];
    }
}
