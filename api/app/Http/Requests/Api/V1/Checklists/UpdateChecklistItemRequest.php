<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Checklists;

use Illuminate\Foundation\Http\FormRequest;

final class UpdateChecklistItemRequest extends FormRequest
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
            'title' => ['sometimes', 'string', 'max:255'],
            'category' => ['sometimes', 'string', 'in:documents,clothing,electronics,toiletries,health,gear,other'],
            'is_packed' => ['sometimes', 'boolean'],
            'quantity' => ['sometimes', 'integer', 'min:1', 'max:99'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'photo_url' => ['nullable', 'url', 'max:2048'],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
        ];
    }
}
