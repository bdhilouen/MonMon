<?php

namespace App\Services;

use App\Models\User;
use App\Models\Achievement;
use App\Models\UserAchievement;
use App\Models\Transaction;
use Illuminate\Support\Facades\DB;

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

    /**
     * Check if achievement condition is met
     */
    private function checkCondition(User $user, Achievement $achievement)
    {
        switch ($achievement->condition_type) {
            case 'streak':
                return $user->streak >= $achievement->condition_value;

            case 'first_saving':
                // First time saving (income > expense)
                $totalIncome = Transaction::where('user_id', $user->id)
                    ->where('type', 'income')
                    ->sum('amount');
                $totalExpense = Transaction::where('user_id', $user->id)
                    ->where('type', 'expense')
                    ->sum('amount');
                
                return ($totalIncome - $totalExpense) >= $achievement->condition_value;

            case 'saving_rate':
                // Achieve certain saving rate in a month
                $currentMonth = now()->format('Y-m');
                
                $monthlyStats = Transaction::raw(function($collection) use ($user, $currentMonth) {
                    return $collection->aggregate([
                        [
                            '$match' => [
                                'user_id' => new \MongoDB\BSON\ObjectId($user->id),
                                '$expr' => [
                                    '$eq' => [
                                        ['$dateToString' => ['format' => '%Y-%m', 'date' => '$date']],
                                        $currentMonth
                                    ]
                                ]
                            ]
                        ],
                        [
                            '$group' => [
                                '_id' => '$type',
                                'total' => ['$sum' => '$amount']
                            ]
                        ]
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

                $savingRate = $income > 0 ? (($income - $expense) / $income) * 100 : 0;
                
                return $savingRate >= $achievement->condition_value;

            case 'expense_ratio':
                // Expense is X times smaller than income
                $monthlyStats = Transaction::raw(function($collection) use ($user) {
                    $currentMonth = now()->format('Y-m');
                    return $collection->aggregate([
                        [
                            '$match' => [
                                'user_id' => new \MongoDB\BSON\ObjectId($user->id),
                                '$expr' => [
                                    '$eq' => [
                                        ['$dateToString' => ['format' => '%Y-%m', 'date' => '$date']],
                                        $currentMonth
                                    ]
                                ]
                            ]
                        ],
                        [
                            '$group' => [
                                '_id' => '$type',
                                'total' => ['$sum' => '$amount']
                            ]
                        ]
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

                if ($income == 0 || $expense == 0) {
                    return false;
                }

                $ratio = $income / $expense;
                return $ratio >= $achievement->condition_value;

            case 'transaction_count':
                $count = Transaction::where('user_id', $user->id)->count();
                return $count >= $achievement->condition_value;

            default:
                return false;
        }
    }
}