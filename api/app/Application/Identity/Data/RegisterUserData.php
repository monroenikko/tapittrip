<?php

declare(strict_types=1);

namespace App\Application\Identity\Data;

final readonly class RegisterUserData
{
    public function __construct(
        public string $name,
        public string $email,
        public string $password,
        public ?string $deviceName = null,
        public ?string $displayName = null,
        public ?string $locale = null,
        public ?string $homeTimezone = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            name: (string) $data['name'],
            email: (string) $data['email'],
            password: (string) $data['password'],
            deviceName: isset($data['device_name']) ? (string) $data['device_name'] : null,
            displayName: isset($data['display_name']) ? (string) $data['display_name'] : null,
            locale: isset($data['locale']) ? (string) $data['locale'] : null,
            homeTimezone: isset($data['home_timezone']) ? (string) $data['home_timezone'] : null,
        );
    }
}
