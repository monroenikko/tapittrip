<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Circles;

use Illuminate\Foundation\Http\FormRequest;

final class CreateTripInvitationRequest extends FormRequest
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
            'proposed_role' => ['sometimes', 'string', 'in:viewer,editor'],
            'max_uses' => ['sometimes', 'integer', 'min:1', 'max:25'],
            'expires_in_days' => ['sometimes', 'integer', 'min:1', 'max:30'],
        ];
    }
}
