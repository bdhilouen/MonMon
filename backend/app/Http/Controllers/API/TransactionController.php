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

    // Inject AchievementService via constructor.
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
            'category_id' => 'required|exists:mongodb.categories,_id',
            'note' => 'nullable|string',
            'receipt' => 'nullable|image|max:2048',
            'date' => 'required|date',
            'currency' => 'nullable|string|size:3',
        ]);

        $data = $request->only(['type', 'amount', 'category_id', 'note', 'date', 'currency']);
        $data['user_id'] = $request->user()->id;
        $data['currency'] = $data['currency'] ?? 'IDR';
        $data['converted_amount'] = $data['amount'];

        // Get category for denormalization.
        $category = Category::find($request->category_id);
        if ($category) {
            $data['category_snapshot'] = [
                'id' => $category->_id,
                'name' => $category->name,
                'icon' => $category->icon,
                'color' => $category->color,
                'type' => $category->type,
            ];
        }

        // Handle receipt upload
        if ($request->hasFile('receipt')) {
            $file = $request->file('receipt');
            $path = $file->store('receipts', 'public');
            $data['receipt_url'] = Storage::url($path);
        }

        $transaction = Transaction::create($data);

        // Update user balance
        $user = $request->user();
        if ($data['type'] == 'income') {
            $user->balance += $data['amount'];
            $user->points += 5;
        } else {
            $user->balance -= $data['amount'];
            $user->points += 2;
        }
        $user->save();

        // Check achievements using service.
        $newAchievements = $this->achievementService->checkAndUnlockAchievements($user);

        // Clear user cache.
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
            'category_id' => 'sometimes|exists:mongodb.categories,_id',
            'note' => 'nullable|string',
            'date' => 'sometimes|date',
        ]);

        $user = $request->user();
        $oldMonth = CacheService::monthFromDate($transaction->date);

        // Revert old balance
        if ($transaction->type == 'income') {
            $user->balance -= $transaction->amount;
        } else {
            $user->balance += $transaction->amount;
        }

        // Update transaction
        $transaction->update($request->all());

        // Apply new balance
        if ($transaction->type == 'income') {
            $user->balance += $transaction->amount;
        } else {
            $user->balance -= $transaction->amount;
        }
        $user->save();

        // Clear cache
        CacheService::clearUserCache($user->id, [
            $oldMonth,
            CacheService::monthFromDate($transaction->fresh()->date),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Transaction updated successfully',
            'data' => $transaction->fresh(),
        ]);
    }

    public function destroy($id, Request $request)
    {
        $transaction = Transaction::where('_id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $user = $request->user();
        $deletedMonth = CacheService::monthFromDate($transaction->date);

        // Revert balance
        if ($transaction->type == 'income') {
            $user->balance -= $transaction->amount;
        } else {
            $user->balance += $transaction->amount;
        }
        $user->save();

        $transaction->delete();

        // Clear cache
        CacheService::clearUserCache($user->id, [$deletedMonth]);

        return response()->json([
            'success' => true,
            'message' => 'Transaction deleted successfully',
        ]);
    }
}
