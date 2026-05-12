<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class TransactionController extends Controller
{
    public function index(Request $request)
    {
        $transactions = Transaction::where('user_id', $request->user()->id)
            ->with('category')
            ->orderBy('date', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $transactions
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'type' => 'required|in:income,expense',
            'amount' => 'required|numeric|min:0',
            'category_id' => 'required|exists:categories,_id',
            'note' => 'nullable|string',
            'receipt' => 'nullable|image|max:2048',
            'date' => 'required|date',
            'currency' => 'nullable|string|size:3',
        ]);

        $data = $request->only(['type', 'amount', 'category_id', 'note', 'date', 'currency']);
        $data['user_id'] = $request->user()->id;
        $data['currency'] = $data['currency'] ?? 'IDR';
        $data['converted_amount'] = $data['amount']; // Default sama, bisa ditambah logic konversi

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
            $user->points += 5; // Bonus points
        } else {
            $user->balance -= $data['amount'];
            $user->points += 2; // Smaller points for expense
        }
        $user->save();

        // Check achievements after transaction
        $this->checkAchievements($user);

        return response()->json([
            'success' => true,
            'message' => 'Transaction created successfully',
            'data' => $transaction->load('category')
        ], 201);

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

        // Check achievements (inject service)
        $achievementService = app(\App\Services\AchievementService::class);
        $newAchievements = $achievementService->checkAndUnlockAchievements($user);

        return response()->json([
            'success' => true,
            'message' => 'Transaction created successfully',
            'data' => $transaction->load('category'),
            'new_achievements' => $newAchievements, // Include newly unlocked achievements
        ], 201);
    }

    public function show($id, Request $request)
    {
        $transaction = Transaction::where('_id', $id)
            ->where('user_id', $request->user()->id)
            ->with('category')
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'data' => $transaction
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
            'category_id' => 'sometimes|exists:categories,_id',
            'note' => 'nullable|string',
            'date' => 'sometimes|date',
        ]);

        // Revert old balance
        $user = $request->user();
        if ($transaction->type == 'income') {
            $user->balance -= $transaction->amount;
        } else {
            $user->balance += $transaction->amount;
        }

        $transaction->update($request->all());

        // Apply new balance
        if ($transaction->type == 'income') {
            $user->balance += $transaction->amount;
        } else {
            $user->balance -= $transaction->amount;
        }
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Transaction updated successfully',
            'data' => $transaction->fresh()->load('category')
        ]);
    }

    public function destroy($id, Request $request)
    {
        $transaction = Transaction::where('_id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        // Revert balance
        $user = $request->user();
        if ($transaction->type == 'income') {
            $user->balance -= $transaction->amount;
        } else {
            $user->balance += $transaction->amount;
        }
        $user->save();

        $transaction->delete();

        return response()->json([
            'success' => true,
            'message' => 'Transaction deleted successfully'
        ]);
    }
}
