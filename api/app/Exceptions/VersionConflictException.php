<?php

declare(strict_types=1);

namespace App\Exceptions;

use Illuminate\Contracts\Debug\ShouldntReport;
use RuntimeException;

final class VersionConflictException extends RuntimeException implements ShouldntReport
{
    /**
     * @param  array<string, mixed>  $serverPayload
     */
    public function __construct(
        public readonly int $serverVersion,
        public readonly array $serverPayload = [],
        string $message = 'The record was modified by another device. Review the latest changes before saving.',
    ) {
        parent::__construct($message);
    }
}

