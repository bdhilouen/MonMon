<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Achievement;
use App\Models\UserAchievement;
use App\Services\AchievementService;
use Illuminate\Http\Request;

class AchievementController extends Controller
{
    protected $achievementService;

    public function __construct(AchievementService $achievementService)
    {
        $this->achievementService = $achievementService;
    }

    /**
     * Get all achievements with unlock status
     * Optimized: Single query with left join concept
     */
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        // Get all achievements
        $achievements = Achievement::all();

        $unlockedByAchievement = UserAchievement::where('user_id', $userId)
            ->get()
            ->mapWithKeys(fn ($item) => [(string) $item->achievement_id => $item->unlocked_at])
            ->all();

        // Combine data
        $achievementsWithStatus = $achievements->map(function ($achievement) use ($unlockedByAchievement, $request) {
            $achievementId = (string) $achievement->_id;
            $unlockedAt = $unlockedByAchievement[$achievementId] ?? null;
            $progress = $this->achievementService->progressFor($request->user(), $achievement);

            return [
                'id' => $achievementId,
                'title' => $achievement->title,
                'description' => $achievement->description,
                'condition_type' => $achievement->condition_type,
                'condition_value' => $achievement->condition_value,
                'icon' => $achievement->icon,
                'is_unlocked' => $unlockedAt !== null,
                'unlocked_at' => $unlockedAt,
                'progress_current' => $progress['current'],
                'progress_target' => $progress['target'],
                'progress_percentage' => $unlockedAt !== null ? 100 : $progress['percentage'],
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $achievementsWithStatus,
        ]);
    }

    /**
     * Get only user's unlocked achievements
     */
    public function myAchievements(Request $request)
    {
        $userId = $request->user()->id;

        // Optimized: eager load achievement details
        $userAchievements = UserAchievement::where('user_id', $userId)
            ->with('achievement')
            ->orderBy('unlocked_at', 'desc')
            ->get()
            ->map(function ($ua) {
                return [
                    'id' => $ua->achievement->_id,
                    'title' => $ua->achievement->title,
                    'description' => $ua->achievement->description,
                    'icon' => $ua->achievement->icon,
                    'unlocked_at' => $ua->unlocked_at,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $userAchievements,
        ]);
    }

    /**
     * Check and unlock new achievements
     * Called after significant user actions
     */
    public function checkAchievements(Request $request)
    {
        $user = $request->user();
        $newlyUnlocked = $this->achievementService->checkAndUnlockAchievements($user);

        return response()->json([
            'success' => true,
            'data' => [
                'newly_unlocked' => $newlyUnlocked,
                'message' => count($newlyUnlocked) > 0
                    ? 'Congratulations! You unlocked '.count($newlyUnlocked).' new achievement(s)!'
                    : 'No new achievements unlocked.',
            ],
        ]);
    }
}
