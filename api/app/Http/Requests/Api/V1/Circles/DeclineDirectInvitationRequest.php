<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Circles;

use Illuminate\Foundation\Http\FormRequest;

final class DeclineDirectInvitationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'block_sender' => ['sometimes', 'boolean'],
        ];
    }
}
