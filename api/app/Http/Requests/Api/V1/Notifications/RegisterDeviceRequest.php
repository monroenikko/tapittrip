<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Notifications;

use Illuminate\Foundation\Http\FormRequest;

final class RegisterDeviceRequest extends FormRequest
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
            'platform' => ['required', 'string', 'in:ios,android,web'],
            'device_key' => ['required', 'string', 'max:255'],
            'push_token' => ['nullable', 'string', 'max:1024'],
        ];
    }
}

