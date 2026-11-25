<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Auth;

use Illuminate\Foundation\Http\FormRequest;

final class ExchangeOAuthRequest extends FormRequest
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
            'id_token' => ['required', 'string', 'min:10', 'max:8192'],
            'device_name' => ['nullable', 'string', 'max:120'],
            'display_name' => ['nullable', 'string', 'max:120'],
            'locale' => ['nullable', 'string', 'max:16'],
            'home_timezone' => ['nullable', 'string', 'timezone:all'],
        ];
    }
}
