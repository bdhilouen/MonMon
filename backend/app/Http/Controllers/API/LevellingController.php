<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\LevellingService;
use Illuminate\Http\Request;

class LevellingController extends Controller
{
    protected $levellingService;

    public function __construct(LevellingService $levellingService)
    {
        $this->levellingService = $levellingService;
    }

    /**
     * Get level progress user
     * GET /api/level/progress
     */
    public function progress(Request $request)
    {
        $user = $request->user();
        $progress = $this->levellingService->getLevelProgress($user);

        return response()->json([
            'success' => true,
            'data' => $progress,
        ]);
    }
}