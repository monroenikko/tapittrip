<?php

declare(strict_types=1);

namespace App\DTOs\Identity;

final readonly class LoginUserData
{
    public function __construct(
        public string $email,
        public string $password,
        public ?string $deviceName = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            email: (string) $data['email'],
            password: (string) $data['password'],
            deviceName: isset($data['device_name']) ? (string) $data['device_name'] : null,
        );
    }
}
