<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Profile;

use Illuminate\Foundation\Http\FormRequest;

final class UpdateProfileRequest extends FormRequest
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
            'display_name' => ['nullable', 'string', 'max:255'],
            'permanent_address' => ['nullable', 'string', 'max:255'],
            'home_country' => ['nullable', 'string', 'max:100'],
            'home_currency' => ['nullable', 'string', 'max:10'],
            'home_timezone' => ['nullable', 'string', 'max:64'],
            'locale' => ['nullable', 'string', 'max:12'],
        ];
    }
}
