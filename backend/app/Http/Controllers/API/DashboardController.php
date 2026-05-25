<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\MonthlyWrapped;
use App\Models\Transaction;
use App\Models\UserAchievement;
use App\Services\CacheService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use MongoDB\BSON\ObjectId;
use MongoDB\BSON\UTCDateTime;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $userId = $user->id;
        $monthKey = $request->query('month', now()->format('Y-m'));

        // ✅ Definisikan di sini, sebelum masuk closure
        if (! preg_match('/^\d{4}-\d{2}$/', $monthKey)) {
            return response()->json([
                'success' => false,
                'message' => 'Month must use YYYY-MM format.',
            ], 422);
        }

        $startOfMonth = Carbon::createFromFormat('Y-m-d H:i:s', "{$monthKey}-01 00:00:00", 'UTC')
            ->startOfMonth();
        $endOfMonth = $startOfMonth->copy()->endOfMonth();
        $userIdFilter = $this->buildUserIdFilter((string) $userId);

        $dashboardData = CacheService::rememberSmart(
            CacheService::dashboardKey($userId, $monthKey),
            'dashboard',
            function () use ($user, $userId, $userIdFilter, $startOfMonth, $endOfMonth, $monthKey) {

                $startUtc = new UTCDateTime($startOfMonth->timestamp * 1000);
                $endUtc = new UTCDateTime($endOfMonth->timestamp * 1000);

                // ✅ Ganti $expr dengan range date
                $monthlyStats = Transaction::raw(function ($collection) use ($userIdFilter, $startUtc, $endUtc) {
                    return $collection->aggregate([
                        [
                            '$match' => [
                                'user_id' => $userIdFilter,
                                'date' => [
                                    '$gte' => $startUtc,
                                    '$lte' => $endUtc,
                                ],
                            ],
                        ],
                        [
                            '$group' => [
                                '_id' => '$type',
                                'total' => ['$sum' => '$amount'],
                                'count' => ['$sum' => 1],
                            ],
                        ],
                    ]);
                });

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

                $recentTransactions = Transaction::where('user_id', $userId)
                    ->orderBy('date', 'desc')
                    ->limit(10)
                    ->get()
                    ->toArray();

                $achievementsCount = UserAchievement::where('user_id', $userId)->count();

                return [
                    'user' => [
                        'name' => $user->name,
                        'balance' => $user->balance,
                        'points' => $user->points,
                        'level' => $user->level,
                        'streak' => $user->streak,
                    ],
                    'month' => $monthKey,
                    'monthly_stats' => $stats,
                    'recent_transactions' => $recentTransactions,
                    'achievements_unlocked' => $achievementsCount,
                ];
            }
        );

        return response()->json([
            'success' => true,
            'data' => $dashboardData,
        ]);
    }

    public function chartData(Request $request)
    {
        $request->validate([
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'group_by' => 'sometimes|in:day,week,month',
        ]);

        $userId = $request->user()->id;
        $startDate = Carbon::parse($request->start_date, 'UTC')->startOfDay();
        $endDate = Carbon::parse($request->end_date, 'UTC')->endOfDay();
        $groupBy = $request->group_by ?? 'day';

        $dateFormat = [
            'day' => '%Y-%m-%d',
            'week' => '%Y-W%U',
            'month' => '%Y-%m',
        ][$groupBy];

        // ✅ Support both ObjectId and plain string
        $userIdFilter = $this->buildUserIdFilter((string) $userId);
        $startUtc = new UTCDateTime($startDate->timestamp * 1000);
        $endUtc = new UTCDateTime($endDate->timestamp * 1000);

        // ✅ Timeline aggregation
        $chartData = Transaction::raw(function ($collection) use ($userIdFilter, $startUtc, $endUtc, $dateFormat) {
            return $collection->aggregate([
                [
                    '$match' => [
                        'user_id' => $userIdFilter,
                        'date' => [
                            '$gte' => $startUtc,
                            '$lte' => $endUtc,
                        ],
                    ],
                ],
                [
                    '$group' => [
                        '_id' => [
                            'date' => ['$dateToString' => ['format' => $dateFormat, 'date' => '$date']],
                            'type' => '$type',
                        ],
                        'total' => ['$sum' => '$amount'],
                    ],
                ],
                [
                    '$sort' => ['_id.date' => 1],
                ],
            ]);
        });

        // Transform to frontend-friendly format
        $formattedData = [];
        foreach ($chartData as $item) {
            $date = $item['_id']['date'];
            $type = $item['_id']['type'];

            if (! isset($formattedData[$date])) {
                $formattedData[$date] = [
                    'date' => $date,
                    'income' => 0,
                    'expense' => 0,
                ];
            }

            $formattedData[$date][$type] = $item['total'];
        }

        // ✅ Category breakdown pakai category_snapshot (no extra query)
        // Category breakdown
        $categoryBreakdown = Transaction::raw(function ($collection) use ($userIdFilter, $startUtc, $endUtc) {
            return $collection->aggregate([
                [
                    '$match' => [
                        'user_id' => $userIdFilter,
                        'type' => 'expense',
                        'date' => [
                            '$gte' => $startUtc,
                            '$lte' => $endUtc,
                        ],
                    ],
                ],
                [
                    '$group' => [
                        '_id' => '$category_id',
                        'total' => ['$sum' => '$amount'],
                        'count' => ['$sum' => 1],
                        'snapshot' => ['$first' => '$category_snapshot'],
                    ],
                ],
                [
                    '$sort' => ['total' => -1],
                ],
                [
                    '$limit' => 10,
                ],
            ]);
        });

        // ✅ Collect category IDs yang snapshotnya null untuk batch query
        $categoryBreakdownArr = iterator_to_array($categoryBreakdown);
        $missingSnapshotIds = array_filter(
            array_map(fn ($item) => data_get($item, 'snapshot.name') ? null : (string) $item['_id'], $categoryBreakdownArr)
        );

        // ✅ Batch query categories yang missing (hindari N+1)
        $categoriesFromDb = $this->loadCategoriesByIds($missingSnapshotIds);

        $enrichedCategoryData = array_map(function ($item) use ($categoriesFromDb) {
            $snapshot = $item['snapshot'] ?? null;
            $categoryId = (string) $item['_id'];

            // ✅ Fallback ke DB kalau snapshot null
            if (! data_get($snapshot, 'name') && isset($categoriesFromDb[$categoryId])) {
                $snapshot = $categoriesFromDb[$categoryId];
            }

            return [
                'category_id' => $categoryId,
                'category_name' => data_get($snapshot, 'name', 'Unknown'),
                'category_icon' => data_get($snapshot, 'icon', '📦'),
                'category_color' => data_get($snapshot, 'color', '#999999'),
                'total' => $item['total'],
                'count' => $item['count'],
            ];
        }, $categoryBreakdownArr);

        return response()->json([
            'success' => true,
            'data' => [
                'timeline' => array_values($formattedData),
                'category_breakdown' => $enrichedCategoryData,
            ],
        ]);
    }

    public function monthlyWrapped(Request $request, $year, $month)
    {
        $userId = $request->user()->id;
        $monthKey = sprintf('%04d-%02d', $year, $month);
        $cacheType = $monthKey === now()->format('Y-m') ? 'wrapped_current' : 'wrapped_past';

        $wrapped = CacheService::rememberSmart(
            CacheService::wrappedKey($userId, $monthKey),
            $cacheType,
            fn () => $this->generateWrapped($request, $year, $month, $monthKey)
        );

        return response()->json([
            'success' => true,
            'data' => $wrapped,
            'insights' => $this->generateInsights($wrapped),
        ]);
    }

    private function generateWrapped(Request $request, $year, $month, string $monthKey): array
    {
        $userId = $request->user()->id;

        // ✅ Fix timezone: pakai UTC eksplisit
        $startDate = Carbon::create($year, $month, 1, 0, 0, 0, 'UTC')->startOfMonth();
        $endDate = Carbon::create($year, $month, 1, 0, 0, 0, 'UTC')->endOfMonth();

        $startUtc = new UTCDateTime($startDate->timestamp * 1000);
        $endUtc = new UTCDateTime($endDate->timestamp * 1000);
        $userIdFilter = $this->buildUserIdFilter((string) $userId);

        $stats = Transaction::raw(function ($collection) use ($userIdFilter, $startUtc, $endUtc) {
            return $collection->aggregate([
                [
                    '$match' => [
                        'user_id' => $userIdFilter,
                        'date' => [
                            '$gte' => $startUtc,
                            '$lte' => $endUtc,
                        ],
                    ],
                ],
                [
                    '$facet' => [
                        'totals' => [
                            [
                                '$group' => [
                                    '_id' => '$type',
                                    'total' => ['$sum' => '$amount'],
                                ],
                            ],
                        ],
                        'top_category' => [
                            ['$match' => ['type' => 'expense']],
                            [
                                '$group' => [
                                    '_id' => '$category_id',
                                    'total' => ['$sum' => '$amount'],
                                    'snapshot' => ['$first' => '$category_snapshot'],
                                ],
                            ],
                            ['$sort' => ['total' => -1]],
                            ['$limit' => 1],
                        ],
                        'transaction_count' => [
                            ['$count' => 'count'],
                        ],
                    ],
                ],
            ])->toArray()[0];
        });

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

        $topCategorySnapshot = $stats['top_category'][0]['snapshot'] ?? null;
        $topCategoryName = data_get($topCategorySnapshot, 'name');

        if (! $topCategoryName && isset($stats['top_category'][0]['_id'])) {
            $categories = $this->loadCategoriesByIds([(string) $stats['top_category'][0]['_id']]);
            $topCategoryName = data_get($categories, (string) $stats['top_category'][0]['_id'].'.name');
        }
        $transactionCount = $stats['transaction_count'][0]['count'] ?? 0;

        $wrapped = MonthlyWrapped::updateOrCreate(
            [
                'user_id' => $userId,
                'month' => $monthKey,
            ],
            [
                'total_income' => $totalIncome,
                'total_expense' => $totalExpense,
                'saving_rate' => $savingRate,
                'top_category' => $topCategoryName,
                'total_transactions' => $transactionCount,
                'streak' => $request->user()->streak,
                'generated_image_url' => null,
            ]
        );

        return $wrapped->toArray();
    }

    private function generateInsights($wrapped)
    {
        $insights = [];
        $savingRate = data_get($wrapped, 'saving_rate', 0);
        $streak = data_get($wrapped, 'streak', 0);

        if ($savingRate >= 30) {
            $insights[] = 'Luar biasa! Kamu termasuk top saver!';
        } elseif ($savingRate >= 20) {
            $insights[] = 'Great job! Savings rate kamu di atas rata-rata!';
        } elseif ($savingRate >= 10) {
            $insights[] = 'Keep it up! Terus tingkatkan savings rate kamu!';
        } elseif ($savingRate > 0) {
            $insights[] = 'Mulai bagus! Coba target 10% bulan depan!';
        } else {
            $insights[] = 'Waktunya evaluasi pengeluaran bulan ini!';
        }

        if ($streak >= 30) {
            $insights[] = "Konsistensi level dewa! {$streak} hari berturut-turut!";
        } elseif ($streak >= 7) {
            $insights[] = "Streak bagus! {$streak} hari konsisten!";
        }

        return $insights;
    }

    private function loadCategoriesByIds(array $categoryIds): array
    {
        $ids = array_values(array_unique(array_filter(array_map('strval', $categoryIds))));

        if (empty($ids)) {
            return [];
        }

        $queryIds = $ids;

        foreach ($ids as $id) {
            if ($this->isObjectIdString($id)) {
                $queryIds[] = new ObjectId($id);
            }
        }

        return Category::whereIn('_id', $queryIds)
            ->get()
            ->mapWithKeys(fn ($category) => [
                (string) $category->_id => [
                    'name' => $category->name,
                    'icon' => $category->icon,
                    'color' => $category->color,
                    'type' => $category->type,
                ],
            ])
            ->all();
    }

    private function buildUserIdFilter(string $userId): array|string
    {
        if ($this->isObjectIdString($userId)) {
            return ['$in' => [new ObjectId($userId), $userId]];
        }

        return $userId;
    }

    private function isObjectIdString(string $value): bool
    {
        if (! preg_match('/^[a-f0-9]{24}$/i', $value)) {
            return false;
        }

        try {
            new ObjectId($value);

            return true;
        } catch (\Throwable) {
            return false;
        }
    }
}
