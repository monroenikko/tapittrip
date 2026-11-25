<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Circles;

use Illuminate\Foundation\Http\FormRequest;

final class StoreAnnouncementRequest extends FormRequest
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
            'title' => ['required', 'string', 'min:1', 'max:160'],
            'body' => ['required', 'string', 'min:1', 'max:4000'],
            'is_pinned' => ['sometimes', 'boolean'],
            'client_operation_id' => ['nullable', 'uuid'],
        ];
    }
}
