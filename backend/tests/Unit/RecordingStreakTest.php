<?php

namespace Tests\Unit;

use App\Services\LevellingService;
use Carbon\Carbon;
use PHPUnit\Framework\TestCase;

class RecordingStreakTest extends TestCase
{
    public function test_it_counts_yesterday_and_today_as_two_day_streak(): void
    {
        $service = new LevellingService();

        $streak = $service->calculateRecordingStreak([
            '2026-06-03',
            '2026-06-04',
            '2026-06-04',
        ], Carbon::parse('2026-06-04'));

        $this->assertSame(2, $streak);
    }

    public function test_it_keeps_yesterdays_streak_active_until_today_is_recorded(): void
    {
        $service = new LevellingService();

        $streak = $service->calculateRecordingStreak([
            '2026-06-02',
            '2026-06-03',
        ], Carbon::parse('2026-06-04'));

        $this->assertSame(2, $streak);
    }

    public function test_it_resets_when_latest_record_is_older_than_yesterday(): void
    {
        $service = new LevellingService();

        $streak = $service->calculateRecordingStreak([
            '2026-06-01',
            '2026-06-02',
        ], Carbon::parse('2026-06-04'));

        $this->assertSame(0, $streak);
    }
}
