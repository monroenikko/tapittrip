<?php

declare(strict_types=1);

namespace App\Contracts;

use App\DTOs\Imports\ExtractedBookingData;

interface BookingExtractorInterface
{
    /**
     * Parse raw booking confirmation text, email, or voucher into structured booking fields.
     */
    public function extract(string $text, ?string $hintType = null): ?ExtractedBookingData;
}
