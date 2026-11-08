<?php

declare(strict_types=1);

namespace App\Application\Notifications\Data;

final readonly class RegisterDeviceData
{
    public function __construct(
        public string $platform,
        public string $deviceKey,
        public ?string $pushToken = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data): self
    {
        return new self(
            platform: (string) $data['platform'],
            deviceKey: (string) $data['device_key'],
            pushToken: isset($data['push_token']) ? (string) $data['push_token'] : null,
        );
    }
}
