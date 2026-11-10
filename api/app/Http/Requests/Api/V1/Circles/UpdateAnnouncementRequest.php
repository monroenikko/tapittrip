<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Circles;

use Illuminate\Foundation\Http\FormRequest;

final class UpdateAnnouncementRequest extends FormRequest
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
            'title' => ['sometimes', 'string', 'min:1', 'max:160'],
            'body' => ['sometimes', 'string', 'min:1', 'max:4000'],
            'is_pinned' => ['sometimes', 'boolean'],
            'base_version' => ['nullable', 'integer', 'min:1'],
        ];
    }
}

