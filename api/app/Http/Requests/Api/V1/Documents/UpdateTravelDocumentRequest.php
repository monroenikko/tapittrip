<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Documents;

use App\Models\TravelDocument;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class UpdateTravelDocumentRequest extends FormRequest
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
            'base_version' => ['required', 'integer', 'min:1'],
            'document_type' => ['sometimes', 'string', Rule::in(TravelDocument::TYPES)],
            'display_name' => ['sometimes', 'string', 'min:1', 'max:160'],
            'issuer' => ['nullable', 'string', 'max:160'],
            'reference_number' => ['nullable', 'string', 'max:160'],
            'notes_private' => ['nullable', 'string', 'max:2000'],
            'expires_on' => ['nullable', 'date_format:Y-m-d'],
            'access_policy' => ['sometimes', 'string', Rule::in(TravelDocument::ACCESS_POLICIES)],
        ];
    }
}
