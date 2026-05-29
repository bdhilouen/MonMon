<?php

namespace App\Services;

use App\Models\Achievement;
use App\Models\Transaction;
use App\Models\User;
use App\Models\UserAchievement;
use MongoDB\BSON\ObjectId;

class AchievementService
{
    /**
     * Check and unlock achievements for a user
     * Returns array of newly unlocked achievements
     */
    public function checkAndUnlockAchievements(User $user)
    {
        $newlyUnlocked = [];

        // Get all achievements
        $achievements = Achievement::all();

        // Get already unlocked achievement IDs
        $unlockedIds = UserAchievement::where('user_id', $user->id)
            ->pluck('achievement_id')
            ->toArray();

        foreach ($achievements as $achievement) {
            // Skip if already unlocked
            if (in_array($achievement->_id, $unlockedIds)) {
                continue;
            }

            // Check if condition is met
            $isMet = $this->checkCondition($user, $achievement);

            if ($isMet) {
                // Unlock achievement
                $userAchievement = UserAchievement::create([
                    'user_id' => $user->id,
                    'achievement_id' => $achievement->_id,
                    'unlocked_at' => now(),
                ]);

                // Give rewards
                $user->points += 50; // Bonus points for achievement
                $user->save();

                $newlyUnlocked[] = [
                    'id' => $achievement->_id,
                    'title' => $achievement->title,
                    'description' => $achievement->description,
                    'icon' => $achievement->icon,
                ];
            }
        }

        return $newlyUnlocked;
    }

    public function progressFor(User $user, Achievement $achievement): array
    {
        $current = $this->currentValue($user, $achievement->condition_type);
        $target = (float) $achievement->condition_value;
        $percentage = $target > 0 ? min(100, round(($current / $target) * 100, 2)) : 0;

        return [
            'current' => $current,
            'target' => $target,
            'percentage' => $percentage,
        ];
    }

    /**
     * Check if achievement condition is met
     */
    private function checkCondition(User $user, Achievement $achievement)
    {
        return $this->currentValue($user, $achievement->condition_type) >= $achievement->condition_value;
    }

    private function currentValue(User $user, string $conditionType): float
    {
        return match ($conditionType) {
            'streak' => (float) $user->streak,
            'first_saving' => $this->totalSaving($user),
            'saving_rate' => $this->monthlySavingRate($user),
            'expense_ratio' => $this->monthlyExpenseRatio($user),
            'transaction_count' => (float) Transaction::where('user_id', $user->id)->count(),
            default => 0,
        };
    }

    private function totalSaving(User $user): float
    {
        $totalIncome = Transaction::where('user_id', $user->id)
            ->where('type', 'income')
            ->sum('amount');
        $totalExpense = Transaction::where('user_id', $user->id)
            ->where('type', 'expense')
            ->sum('amount');

        return (float) max(0, $totalIncome - $totalExpense);
    }

    private function monthlySavingRate(User $user): float
    {
        [$income, $expense] = $this->currentMonthTotals($user);

        return $income > 0 ? (float) (($income - $expense) / $income) * 100 : 0;
    }

    private function monthlyExpenseRatio(User $user): float
    {
        [$income, $expense] = $this->currentMonthTotals($user);

        if ($income <= 0 || $expense <= 0) {
            return 0;
        }

        return (float) ($income / $expense);
    }

    private function currentMonthTotals(User $user): array
    {
        $currentMonth = now()->format('Y-m');
        $userId = (string) $user->id;
        $userIdFilter = preg_match('/^[a-f0-9]{24}$/i', $userId)
            ? ['$in' => [new ObjectId($userId), $userId]]
            : $userId;

        $monthlyStats = Transaction::raw(function ($collection) use ($userIdFilter, $currentMonth) {
            return $collection->aggregate([
                [
                    '$match' => [
                        'user_id' => $userIdFilter,
                        '$expr' => [
                            '$eq' => [
                                ['$dateToString' => ['format' => '%Y-%m', 'date' => '$date']],
                                $currentMonth,
                            ],
                        ],
                    ],
                ],
                [
                    '$group' => [
                        '_id' => '$type',
                        'total' => ['$sum' => '$amount'],
                    ],
                ],
            ])->toArray();
        });

        $income = 0;
        $expense = 0;
        foreach ($monthlyStats as $stat) {
            if ($stat['_id'] == 'income') {
                $income = $stat['total'];
            } else {
                $expense = $stat['total'];
            }
        }

        return [(float) $income, (float) $expense];
    }
}
