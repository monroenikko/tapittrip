<?php

use App\Http\Controllers\Api\V1\ActivityFeedController;
use App\Http\Controllers\Api\V1\AiItineraryController;
use App\Http\Controllers\Api\V1\AirportLoungeController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BookingImportController;
use App\Http\Controllers\Api\V1\ChecklistController;
use App\Http\Controllers\Api\V1\ChecklistItemController;
use App\Http\Controllers\Api\V1\CountryController;
use App\Http\Controllers\Api\V1\CurrencyController;
use App\Http\Controllers\Api\V1\DestinationSafetyController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\FlightController;
use App\Http\Controllers\Api\V1\FoodSuggestionController;
use App\Http\Controllers\Api\V1\GroupSettlementController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\InvitationInboxController;
use App\Http\Controllers\Api\V1\InvitationRedemptionController;
use App\Http\Controllers\Api\V1\ItineraryItemController;
use App\Http\Controllers\Api\V1\MediaController;
use App\Http\Controllers\Api\V1\NotificationPreferenceController;
use App\Http\Controllers\Api\V1\PlaceController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\ReminderController;
use App\Http\Controllers\Api\V1\StayController;
use App\Http\Controllers\Api\V1\StayRecommendationController;
use App\Http\Controllers\Api\V1\StayTransportController;
use App\Http\Controllers\Api\V1\SyncController;
use App\Http\Controllers\Api\V1\TranslationController;
use App\Http\Controllers\Api\V1\TravelDocumentController;
use App\Http\Controllers\Api\V1\TripAnnouncementController;
use App\Http\Controllers\Api\V1\TripBudgetController;
use App\Http\Controllers\Api\V1\TripCircleController;
use App\Http\Controllers\Api\V1\TripController;
use App\Http\Controllers\Api\V1\TripDayController;
use App\Http\Controllers\Api\V1\TripExpenseController;
use App\Http\Controllers\Api\V1\TripJournalController;
use App\Http\Controllers\Api\V1\TripLocationShareController;
use App\Http\Controllers\Api\V1\TripNotificationController;
use App\Http\Controllers\Api\V1\TripRecapController;
use App\Http\Controllers\Api\V1\TripTodayController;
use App\Http\Controllers\Api\V1\TripTravelerController;
use App\Http\Controllers\Api\V1\TripWeatherController;
use App\Http\Controllers\Api\V1\VisitEventController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', HealthController::class)->name('health.show');
    Route::get('/countries', [CountryController::class, 'index'])->name('countries.index');

    Route::post('/auth/register', [AuthController::class, 'register'])->name('auth.register');
    Route::post('/auth/login', [AuthController::class, 'login'])->name('auth.login');
    Route::post('/auth/token', [AuthController::class, 'login'])->name('auth.token');
    Route::post('/auth/{provider}/exchange', [AuthController::class, 'exchangeOAuth'])->middleware('throttle:20,1')->name('auth.oauth.exchange');
    Route::get('/invitations/{token}', [InvitationRedemptionController::class, 'preview'])->middleware('throttle:30,1')->name('invitations.preview');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('/auth/logout', [AuthController::class, 'logout'])->name('auth.logout');
        Route::get('/me', [ProfileController::class, 'show'])->name('me.show');
        Route::patch('/me', [ProfileController::class, 'update'])->name('me.update');
        Route::delete('/me', [ProfileController::class, 'destroy'])->name('me.destroy');
        Route::post('/me/friend-code/regenerate', [ProfileController::class, 'regenerateFriendCode'])->middleware('throttle:10,1')->name('me.friend-code.regenerate');

        Route::get('/me/invitations', [InvitationInboxController::class, 'invitations'])->name('me.invitations.index');
        Route::post('/me/invitations/{invitation}/accept', [InvitationInboxController::class, 'acceptInvitation'])->middleware('throttle:20,1')->name('me.invitations.accept');
        Route::post('/me/invitations/{invitation}/decline', [InvitationInboxController::class, 'declineInvitation'])->middleware('throttle:20,1')->name('me.invitations.decline');
        Route::get('/me/ownership-transfers', [InvitationInboxController::class, 'ownershipTransfers'])->name('me.ownership-transfers.index');
        Route::post('/me/ownership-transfers/{transfer}/accept', [InvitationInboxController::class, 'acceptOwnershipTransfer'])->middleware('throttle:20,1')->name('me.ownership-transfers.accept');
        Route::post('/me/ownership-transfers/{transfer}/decline', [InvitationInboxController::class, 'declineOwnershipTransfer'])->middleware('throttle:20,1')->name('me.ownership-transfers.decline');

        Route::apiResource('trips', TripController::class);
        Route::get('/trips/{trip}/today', [TripTodayController::class, 'show'])->name('trips.today.show');
        Route::get('/trips/{trip}/weather', [TripWeatherController::class, 'show'])->name('trips.weather.show');
        Route::get('/trips/{trip}/safety', [DestinationSafetyController::class, 'showTrip'])->name('trips.safety.show');
        Route::get('/safety/countries', [DestinationSafetyController::class, 'index'])->name('safety.countries.index');
        Route::get('/safety/countries/{country}', [DestinationSafetyController::class, 'showCountry'])->name('safety.countries.show');

        Route::get('/trips/{trip}/phrasebook', [TranslationController::class, 'tripPhrasebook'])->name('trips.phrasebook.show');
        Route::get('/translation/languages', [TranslationController::class, 'languages'])->name('translation.languages.index');
        Route::get('/translation/phrasebook/{language}', [TranslationController::class, 'phrasebook'])->name('translation.phrasebook.show');
        Route::post('/translation/translate', [TranslationController::class, 'translate'])->middleware('throttle:30,1')->name('translation.translate');

        Route::get('/trips/{trip}/documents', [TravelDocumentController::class, 'index'])->name('trips.documents.index');
        Route::post('/trips/{trip}/documents', [TravelDocumentController::class, 'store'])->name('trips.documents.store');
        Route::post('/documents/{document}/attachment', [TravelDocumentController::class, 'uploadAttachment'])->name('documents.attachment.store');
        Route::get('/documents/{document}/download', [TravelDocumentController::class, 'download'])->name('documents.download');
        Route::patch('/documents/{document}', [TravelDocumentController::class, 'update'])->name('documents.update');
        Route::delete('/documents/{document}', [TravelDocumentController::class, 'destroy'])->name('documents.destroy');

        Route::get('/trips/{trip}/imports', [BookingImportController::class, 'index'])->name('trips.imports.index');
        Route::post('/trips/{trip}/imports', [BookingImportController::class, 'store'])->name('trips.imports.store');
        Route::get('/imports/{import}', [BookingImportController::class, 'show'])->name('imports.show');
        Route::get('/imports/{import}/download', [BookingImportController::class, 'download'])->name('imports.download');
        Route::post('/imports/{import}/confirm', [BookingImportController::class, 'confirm'])->name('imports.confirm');
        Route::delete('/imports/{import}', [BookingImportController::class, 'destroy'])->name('imports.destroy');

        Route::get('/trips/{trip}/days', [TripDayController::class, 'index'])->name('trips.days.index');
        Route::post('/trips/{trip}/days', [TripDayController::class, 'store'])->name('trips.days.store');

        Route::get('/trips/{trip}/itinerary-items', [ItineraryItemController::class, 'index'])->name('trips.itinerary-items.index');
        Route::post('/trips/{trip}/itinerary-items', [ItineraryItemController::class, 'store'])->name('trips.itinerary-items.store');
        Route::post('/trips/{trip}/itinerary-items/reorder', [ItineraryItemController::class, 'reorder'])->name('trips.itinerary-items.reorder');
        Route::post('/trips/{trip}/itinerary-items/optimize-route', [ItineraryItemController::class, 'optimizeRoute'])->name('trips.itinerary-items.optimize-route');
        Route::get('/trips/{trip}/food-suggestions', [FoodSuggestionController::class, 'index'])->name('trips.food-suggestions.index');
        Route::get('/itinerary-items/{item}', [ItineraryItemController::class, 'show'])->name('itinerary-items.show');
        Route::patch('/itinerary-items/{item}', [ItineraryItemController::class, 'update'])->name('itinerary-items.update');
        Route::delete('/itinerary-items/{item}', [ItineraryItemController::class, 'destroy'])->name('itinerary-items.destroy');
        Route::post('/itinerary-items/{item}/vote', [ItineraryItemController::class, 'vote'])->name('itinerary-items.vote');

        Route::post('/trips/{trip}/ai-plan/generate', [AiItineraryController::class, 'generate'])->name('trips.ai-plan.generate');
        Route::post('/trips/{trip}/ai-plan/apply', [AiItineraryController::class, 'apply'])->name('trips.ai-plan.apply');
        Route::post('/trips/{trip}/ai-plan/replan', [AiItineraryController::class, 'replan'])->name('trips.ai-plan.replan');
        Route::post('/trips/{trip}/assistant/query', [AiItineraryController::class, 'ask'])->name('trips.assistant.query');

        Route::get('/places/search', [PlaceController::class, 'search'])->name('places.search');
        Route::post('/places', [PlaceController::class, 'store'])->name('places.store');
        Route::get('/places/{place}', [PlaceController::class, 'show'])->name('places.show');

        Route::post('/trips/{trip}/stay-recommendations', StayRecommendationController::class)->middleware('throttle:6,1')->name('trips.stay-recommendations');

        Route::get('/trips/{trip}/flights', [FlightController::class, 'index'])->name('trips.flights.index');
        Route::post('/trips/{trip}/flights', [FlightController::class, 'store'])->name('trips.flights.store');
        Route::patch('/flights/{flight}', [FlightController::class, 'update'])->name('flights.update');
        Route::delete('/flights/{flight}', [FlightController::class, 'destroy'])->name('flights.destroy');

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
        Route::post('/expenses/{expense}/receipt', [TripExpenseController::class, 'uploadReceipt'])->name('expenses.receipt.upload');

        Route::get('/trips/{trip}/settlements', [GroupSettlementController::class, 'index'])->name('trips.settlements.index');
        Route::post('/trips/{trip}/settlements', [GroupSettlementController::class, 'store'])->name('trips.settlements.store');

        Route::get('/currencies/rates', [CurrencyController::class, 'rate'])->name('currencies.rates');

        Route::get('/trips/{trip}/journal', [TripJournalController::class, 'index'])->name('trips.journal.index');
        Route::post('/trips/{trip}/journal', [TripJournalController::class, 'store'])->name('trips.journal.store');
        Route::get('/journal-entries/{entry}', [TripJournalController::class, 'show'])->name('journal-entries.show');
        Route::patch('/journal-entries/{entry}', [TripJournalController::class, 'update'])->name('journal-entries.update');
        Route::delete('/journal-entries/{entry}', [TripJournalController::class, 'destroy'])->name('journal-entries.destroy');
        Route::post('/journal-entries/{entry}/photos', [TripJournalController::class, 'uploadPhoto'])->name('journal-entries.photos.upload');

        Route::get('/trips/{trip}/feed', [ActivityFeedController::class, 'index'])->name('trips.feed.index');
        Route::get('/trips/{trip}/announcements', [TripAnnouncementController::class, 'index'])->name('trips.announcements.index');
        Route::post('/trips/{trip}/announcements', [TripAnnouncementController::class, 'store'])->middleware('throttle:20,1')->name('trips.announcements.store');
        Route::patch('/announcements/{announcement}', [TripAnnouncementController::class, 'update'])->name('announcements.update');
        Route::delete('/announcements/{announcement}', [TripAnnouncementController::class, 'destroy'])->name('announcements.destroy');
        Route::get('/trips/{trip}/recap', [TripRecapController::class, 'show'])->name('trips.recap.show');

        Route::get('/trips/{trip}/members', [TripCircleController::class, 'members'])->name('trips.members.index');
        Route::patch('/trips/{trip}/members/{member}', [TripCircleController::class, 'updateMemberRole'])->name('trips.members.update');
        Route::delete('/trips/{trip}/members/{member}', [TripCircleController::class, 'removeMember'])->name('trips.members.destroy');
        Route::get('/trips/{trip}/travelers', [TripTravelerController::class, 'index'])->name('trips.travelers.index');
        Route::post('/trips/{trip}/travelers', [TripTravelerController::class, 'store'])->name('trips.travelers.store');
        Route::patch('/travelers/{traveler}', [TripTravelerController::class, 'update'])->name('travelers.update');
        Route::delete('/travelers/{traveler}', [TripTravelerController::class, 'destroy'])->name('travelers.destroy');
        Route::get('/trips/{trip}/invitations', [TripCircleController::class, 'invitations'])->name('trips.invitations.index');
        Route::post('/trips/{trip}/invitations', [TripCircleController::class, 'storeInvitation'])->middleware('throttle:20,1')->name('trips.invitations.store');
        Route::post('/trips/{trip}/invitations/direct', [TripCircleController::class, 'storeDirectInvitation'])->middleware('throttle:20,1')->name('trips.invitations.direct');
        Route::delete('/trips/{trip}/invitations/{invitation}', [TripCircleController::class, 'revokeInvitation'])->name('trips.invitations.revoke');
        Route::get('/trips/{trip}/ownership-transfer', [TripCircleController::class, 'pendingOwnershipTransfer'])->name('trips.ownership-transfer.show');
        Route::post('/trips/{trip}/ownership-transfer', [TripCircleController::class, 'initiateOwnershipTransfer'])->middleware('throttle:20,1')->name('trips.ownership-transfer.store');
        Route::delete('/trips/{trip}/ownership-transfer/{transfer}', [TripCircleController::class, 'cancelOwnershipTransfer'])->name('trips.ownership-transfer.destroy');
        Route::post('/invitations/{token}/accept', [InvitationRedemptionController::class, 'accept'])->middleware('throttle:20,1')->name('invitations.accept');
        Route::get('/trips/{trip}/location-share', [TripLocationShareController::class, 'show'])->name('trips.location-share.show');
        Route::post('/trips/{trip}/location-share', [TripLocationShareController::class, 'store'])->middleware('throttle:30,1')->name('trips.location-share.store');
        Route::patch('/trips/{trip}/location-share', [TripLocationShareController::class, 'update'])->middleware('throttle:60,1')->name('trips.location-share.update');
        Route::get('/trips/{trip}/location-shares', [TripLocationShareController::class, 'index'])->name('trips.location-shares.index');

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
        Route::get('/me/notifications', [TripNotificationController::class, 'index'])->name('me.notifications.index');
        Route::post('/me/notifications/{notification}/read', [TripNotificationController::class, 'markRead'])->name('me.notifications.read');
        Route::get('/me/notification-preferences', [NotificationPreferenceController::class, 'show'])->name('me.notification-preferences.show');
        Route::put('/me/notification-preferences', [NotificationPreferenceController::class, 'update'])->name('me.notification-preferences.update');

        Route::get('/trips/{trip}/reminders', [ReminderController::class, 'index'])->name('trips.reminders.index');
        Route::post('/trips/{trip}/reminders/generate', [ReminderController::class, 'generate'])->name('trips.reminders.generate');

        Route::post('/itinerary-items/{item}/visit-events', [VisitEventController::class, 'store'])->name('itinerary-items.visit-events.store');

        Route::post('/sync/push', [SyncController::class, 'push'])->name('sync.push');
        Route::get('/sync/pull', [SyncController::class, 'pull'])->name('sync.pull');

        Route::get('/airports', [AirportLoungeController::class, 'airports'])->name('airports.index');
        Route::get('/airports/{iata}/lounges', [AirportLoungeController::class, 'index'])->name('airports.lounges.index');
        Route::get('/lounges/{lounge}', [AirportLoungeController::class, 'show'])->name('lounges.show');
    });
});
