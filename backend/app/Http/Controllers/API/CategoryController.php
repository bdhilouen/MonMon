<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Services\CacheService;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    /**
     * Get all categories (default + user custom)
     * Optimized with caching
     */
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        // Cache key per user
        $categories = CacheService::rememberSmart(CacheService::categoriesKey($userId), 'categories', function () use ($userId) {
            // Get default categories + user's custom categories
            // Single query with OR condition (no N+1)
            return Category::where(function ($query) use ($userId) {
                $query->whereNull('user_id')
                    ->orWhere('user_id', $userId);
            })
                ->orderBy('type')
                ->orderBy('name')
                ->get()
                ->groupBy('type')
                ->toArray(); // Group by income/expense
        });

        return response()->json([
            'success' => true,
            'data' => $categories,
        ]);
    }

    /**
     * Create custom category for user
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:100',
            'icon' => 'required|string|max:50',
            'color' => 'required|string|max:7', // hex color
            'type' => 'required|in:income,expense',
        ]);

        $category = Category::create([
            'user_id' => $request->user()->id,
            'name' => $request->name,
            'icon' => $request->icon,
            'color' => $request->color,
            'type' => $request->type,
        ]);

        CacheService::clearUserCache($request->user()->id);

        return response()->json([
            'success' => true,
            'message' => 'Category created successfully',
            'data' => $category,
        ], 201);
    }

    /**
     * Update custom category
     */
    public function update(Request $request, $id)
    {
        $category = Category::where('_id', $id)
            ->where('user_id', $request->user()->id) // Only user's custom categories
            ->firstOrFail();

        $request->validate([
            'name' => 'sometimes|string|max:100',
            'icon' => 'sometimes|string|max:50',
            'color' => 'sometimes|string|max:7',
            'type' => 'sometimes|in:income,expense',
        ]);

        $category->update($request->all());

        CacheService::clearUserCache($request->user()->id);

        return response()->json([
            'success' => true,
            'message' => 'Category updated successfully',
            'data' => $category,
        ]);
    }

    /**
     * Delete custom category
     */
    public function destroy($id, Request $request)
    {
        $category = Category::where('_id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        // Check if category is used in transactions
        $transactionCount = $category->transactions()->count();

        if ($transactionCount > 0) {
            return response()->json([
                'success' => false,
                'message' => "Cannot delete category. It's used in {$transactionCount} transactions.",
            ], 422);
        }

        $category->delete();

        CacheService::clearUserCache($request->user()->id);

        return response()->json([
            'success' => true,
            'message' => 'Category deleted successfully',
        ]);
    }
}
