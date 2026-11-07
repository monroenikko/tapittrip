<?php

declare(strict_types=1);

namespace App\Application\Media\Data;

use Illuminate\Http\UploadedFile;

final readonly class UploadMediaData
{
    public function __construct(
        public UploadedFile $file,
        public ?string $title = null,
        public ?string $attachableType = null,
        public ?string $attachableId = null,
        public ?string $notes = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function from(array $data, UploadedFile $file): self
    {
        return new self(
            file: $file,
            title: isset($data['title']) ? (string) $data['title'] : null,
            attachableType: isset($data['attachable_type']) ? (string) $data['attachable_type'] : null,
            attachableId: isset($data['attachable_id']) ? (string) $data['attachable_id'] : null,
            notes: isset($data['notes']) ? (string) $data['notes'] : null,
        );
    }
}
