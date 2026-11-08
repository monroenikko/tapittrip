<?php

use App\Http\Controllers\Api\V1\AiItineraryController;
use App\Http\Controllers\Api\V1\AirportLoungeController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ChecklistController;
use App\Http\Controllers\Api\V1\ChecklistItemController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\GroupSettlementController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\ItineraryItemController;
use App\Http\Controllers\Api\V1\MediaController;
use App\Http\Controllers\Api\V1\NotificationPreferenceController;
use App\Http\Controllers\Api\V1\PlaceController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\ReminderController;
use App\Http\Controllers\Api\V1\StayController;
use App\Http\Controllers\Api\V1\StayTransportController;
use App\Http\Controllers\Api\V1\SyncController;
use App\Http\Controllers\Api\V1\TripBudgetController;
use App\Http\Controllers\Api\V1\TripController;
use App\Http\Controllers\Api\V1\TripDayController;
use App\Http\Controllers\Api\V1\TripExpenseController;
use App\Http\Controllers\Api\V1\TripTodayController;
use App\Http\Controllers\Api\V1\VisitEventController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', HealthController::class)->name('health.show');

    Route::post('/auth/register', [AuthController::class, 'register'])->name('auth.register');
    Route::post('/auth/login', [AuthController::class, 'login'])->name('auth.login');
    Route::post('/auth/token', [AuthController::class, 'login'])->name('auth.token');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('/auth/logout', [AuthController::class, 'logout'])->name('auth.logout');
        Route::get('/me', [ProfileController::class, 'show'])->name('me.show');
        Route::delete('/me', [ProfileController::class, 'destroy'])->name('me.destroy');

        Route::apiResource('trips', TripController::class);
        Route::get('/trips/{trip}/today', [TripTodayController::class, 'show'])->name('trips.today.show');

        Route::get('/trips/{trip}/days', [TripDayController::class, 'index'])->name('trips.days.index');
        Route::post('/trips/{trip}/days', [TripDayController::class, 'store'])->name('trips.days.store');

        Route::get('/trips/{trip}/itinerary-items', [ItineraryItemController::class, 'index'])->name('trips.itinerary-items.index');
        Route::post('/trips/{trip}/itinerary-items', [ItineraryItemController::class, 'store'])->name('trips.itinerary-items.store');
        Route::post('/trips/{trip}/itinerary-items/reorder', [ItineraryItemController::class, 'reorder'])->name('trips.itinerary-items.reorder');
        Route::get('/itinerary-items/{item}', [ItineraryItemController::class, 'show'])->name('itinerary-items.show');
        Route::patch('/itinerary-items/{item}', [ItineraryItemController::class, 'update'])->name('itinerary-items.update');
        Route::delete('/itinerary-items/{item}', [ItineraryItemController::class, 'destroy'])->name('itinerary-items.destroy');

        Route::post('/trips/{trip}/ai-plan/generate', [AiItineraryController::class, 'generate'])->name('trips.ai-plan.generate');
        Route::post('/trips/{trip}/ai-plan/apply', [AiItineraryController::class, 'apply'])->name('trips.ai-plan.apply');
        Route::post('/trips/{trip}/assistant/query', [AiItineraryController::class, 'ask'])->name('trips.assistant.query');

        Route::get('/places/search', [PlaceController::class, 'search'])->name('places.search');
        Route::post('/places', [PlaceController::class, 'store'])->name('places.store');
        Route::get('/places/{place}', [PlaceController::class, 'show'])->name('places.show');

        Route::get('/trips/{trip}/stays', [StayController::class, 'index'])->name('trips.stays.index');
        Route::post('/trips/{trip}/stays', [StayController::class, 'store'])->name('trips.stays.store');
        Route::get('/stays/{stay}', [StayController::class, 'show'])->name('stays.show');
        Route::patch('/stays/{stay}', [StayController::class, 'update'])->name('stays.update');
        Route::delete('/stays/{stay}', [StayController::class, 'destroy'])->name('stays.destroy');
        Route::post('/stays/{stay}/transport-options', [StayTransportController::class, 'compare'])->name('stays.transport-options.compare');

        Route::get('/trips/{trip}/budget', [TripBudgetController::class, 'show'])->name('trips.budget.show');
        Route::put('/trips/{trip}/budget', [TripBudgetController::class, 'store'])->name('trips.budget.store');

        Route::get('/trips/{trip}/expenses', [TripExpenseController::class, 'index'])->name('trips.expenses.index');
        Route::post('/trips/{trip}/expenses', [TripExpenseController::class, 'store'])->name('trips.expenses.store');
        Route::get('/trips/{trip}/expenses/summary', [TripExpenseController::class, 'summary'])->name('trips.expenses.summary');
        Route::get('/expenses/{expense}', [TripExpenseController::class, 'show'])->name('expenses.show');
        Route::patch('/expenses/{expense}', [TripExpenseController::class, 'update'])->name('expenses.update');
        Route::delete('/expenses/{expense}', [TripExpenseController::class, 'destroy'])->name('expenses.destroy');

        Route::get('/trips/{trip}/settlements', [GroupSettlementController::class, 'index'])->name('trips.settlements.index');
        Route::post('/trips/{trip}/settlements', [GroupSettlementController::class, 'store'])->name('trips.settlements.store');

        Route::get('/trips/{trip}/checklists', [ChecklistController::class, 'index'])->name('trips.checklists.index');
        Route::post('/trips/{trip}/checklists', [ChecklistController::class, 'store'])->name('trips.checklists.store');
        Route::post('/trips/{trip}/checklists/apply-template', [ChecklistController::class, 'applyTemplate'])->name('trips.checklists.apply-template');
        Route::get('/checklists/{checklist}', [ChecklistController::class, 'show'])->name('checklists.show');
        Route::delete('/checklists/{checklist}', [ChecklistController::class, 'destroy'])->name('checklists.destroy');

        Route::post('/checklists/{checklist}/items', [ChecklistItemController::class, 'store'])->name('checklists.items.store');
        Route::patch('/checklist-items/{item}', [ChecklistItemController::class, 'update'])->name('checklist-items.update');
        Route::post('/checklist-items/{item}/toggle', [ChecklistItemController::class, 'toggle'])->name('checklist-items.toggle');
        Route::delete('/checklist-items/{item}', [ChecklistItemController::class, 'destroy'])->name('checklist-items.destroy');
        Route::post('/checklist-items/{item}/photo', [ChecklistItemController::class, 'uploadPhoto'])->name('checklist-items.photo.upload');

        Route::get('/trips/{trip}/media', [MediaController::class, 'index'])->name('trips.media.index');
        Route::post('/trips/{trip}/media', [MediaController::class, 'store'])->name('trips.media.store');
        Route::get('/trips/{trip}/media/{media}', [MediaController::class, 'show'])->name('trips.media.show');
        Route::delete('/trips/{trip}/media/{media}', [MediaController::class, 'destroy'])->name('trips.media.destroy');

        Route::post('/devices/register', [DeviceController::class, 'register'])->name('devices.register');
        Route::get('/me/notification-preferences', [NotificationPreferenceController::class, 'show'])->name('me.notification-preferences.show');
        Route::put('/me/notification-preferences', [NotificationPreferenceController::class, 'update'])->name('me.notification-preferences.update');

        Route::get('/trips/{trip}/reminders', [ReminderController::class, 'index'])->name('trips.reminders.index');
        Route::post('/trips/{trip}/reminders/generate', [ReminderController::class, 'generate'])->name('trips.reminders.generate');

        Route::post('/itinerary-items/{item}/visit-events', [VisitEventController::class, 'store'])->name('itinerary-items.visit-events.store');

        Route::post('/sync/push', [SyncController::class, 'push'])->name('sync.push');
        Route::get('/sync/pull', [SyncController::class, 'pull'])->name('sync.pull');

        Route::get('/airports/{iata}/lounges', [AirportLoungeController::class, 'index'])->name('airports.lounges.index');
        Route::get('/lounges/{lounge}', [AirportLoungeController::class, 'show'])->name('lounges.show');
    });
});
