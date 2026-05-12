<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\MonthlyWrapped;
use App\Models\UserAchievement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DashboardController extends Controller
{
    /**
     * Dashboard overview
     * Optimized: Single aggregation query instead of multiple
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $userId = $user->id;

        // Get current month stats using aggregation (efficient)
        $currentMonth = now()->format('Y-m');
        
        $monthlyStats = Transaction::raw(function($collection) use ($userId, $currentMonth) {
            return $collection->aggregate([
                [
                    '$match' => [
                        'user_id' => new \MongoDB\BSON\ObjectId($userId),
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
                        'total' => ['$sum' => '$amount'],
                        'count' => ['$sum' => 1]
                    ]
                ]
            ]);
        });

        // Transform aggregation result
        $stats = [
            'total_income' => 0,
            'total_expense' => 0,
            'income_count' => 0,
            'expense_count' => 0,
        ];

        foreach ($monthlyStats as $stat) {
            if ($stat['_id'] == 'income') {
                $stats['total_income'] = $stat['total'];
                $stats['income_count'] = $stat['count'];
            } else {
                $stats['total_expense'] = $stat['total'];
                $stats['expense_count'] = $stat['count'];
            }
        }

        $stats['net_income'] = $stats['total_income'] - $stats['total_expense'];
        $stats['saving_rate'] = $stats['total_income'] > 0 
            ? round(($stats['net_income'] / $stats['total_income']) * 100, 2)
            : 0;

        // Get recent transactions (limited, with category preloaded - no N+1)
        $recentTransactions = Transaction::where('user_id', $userId)
            ->with('category:_id,name,icon,color') // Only select needed fields
            ->orderBy('date', 'desc')
            ->limit(10)
            ->get();

        // Get achievements count (efficient)
        $achievementsCount = UserAchievement::where('user_id', $userId)->count();

        return response()->json([
            'success' => true,
            'data' => [
                'user' => [
                    'name' => $user->name,
                    'balance' => $user->balance,
                    'points' => $user->points,
                    'level' => $user->level,
                    'streak' => $user->streak,
                ],
                'monthly_stats' => $stats,
                'recent_transactions' => $recentTransactions,
                'achievements_unlocked' => $achievementsCount,
            ]
        ]);
    }

    /**
     * Chart data with date range
     * Optimized with aggregation pipeline
     */
    public function chartData(Request $request)
    {
        $request->validate([
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'group_by' => 'sometimes|in:day,week,month', // Grouping option
        ]);

        $userId = $request->user()->id;
        $startDate = Carbon::parse($request->start_date)->startOfDay();
        $endDate = Carbon::parse($request->end_date)->endOfDay();
        $groupBy = $request->group_by ?? 'day';

        // Date format based on grouping
        $dateFormat = [
            'day' => '%Y-%m-%d',
            'week' => '%Y-W%U',
            'month' => '%Y-%m',
        ][$groupBy];

        // Aggregation pipeline for chart data
        $chartData = Transaction::raw(function($collection) use ($userId, $startDate, $endDate, $dateFormat) {
            return $collection->aggregate([
                [
                    '$match' => [
                        'user_id' => new \MongoDB\BSON\ObjectId($userId),
                        'date' => [
                            '$gte' => new \MongoDB\BSON\UTCDateTime($startDate->timestamp * 1000),
                            '$lte' => new \MongoDB\BSON\UTCDateTime($endDate->timestamp * 1000),
                        ]
                    ]
                ],
                [
                    '$group' => [
                        '_id' => [
                            'date' => ['$dateToString' => ['format' => $dateFormat, 'date' => '$date']],
                            'type' => '$type'
                        ],
                        'total' => ['$sum' => '$amount']
                    ]
                ],
                [
                    '$sort' => ['_id.date' => 1]
                ]
            ]);
        });

        // Transform to frontend-friendly format
        $formattedData = [];
        foreach ($chartData as $item) {
            $date = $item['_id']['date'];
            $type = $item['_id']['type'];
            
            if (!isset($formattedData[$date])) {
                $formattedData[$date] = [
                    'date' => $date,
                    'income' => 0,
                    'expense' => 0,
                ];
            }
            
            $formattedData[$date][$type] = $item['total'];
        }

        // Category breakdown (pie chart data)
        $categoryBreakdown = Transaction::raw(function($collection) use ($userId, $startDate, $endDate) {
            return $collection->aggregate([
                [
                    '$match' => [
                        'user_id' => new \MongoDB\BSON\ObjectId($userId),
                        'type' => 'expense',
                        'date' => [
                            '$gte' => new \MongoDB\BSON\UTCDateTime($startDate->timestamp * 1000),
                            '$lte' => new \MongoDB\BSON\UTCDateTime($endDate->timestamp * 1000),
                        ]
                    ]
                ],
                [
                    '$group' => [
                        '_id' => '$category_id',
                        'total' => ['$sum' => '$amount'],
                        'count' => ['$sum' => 1]
                    ]
                ],
                [
                    '$sort' => ['total' => -1]
                ],
                [
                    '$limit' => 10
                ]
            ]);
        });

        // Enrich with category details (batch load to avoid N+1)
        $categoryIds = array_map(fn($item) => $item['_id'], iterator_to_array($categoryBreakdown));
        $categories = \App\Models\Category::whereIn('_id', $categoryIds)
            ->get()
            ->keyBy('_id');

        $enrichedCategoryData = array_map(function($item) use ($categories) {
            $category = $categories[$item['_id']] ?? null;
            return [
                'category_id' => $item['_id'],
                'category_name' => $category->name ?? 'Unknown',
                'category_icon' => $category->icon ?? '📦',
                'category_color' => $category->color ?? '#999999',
                'total' => $item['total'],
                'count' => $item['count'],
            ];
        }, iterator_to_array($categoryBreakdown));

        return response()->json([
            'success' => true,
            'data' => [
                'timeline' => array_values($formattedData),
                'category_breakdown' => $enrichedCategoryData,
            ]
        ]);
    }

    /**
     * Generate Monthly Wrapped
     * Cached to avoid regeneration
     */
    public function monthlyWrapped(Request $request, $year, $month)
    {
        $userId = $request->user()->id;
        $monthKey = sprintf('%04d-%02d', $year, $month);

        // Check if already generated
        $wrapped = MonthlyWrapped::where('user_id', $userId)
            ->where('month', $monthKey)
            ->first();

        if ($wrapped) {
            return response()->json([
                'success' => true,
                'data' => $wrapped
            ]);
        }

        // Generate new wrapped
        $startDate = Carbon::create($year, $month, 1)->startOfMonth();
        $endDate = $startDate->copy()->endOfMonth();

        // Aggregation for monthly stats
        $stats = Transaction::raw(function($collection) use ($userId, $startDate, $endDate) {
            return $collection->aggregate([
                [
                    '$match' => [
                        'user_id' => new \MongoDB\BSON\ObjectId($userId),
                        'date' => [
                            '$gte' => new \MongoDB\BSON\UTCDateTime($startDate->timestamp * 1000),
                            '$lte' => new \MongoDB\BSON\UTCDateTime($endDate->timestamp * 1000),
                        ]
                    ]
                ],
                [
                    '$facet' => [
                        'totals' => [
                            [
                                '$group' => [
                                    '_id' => '$type',
                                    'total' => ['$sum' => '$amount']
                                ]
                            ]
                        ],
                        'top_category' => [
                            [
                                '$match' => ['type' => 'expense']
                            ],
                            [
                                '$group' => [
                                    '_id' => '$category_id',
                                    'total' => ['$sum' => '$amount']
                                ]
                            ],
                            [
                                '$sort' => ['total' => -1]
                            ],
                            [
                                '$limit' => 1
                            ]
                        ],
                        'transaction_count' => [
                            [
                                '$count' => 'count'
                            ]
                        ]
                    ]
                ]
            ])->toArray()[0];
        });

        // Process results
        $totalIncome = 0;
        $totalExpense = 0;
        
        foreach ($stats['totals'] as $total) {
            if ($total['_id'] == 'income') {
                $totalIncome = $total['total'];
            } else {
                $totalExpense = $total['total'];
            }
        }

        $savingRate = $totalIncome > 0 
            ? round((($totalIncome - $totalExpense) / $totalIncome) * 100, 2)
            : 0;

        $topCategoryId = $stats['top_category'][0]['_id'] ?? null;
        $topCategory = $topCategoryId 
            ? \App\Models\Category::find($topCategoryId)
            : null;

        $transactionCount = $stats['transaction_count'][0]['count'] ?? 0;

        // Get streak for that month (simplified - could be more complex)
        $user = $request->user();
        $streak = $user->streak;

        // Create wrapped record
        $wrapped = MonthlyWrapped::create([
            'user_id' => $userId,
            'month' => $monthKey,
            'total_income' => $totalIncome,
            'total_expense' => $totalExpense,
            'saving_rate' => $savingRate,
            'top_category' => $topCategory ? $topCategory->name : null,
            'total_transactions' => $transactionCount,
            'streak' => $streak,
            'generated_image_url' => null, // Will be generated by frontend
        ]);

        return response()->json([
            'success' => true,
            'data' => $wrapped,
            'insights' => $this->generateInsights($wrapped)
        ]);
    }

    /**
     * Generate insights for wrapped
     */
    private function generateInsights($wrapped)
    {
        $insights = [];

        if ($wrapped->saving_rate >= 30) {
            $insights[] = "🌟 Luar biasa! Kamu termasuk top saver!";
        } elseif ($wrapped->saving_rate >= 20) {
            $insights[] = "💪 Great job! Savings rate kamu di atas rata-rata!";
        } elseif ($wrapped->saving_rate >= 10) {
            $insights[] = "👍 Keep it up! Terus tingkatkan savings rate kamu!";
        } elseif ($wrapped->saving_rate > 0) {
            $insights[] = "📈 Mulai bagus! Coba target 10% bulan depan!";
        } else {
            $insights[] = "⚠️ Waktunya evaluasi pengeluaran bulan ini!";
        }

        if ($wrapped->streak >= 30) {
            $insights[] = "🔥 Konsistensi level dewa! {$wrapped->streak} hari berturut-turut!";
        } elseif ($wrapped->streak >= 7) {
            $insights[] = "✨ Streak bagus! {$wrapped->streak} hari konsisten!";
        }

        return $insights;
    }
}