<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;
use Carbon\Carbon;

class EmailVerification extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'email_verifications';

    protected $fillable = [
        'email',
        'otp',
        'expires_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'created_at' => 'datetime',
    ];

    /**
     * Generate random 6-digit OTP
     */
    public static function generateOTP()
    {
        return str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
    }

    /**
     * Create new OTP for email
     */
    public static function createForEmail($email)
    {
        // Delete old OTPs for this email
        self::where('email', $email)->delete();

        // Create new OTP (expires in 10 minutes)
        $otp = self::generateOTP();
        
        return self::create([
            'email' => $email,
            'otp' => $otp,
            'expires_at' => now()->addMinutes(10),
        ]);
    }

    /**
     * Verify OTP
     */
    public static function verify($email, $otp)
    {
        $record = self::where('email', $email)
            ->where('otp', $otp)
            ->first();

        if (!$record) {
            return false;
        }

        // Check if expired
        if ($record->expires_at->isPast()) {
            $record->delete();
            return false;
        }

        // Valid OTP
        $record->delete(); // Delete after successful verification
        return true;
    }

    /**
     * Check if OTP exists and not expired
     */
    public function isValid()
    {
        return $this->expires_at->isFuture();
    }
}