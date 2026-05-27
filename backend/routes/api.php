<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\TransactionController;
use App\Http\Controllers\API\CategoryController;
use App\Http\Controllers\API\AchievementController;
use App\Http\Controllers\API\DashboardController;
use App\Http\Controllers\API\ExportController;
use App\Http\Controllers\API\ForgotPasswordController;

// Public routes
Route::post('/register',        [AuthController::class, 'register']);
Route::post('/verify-otp',      [AuthController::class, 'verifyOTP']);
Route::post('/resend-otp',      [AuthController::class, 'resendOTP']);
Route::post('/login',           [AuthController::class, 'login']);
Route::post('/forgot-password', [ForgotPasswordController::class, 'forgotPassword']);
Route::post('/verify-reset-otp',[ForgotPasswordController::class, 'verifyResetOTP']);
Route::post('/reset-password',  [ForgotPasswordController::class, 'resetPassword']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/logout',[AuthController::class, 'logout']);
    Route::get('/me',     [AuthController::class, 'me']);
    
    // Transactions
    Route::apiResource('transactions', TransactionController::class);
    
    // Categories
    Route::get('/categories',        [CategoryController::class, 'index']);
    Route::post('/categories',       [CategoryController::class, 'store']);
    Route::put('/categories/{id}',   [CategoryController::class, 'update']);
    Route::delete('/categories/{id}',[CategoryController::class, 'destroy']);
    
    // Dashboard
    Route::get('/dashboard',      [DashboardController::class, 'index']);
    Route::get('/dashboard/chart',[DashboardController::class, 'chartData']);

    // Export
    Route::get('/export/csv',[ExportController::class, 'exportCSV']);
    Route::get('/export/pdf',[ExportController::class, 'exportPDF']);
    
    // Achievements
    Route::get('/achievements',       [AchievementController::class, 'index']);
    Route::get('/achievements/my',    [AchievementController::class, 'myAchievements']);
    Route::post('/achievements/check',[AchievementController::class, 'checkAchievements']);
    
    // Monthly Wrapped
    Route::get('/wrapped/{year}/{month}',[DashboardController::class, 'monthlyWrapped']);
});