<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Application\Notifications\Services\GetTripRemindersService;
use App\Application\Notifications\Services\ScheduleTripRemindersService;
use App\Domain\Trips\Models\Trip;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ReminderResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;

final class ReminderController extends Controller
{
    /**
     * List scheduled reminders for a trip.
     */
    public function index(
        Request $request,
        Trip $trip,
        GetTripRemindersService $service,
    ): AnonymousResourceCollection {
        Gate::authorize('view', $trip);

        $status = $request->query('status');
        $reminders = $service->execute($trip, is_string($status) ? $status : null);

        return ReminderResource::collection($reminders);
    }

    /**
     * Generate or recalculate scheduled reminders for a trip.
     */
    public function generate(
        Request $request,
        Trip $trip,
        ScheduleTripRemindersService $service,
    ): AnonymousResourceCollection {
        Gate::authorize('update', $trip);

        $reminders = $service->execute($trip, $request->user());

        return ReminderResource::collection($reminders);
    }
}
