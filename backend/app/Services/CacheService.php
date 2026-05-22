<?php

namespace App\Services;

use Carbon\Carbon;
use Carbon\CarbonInterface;
use Illuminate\Support\Facades\Cache;

class CacheService
{
    public const TTL_SHORT = 300;

    public const TTL_MEDIUM = 1800;

    public const TTL_LONG = 3600;

    public const TTL_VERY_LONG = 86400;

    public const TTL_PERMANENT = 2592000;

    public static function rememberSmart(string $key, string $type, callable $callback)
    {
        return Cache::remember($key, self::ttlFor($type), $callback);
    }

    public static function dashboardKey($userId, string $month): string
    {
        return 'dashboard_'.self::normalizeUserId($userId).'_'.$month;
    }

    public static function wrappedKey($userId, string $month): string
    {
        return 'wrapped_'.self::normalizeUserId($userId).'_'.$month;
    }

    public static function categoriesKey($userId): string
    {
        return 'categories_user_'.self::normalizeUserId($userId);
    }

    public static function clearUserCache($userId, array $months = []): void
    {
        $userId = self::normalizeUserId($userId);
        $months = array_unique(array_filter(array_merge([now()->format('Y-m')], $months)));

        foreach ($months as $month) {
            Cache::forget(self::dashboardKey($userId, $month));
            Cache::forget(self::wrappedKey($userId, $month));
        }

        Cache::forget(self::categoriesKey($userId));
    }

    public static function monthFromDate($date): ?string
    {
        if ($date instanceof CarbonInterface) {
            return $date->format('Y-m');
        }

        if (empty($date)) {
            return null;
        }

        return Carbon::parse($date)->format('Y-m');
    }

    private static function ttlFor(string $type): int
    {
        return match ($type) {
            'dashboard' => self::TTL_MEDIUM,
            'wrapped_current', 'categories' => self::TTL_LONG,
            'wrapped_past' => self::TTL_PERMANENT,
            'achievements' => self::TTL_VERY_LONG,
            default => self::TTL_SHORT,
        };
    }

    private static function normalizeUserId($userId): string
    {
        return (string) $userId;
    }
}
