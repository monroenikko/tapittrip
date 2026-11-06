<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Checklists;

use Illuminate\Foundation\Http\FormRequest;

final class StoreChecklistRequest extends FormRequest
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
            'title' => ['required', 'string', 'max:255'],
            'type' => ['sometimes', 'string', 'in:packing,documents,departure,return,custom'],
            'description' => ['nullable', 'string', 'max:1000'],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
        ];
    }
}
