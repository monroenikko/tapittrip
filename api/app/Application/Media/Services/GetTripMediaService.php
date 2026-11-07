<?php

declare(strict_types=1);

namespace App\Application\Media\Services;

use App\Domain\Media\Models\MediaAttachment;
use App\Domain\Trips\Models\Trip;
use Illuminate\Database\Eloquent\Collection;

final class GetTripMediaService
{
    /**
     * Get all media attachments for a trip.
     *
     * @return Collection<int, MediaAttachment>
     */
    public function handle(Trip $trip, ?string $attachableType = null): Collection
    {
        $query = $trip->mediaAttachments()->with(['uploadedBy']);

        if ($attachableType !== null) {
            $query->where('attachable_type', $attachableType);
        }

        return $query->get();
    }
}
