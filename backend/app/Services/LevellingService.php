<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\Transaction;
use App\Models\User;
use Carbon\Carbon;
use Carbon\CarbonInterface;
use MongoDB\BSON\ObjectId;

class LevellingService
{
    /**
     * Level definitions
     */
    const LEVELS = [
        1 => ['min' => 0,    'max' => 99,   'name' => 'Pemula',            'icon' => '🌱'],
        2 => ['min' => 100,  'max' => 249,  'name' => 'Pencatat Aktif',    'icon' => '📝'],
        3 => ['min' => 250,  'max' => 499,  'name' => 'Pengatur Keuangan', 'icon' => '📊'],
        4 => ['min' => 500,  'max' => 999,  'name' => 'Penabung Cerdas',   'icon' => '💰'],
        5 => ['min' => 1000, 'max' => 1999, 'name' => 'Investor Muda',     'icon' => '📈'],
        6 => ['min' => 2000, 'max' => 3999, 'name' => 'Ahli Finansial',    'icon' => '🏦'],
        7 => ['min' => 4000, 'max' => 7499, 'name' => 'Master Keuangan',   'icon' => '👑'],
        8 => ['min' => 7500, 'max' => PHP_INT_MAX, 'name' => 'Legend MonMon', 'icon' => '⭐'],
    ];

    /**
     * Streak milestone bonus poin
     */
    const STREAK_MILESTONES = [
        7   => 50,   // 7 hari streak → +50 bonus poin
        14  => 75,
        30  => 150,
        60  => 250,
        100 => 500,
        365 => 2000,
    ];

    /**
     * Poin per aksi
     */
    const POINTS = [
        'transaction_income'  => 5,
        'transaction_expense' => 2,
        'daily_login'         => 10,
        'achievement_unlock'  => 50,
    ];

    /**
     * Add poin ke user dan cek level up
     * Return array info (poin added, level up info, streak bonus)
     */
    public function addPoints(User $user, string $action, int $multiplier = 1): array
    {
        $pointsToAdd = (self::POINTS[$action] ?? 0) * $multiplier;

        if ($pointsToAdd === 0) {
            return $this->buildResult($user, 0, false, null);
        }

        $oldLevel = $user->level;
        $user->points += $pointsToAdd;

        // Cek level up
        $newLevel = $this->calculateLevel($user->points);
        $leveledUp = $newLevel > $oldLevel;

        if ($leveledUp) {
            $user->level = $newLevel;
        }

        $user->save();

        // Kirim notifikasi kalau level up
        if ($leveledUp) {
            $this->sendLevelUpNotification($user, $oldLevel, $newLevel);
        }

        return $this->buildResult($user, $pointsToAdd, $leveledUp, $leveledUp ? $newLevel : null);
    }

    /**
     * Recalculate daily recording streak from transaction dates.
     */
    public function refreshRecordingStreak(User $user, ?CarbonInterface $asOf = null): int
    {
        $transactionDates = Transaction::whereIn('user_id', $this->userIdCandidates($user))
            ->orderBy('date', 'desc')
            ->pluck('date');

        $streak = $this->calculateRecordingStreak($transactionDates, $asOf);

        if ((int) $user->streak !== $streak) {
            $user->streak = $streak;
            $user->save();
        }

        return $streak;
    }

    /**
     * Calculate the active streak from a list of transaction dates.
     *
     * A streak stays active through the current day if the latest record is
     * yesterday, then increases once the user records again today.
     */
    public function calculateRecordingStreak(iterable $dates, ?CarbonInterface $asOf = null): int
    {
        $recordedDays = [];

        foreach ($dates as $date) {
            if (empty($date)) {
                continue;
            }

            $recordedDays[$this->toCarbon($date)->toDateString()] = true;
        }

        if (empty($recordedDays)) {
            return 0;
        }

        $today = ($asOf ? Carbon::parse($asOf) : now())->startOfDay();
        $cursor = $today->copy();

        if (!isset($recordedDays[$cursor->toDateString()])) {
            $yesterday = $today->copy()->subDay();

            if (!isset($recordedDays[$yesterday->toDateString()])) {
                return 0;
            }

            $cursor = $yesterday;
        }

        $streak = 0;
        while (isset($recordedDays[$cursor->toDateString()])) {
            $streak++;
            $cursor->subDay();
        }

        return $streak;
    }

    private function toCarbon(mixed $date): Carbon
    {
        if ($date instanceof CarbonInterface) {
            return Carbon::parse($date)->startOfDay();
        }

        return Carbon::parse($date)->startOfDay();
    }

    private function userIdCandidates(User $user): array
    {
        $userId = (string) $user->id;
        $candidates = [$user->id, $userId];

        if (preg_match('/^[a-f0-9]{24}$/i', $userId)) {
            try {
                $candidates[] = new ObjectId($userId);
            } catch (\Throwable) {
                // Ignore invalid ObjectId representations.
            }
        }

        return $candidates;
    }

    /**
     * Award daily login points without changing the recording streak.
     */
    public function handleDailyLogin(User $user): array
    {
        $now = now();
        $lastActive = $user->last_active_date;
        $loginAction = 'first';
        $pointsInfo = $this->buildResult($user, 0, false, null);

        if ($lastActive) {
            $loginAction = $lastActive->copy()->startOfDay()->isSameDay($now)
                ? 'same_day'
                : 'new_day';
        }

        if ($loginAction !== 'same_day') {
            $pointsInfo = $this->addPoints($user, 'daily_login');
            $user = $user->fresh();
        }

        $user->last_active_date = $now;
        $user->save();

        return array_merge($pointsInfo, [
            'login_action' => $loginAction,
        ]);
    }

    /**
     * Handle daily login streak
     * Return array info (streak, bonus poin, milestone tercapai)
     */
    public function handleLoginStreak(User $user): array
    {
        $now = now();
        $lastActive = $user->last_active_date;
        $streakBonus = 0;
        $milestoneReached = null;
        $streakAction = 'continued'; // continued, reset, same_day

        if ($lastActive) {
            $lastActiveDate = $lastActive->startOfDay();
            $todayDate = $now->copy()->startOfDay();
            $daysDiff = $lastActiveDate->diffInDays($todayDate);

            if ($daysDiff === 0) {
                // Login di hari yang sama → tidak ada perubahan streak
                $streakAction = 'same_day';
            } elseif ($daysDiff === 1) {
                // Consecutive day → streak naik
                $user->streak += 1;
                $streakAction = 'continued';

                // Cek milestone
                $milestoneBonus = self::STREAK_MILESTONES[$user->streak] ?? 0;
                if ($milestoneBonus > 0) {
                    $user->points += $milestoneBonus;
                    $streakBonus = $milestoneBonus;
                    $milestoneReached = $user->streak;

                    // Recalculate level setelah milestone bonus
                    $user->level = $this->calculateLevel($user->points);

                    $this->sendStreakMilestoneNotification($user, $user->streak, $milestoneBonus);
                }
            } else {
                // Skip lebih dari 1 hari → streak reset
                $user->streak = 1;
                $streakAction = 'reset';
            }
        } else {
            // Login pertama kali
            $user->streak = 1;
            $streakAction = 'first';
        }

        // Add daily login poin (kecuali same_day)
        $loginPoints = 0;
        if ($streakAction !== 'same_day') {
            $loginPoints = self::POINTS['daily_login'];
            $oldLevel = $user->level;
            $user->points += $loginPoints;

            $newLevel = $this->calculateLevel($user->points);
            if ($newLevel > $oldLevel) {
                $user->level = $newLevel;
                $this->sendLevelUpNotification($user, $oldLevel, $newLevel);
            }
        }

        $user->last_active_date = $now;
        $user->save();

        return [
            'streak' => $user->streak,
            'streak_action' => $streakAction,
            'login_points_earned' => $loginPoints,
            'streak_bonus_earned' => $streakBonus,
            'milestone_reached' => $milestoneReached,
            'total_points' => $user->points,
            'current_level' => $this->getLevelInfo($user->level),
            'next_level' => $this->getNextLevelInfo($user->level, $user->points),
        ];
    }

    /**
     * Hitung level berdasarkan total poin
     */
    public function calculateLevel(int $points): int
    {
        foreach (array_reverse(self::LEVELS, true) as $level => $config) {
            if ($points >= $config['min']) {
                return $level;
            }
        }
        return 1;
    }

    /**
     * Get info level saat ini
     */
    public function getLevelInfo(int $level): array
    {
        $config = self::LEVELS[$level] ?? self::LEVELS[1];
        return [
            'level' => $level,
            'name' => $config['name'],
            'icon' => $config['icon'],
            'min_points' => $config['min'],
            'max_points' => $config['max'] === PHP_INT_MAX ? null : $config['max'],
        ];
    }

    /**
     * Get info level berikutnya + progress
     */
    public function getNextLevelInfo(int $currentLevel, int $currentPoints): ?array
    {
        $nextLevel = $currentLevel + 1;

        if (!isset(self::LEVELS[$nextLevel])) {
            return null; // Sudah max level
        }

        $nextConfig = self::LEVELS[$nextLevel];
        $currentConfig = self::LEVELS[$currentLevel];

        $pointsNeeded = $nextConfig['min'] - $currentPoints;
        $progressPoints = $currentPoints - $currentConfig['min'];
        $totalPointsForLevel = $nextConfig['min'] - $currentConfig['min'];
        $progressPercent = round(($progressPoints / $totalPointsForLevel) * 100, 1);

        return [
            'level' => $nextLevel,
            'name' => $nextConfig['name'],
            'icon' => $nextConfig['icon'],
            'points_needed' => max(0, $pointsNeeded),
            'progress_points' => $progressPoints,
            'total_points_for_level' => $totalPointsForLevel,
            'progress_percent' => min(100, $progressPercent),
        ];
    }

    /**
     * Get full level progress info untuk user
     */
    public function getLevelProgress(User $user): array
    {
        return [
            'current_points' => $user->points,
            'current_level' => $this->getLevelInfo($user->level),
            'next_level' => $this->getNextLevelInfo($user->level, $user->points),
            'streak' => $user->streak,
            'upcoming_milestones' => $this->getUpcomingMilestones($user->streak),
            'all_levels' => array_map(function ($level, $config) use ($user) {
                return [
                    'level' => $level,
                    'name' => $config['name'],
                    'icon' => $config['icon'],
                    'min_points' => $config['min'],
                    'is_current' => $level === $user->level,
                    'is_achieved' => $user->points >= $config['min'],
                ];
            }, array_keys(self::LEVELS), self::LEVELS),
        ];
    }

    /**
     * Get upcoming streak milestones
     */
    private function getUpcomingMilestones(int $currentStreak): array
    {
        $upcoming = [];
        foreach (self::STREAK_MILESTONES as $day => $bonus) {
            if ($day > $currentStreak) {
                $upcoming[] = [
                    'days' => $day,
                    'days_remaining' => $day - $currentStreak,
                    'bonus_points' => $bonus,
                ];
                if (count($upcoming) >= 3) break; // Tampilkan 3 milestone berikutnya
            }
        }
        return $upcoming;
    }

    /**
     * Kirim notifikasi level up
     */
    private function sendLevelUpNotification(User $user, int $oldLevel, int $newLevel): void
    {
        $newLevelInfo = self::LEVELS[$newLevel];

        Notification::create([
            'user_id' => $user->id,
            'title' => '🎉 Level Up!',
            'message' => "Selamat! Kamu naik ke level {$newLevel}: {$newLevelInfo['icon']} {$newLevelInfo['name']}",
            'type' => 'level_up',
            'is_read' => false,
            'data' => [
                'old_level' => $oldLevel,
                'new_level' => $newLevel,
                'level_name' => $newLevelInfo['name'],
                'level_icon' => $newLevelInfo['icon'],
            ],
        ]);
    }

    /**
     * Kirim notifikasi streak milestone
     */
    private function sendStreakMilestoneNotification(User $user, int $streak, int $bonusPoints): void
    {
        Notification::create([
            'user_id' => $user->id,
            'title' => '🔥 Streak Milestone!',
            'message' => "Luar biasa! {$streak} hari streak! Kamu mendapatkan bonus {$bonusPoints} poin!",
            'type' => 'streak_milestone',
            'is_read' => false,
            'data' => [
                'streak' => $streak,
                'bonus_points' => $bonusPoints,
            ],
        ]);
    }

    /**
     * Build result array
     */
    private function buildResult(User $user, int $pointsAdded, bool $leveledUp, ?int $newLevel): array
    {
        return [
            'points_earned' => $pointsAdded,
            'total_points' => $user->points,
            'leveled_up' => $leveledUp,
            'current_level' => $this->getLevelInfo($user->level),
            'next_level' => $this->getNextLevelInfo($user->level, $user->points),
        ];
    }
}
