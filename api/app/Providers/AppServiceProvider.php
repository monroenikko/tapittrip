<?php

namespace App\Providers;

use App\Contracts\BookingExtractorInterface;
use App\Contracts\ExchangeRateProviderInterface;
use App\Contracts\OAuthTokenVerifierInterface;
use App\Contracts\StayRecommendationProvider;
use App\Contracts\TranslationProviderInterface;
use App\Models\Trip;
use App\Policies\TripPolicy;
use App\Services\Expenses\FakeExchangeRateProvider;
use App\Services\Expenses\LiveExchangeRateProvider;
use App\Services\Identity\FakeOAuthTokenVerifier;
use App\Services\Identity\LiveOAuthTokenVerifier;
use App\Services\Imports\FakeBookingExtractor;
use App\Services\Imports\GeminiBookingExtractor;
use App\Services\Stays\GeminiStayRecommendationProvider;
use App\Services\Translation\FakeTranslationProvider;
use App\Services\Translation\GeminiTranslationProvider;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(StayRecommendationProvider::class, GeminiStayRecommendationProvider::class);
        $this->app->bind(ExchangeRateProviderInterface::class, function ($app) {
            if ($app->environment('testing')) {
                return new FakeExchangeRateProvider;
            }

            return new LiveExchangeRateProvider;
        });
        $this->app->bind(TranslationProviderInterface::class, function ($app) {
            if ($app->environment('testing')) {
                return new FakeTranslationProvider;
            }

            return new GeminiTranslationProvider;
        });
        $this->app->bind(BookingExtractorInterface::class, function ($app) {
            if ($app->environment('testing')) {
                return new FakeBookingExtractor;
            }

            return $app->make(GeminiBookingExtractor::class);
        });
        $this->app->bind(OAuthTokenVerifierInterface::class, function ($app) {
            if ($app->environment('testing')) {
                return new FakeOAuthTokenVerifier;
            }

            return new LiveOAuthTokenVerifier;
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(Trip::class, TripPolicy::class);
    }
}
