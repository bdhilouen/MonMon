<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\EmailVerification;

class CleanupExpiredOTPs extends Command
{
    protected $signature = 'otp:cleanup';
    protected $description = 'Delete expired OTP records';

    public function handle()
    {
        $deleted = EmailVerification::where('expires_at', '<', now())->delete();
        
        $this->info("Deleted {$deleted} expired OTP records.");
    }
}