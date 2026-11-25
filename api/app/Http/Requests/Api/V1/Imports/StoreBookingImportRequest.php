<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Imports;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class StoreBookingImportRequest extends FormRequest
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
            'raw_text' => ['required_without_all:text,file', 'nullable', 'string', 'max:50000'],
            'text' => ['nullable', 'string', 'max:50000'],
            'file' => ['nullable', 'file', 'max:10240', 'mimes:pdf,jpg,jpeg,png,webp,heic'],
            'booking_type' => ['nullable', 'string', Rule::in(['flight', 'stay', 'activity', 'auto'])],
            'source' => ['nullable', 'string', Rule::in(['paste_text', 'upload_file', 'share_link'])],
            'client_operation_id' => ['nullable', 'uuid'],
        ];
    }
}
