<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Circles;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class CreateDirectInvitationRequest extends FormRequest
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
            'friend_code' => ['required', 'string', 'max:32'],
            'proposed_role' => ['sometimes', 'string', Rule::in(['viewer', 'editor'])],
            'expires_in_days' => ['sometimes', 'integer', 'min:1', 'max:30'],
        ];
    }
}
