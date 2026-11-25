<?php

declare(strict_types=1);

namespace App\Contracts;

use App\DTOs\Itinerary\TripAssistantResult;
use App\Models\Trip;

interface StayRecommendationProvider
{
    public function recommend(Trip $trip): ?TripAssistantResult;
}
