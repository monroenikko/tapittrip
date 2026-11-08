<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Expenses;

use Illuminate\Foundation\Http\FormRequest;

final class UploadReceiptRequest extends FormRequest
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
            'file' => ['required', 'file', 'max:10240', 'mimes:jpeg,jpg,png,webp,pdf'],
        ];
    }
}
