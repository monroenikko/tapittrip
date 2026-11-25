<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Translation;

use Illuminate\Foundation\Http\FormRequest;

final class TranslateTextRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'text' => ['required', 'string', 'min:1', 'max:500'],
            'source_language' => ['sometimes', 'string', 'max:32'],
            'target_language' => ['required', 'string', 'max:64'],
            'consent_cloud' => ['required', 'boolean'],
        ];
    }
}
