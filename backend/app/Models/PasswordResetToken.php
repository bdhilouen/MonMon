<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class PasswordResetToken extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'password_reset_tokens';

    protected $fillable = [
        'email',
        'otp',
        'expires_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Buat OTP baru untuk email
     */
    public static function createForEmail(string $email): self
    {
        // Hapus request lama
        self::where('email', $email)->delete();

        return self::create([
            'email' => $email,
            'otp' => str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT),
            'expires_at' => now()->addMinutes(10),
        ]);
    }

    /**
     * Verify OTP - return record kalau valid, null kalau tidak
     */
    public static function verifyOTP(string $email, string $otp): ?self
    {
        $record = self::where('email', $email)
            ->where('otp', $otp)
            ->first();

        if (!$record) return null;

        if ($record->expires_at->isPast()) {
            $record->delete();
            return null;
        }

        return $record;
    }
}