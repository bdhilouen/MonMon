<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Services\AchievementService;
use Laravel\Sanctum\Sanctum;
use App\Models\PersonalAccessToken;
use App\Services\LevellingService;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(AchievementService::class, fn() => new AchievementService());
        $this->app->singleton(LevellingService::class, fn() => new LevellingService());
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // ✅ Tell Sanctum to use MongoDB model
        Sanctum::usePersonalAccessTokenModel(PersonalAccessToken::class);
    }
}
