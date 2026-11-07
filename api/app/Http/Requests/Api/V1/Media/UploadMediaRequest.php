<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Media;

use Illuminate\Foundation\Http\FormRequest;

final class UploadMediaRequest extends FormRequest
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
            'file' => ['required', 'file', 'max:10240', 'mimes:jpeg,jpg,png,webp,heic,pdf'],
            'title' => ['nullable', 'string', 'max:255'],
            'attachable_type' => ['nullable', 'string', 'in:checklist_item,stay,itinerary_item,trip_document'],
            'attachable_id' => ['nullable', 'uuid'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
