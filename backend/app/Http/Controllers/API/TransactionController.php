<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Transaction;
use App\Services\AchievementService;
use App\Services\CacheService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class TransactionController extends Controller
{
    protected $achievementService;

    public function __construct(AchievementService $achievementService)
    {
        $this->achievementService = $achievementService;
    }

    public function index(Request $request)
    {
        $transactions = Transaction::where('user_id', $request->user()->id)
            ->orderBy('date', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $transactions,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'type' => 'required|in:income,expense',
            'amount' => 'required|numeric|min:0',
            'category_id' => 'required|string',
            'note' => 'nullable|string',
            'receipt' => 'nullable|image|max:2048',
            'date' => 'required|date',
            'currency' => 'nullable|string|size:3',
        ]);

        $category = Category::find($request->category_id);

        if (!$category) {
            return response()->json([
                'success' => false,
                'message' => 'Category not found',
            ], 404);
        }

        // Validasi type match
        if ($category->type !== $request->type) {
            return response()->json([
                'success' => false,
                'message' => "Category '{$category->name}' is for {$category->type}, not {$request->type}",
                'data' => [
                    'transaction_type' => $request->type,
                    'category_type' => $category->type,
                    'category_name' => $category->name,
                ],
            ], 422);
        }

        // Validasi ownership custom category
        if ($category->user_id !== null && (string) $category->user_id !== (string) $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Category not found',
            ], 404);
        }

        $data = $request->only(['type', 'amount', 'category_id', 'note', 'date', 'currency']);
        $data['user_id'] = $request->user()->id;
        $data['currency'] = $data['currency'] ?? 'IDR';
        $data['converted_amount'] = $data['amount'];

        // Pakai $category yang sudah di-fetch sebelumnya
        $data['category_snapshot'] = [
            'id' => (string) $category->_id,
            'name' => $category->name,
            'icon' => $category->icon,
            'color' => $category->color,
            'type' => $category->type,
        ];

        if ($request->hasFile('receipt')) {
            $path = $request->file('receipt')->store('receipts', 'public');
            $data['receipt_url'] = Storage::url($path);
        }

        $transaction = Transaction::create($data);

        // Update user balance & points
        $user = $request->user();
        if ($data['type'] === 'income') {
            $user->balance += $data['amount'];
            $user->points += 5;
        } else {
            $user->balance -= $data['amount'];
            $user->points += 2;
        }
        $user->save();

        $newAchievements = $this->achievementService->checkAndUnlockAchievements($user);

        CacheService::clearUserCache($user->id, [
            CacheService::monthFromDate($transaction->date),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Transaction created successfully',
            'data' => $transaction,
            'new_achievements' => $newAchievements,
        ], 201);
    }

    public function show($id, Request $request)
    {
        $transaction = Transaction::where('_id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'data' => $transaction,
        ]);
    }

    public function update(Request $request, $id)
    {
        $transaction = Transaction::where('_id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $request->validate([
            'type' => 'sometimes|in:income,expense',
            'amount' => 'sometimes|numeric|min:0',
            'category_id' => 'sometimes|string',
            'note' => 'nullable|string',
            'date' => 'sometimes|date',
        ]);

        // Validasi category jalan kalau type ATAU category_id berubah
        $typeChanging = $request->has('type') && $request->type !== $transaction->type;
        $categoryChanging = $request->has('category_id') && $request->category_id !== (string) $transaction->category_id;

        if ($typeChanging || $categoryChanging) {
            // Tentukan category yang akan dipakai setelah update
            $categoryId = $request->category_id ?? $transaction->category_id;
            $finalType = $request->type ?? $transaction->type;

            $category = Category::find($categoryId);

            if (!$category) {
                return response()->json([
                    'success' => false,
                    'message' => 'Category not found',
                ], 404);
            }

            // Validasi type match dengan final state
            if ($category->type !== $finalType) {
                return response()->json([
                    'success' => false,
                    'message' => "Category '{$category->name}' is for {$category->type}, not {$finalType}",
                    'data' => [
                        'transaction_type' => $finalType,
                        'category_type' => $category->type,
                        'category_name' => $category->name,
                    ],
                ], 422);
            }

            // Validasi ownership custom category
            if ($category->user_id !== null && (string) $category->user_id !== (string) $request->user()->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Category not found',
                ], 404);
            }

            // Update snapshot kalau category berubah
            if ($categoryChanging) {
                $request->merge([
                    'category_snapshot' => [
                        'id' => (string) $category->_id,
                        'name' => $category->name,
                        'icon' => $category->icon,
                        'color' => $category->color,
                        'type' => $category->type,
                    ],
                ]);
            }
        }

        $user = $request->user();
        $oldMonth = CacheService::monthFromDate($transaction->date);

        // Revert balance lama
        if ($transaction->type === 'income') {
            $user->balance -= $transaction->amount;
        } else {
            $user->balance += $transaction->amount;
        }

        $transaction->update($request->except('receipt'));
        $transaction->refresh();

        // Apply balance baru
        if ($transaction->type === 'income') {
            $user->balance += $transaction->amount;
        } else {
            $user->balance -= $transaction->amount;
        }
        $user->save();

        CacheService::clearUserCache($user->id, [
            $oldMonth,
            CacheService::monthFromDate($transaction->date),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Transaction updated successfully',
            'data' => $transaction,
        ]);
    }

    public function destroy($id, Request $request)
    {
        $transaction = Transaction::where('_id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $user = $request->user();
        $deletedMonth = CacheService::monthFromDate($transaction->date);

        if ($transaction->type === 'income') {
            $user->balance -= $transaction->amount;
        } else {
            $user->balance += $transaction->amount;
        }
        $user->save();

        $transaction->delete();

        CacheService::clearUserCache($user->id, [$deletedMonth]);

        return response()->json([
            'success' => true,
            'message' => 'Transaction deleted successfully',
        ]);
    }
}