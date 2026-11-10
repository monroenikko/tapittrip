<?php

declare(strict_types=1);

namespace App\DTOs\Identity;

final readonly class UpdateProfileData
{
    public function __construct(
        public ?string $displayName = null,
        public ?string $permanentAddress = null,
        public ?string $homeCountry = null,
        public ?string $homeCurrency = null,
        public ?string $homeTimezone = null,
        public ?string $locale = null,
        public ?bool $acceptsDirectInvites = null,
        public bool $hasDisplayName = false,
        public bool $hasPermanentAddress = false,
        public bool $hasHomeCountry = false,
        public bool $hasHomeCurrency = false,
        public bool $hasHomeTimezone = false,
        public bool $hasLocale = false,
        public bool $hasAcceptsDirectInvites = false,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            displayName: isset($data['display_name']) ? (string) $data['display_name'] : null,
            permanentAddress: isset($data['permanent_address']) ? (string) $data['permanent_address'] : null,
            homeCountry: isset($data['home_country']) ? (string) $data['home_country'] : null,
            homeCurrency: isset($data['home_currency']) ? (string) $data['home_currency'] : null,
            homeTimezone: isset($data['home_timezone']) ? (string) $data['home_timezone'] : null,
            locale: isset($data['locale']) ? (string) $data['locale'] : null,
            acceptsDirectInvites: array_key_exists('accepts_direct_invites', $data) ? (bool) $data['accepts_direct_invites'] : null,
            hasDisplayName: array_key_exists('display_name', $data),
            hasPermanentAddress: array_key_exists('permanent_address', $data),
            hasHomeCountry: array_key_exists('home_country', $data),
            hasHomeCurrency: array_key_exists('home_currency', $data),
            hasHomeTimezone: array_key_exists('home_timezone', $data),
            hasLocale: array_key_exists('locale', $data),
            hasAcceptsDirectInvites: array_key_exists('accepts_direct_invites', $data),
        );
    }
}
