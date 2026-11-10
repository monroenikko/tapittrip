<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ReminderResource;
use App\Models\Trip;
use App\Services\Notifications\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Gate;

final class ReminderController extends Controller
{
    public function __construct(
        private readonly NotificationService $notificationService,
    ) {}

    /**
     * List scheduled reminders for a trip.
     */
    public function index(
        Request $request,
        Trip $trip,
    ): AnonymousResourceCollection {
        Gate::authorize('view', $trip);

        $status = $request->query('status');
        $reminders = $this->notificationService->getTripReminders($trip, is_string($status) ? $status : null);

        return ReminderResource::collection($reminders);
    }

    /**
     * Generate or recalculate scheduled reminders for a trip.
     */
    public function generate(
        Request $request,
        Trip $trip,
    ): AnonymousResourceCollection {
        Gate::authorize('update', $trip);

        $reminders = $this->notificationService->scheduleTripReminders($trip, $request->user());

        return ReminderResource::collection($reminders);
    }
}
