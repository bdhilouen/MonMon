<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;
use Carbon\Carbon;

class PasswordResetToken extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'password_reset_tokens';

    protected $fillable = [
        'email',
        'otp',
        'token',        // Token untuk reset password (setelah OTP verified)
        'otp_verified', // OTP sudah diverifikasi atau belum
        'expires_at',
    ];

    protected $casts = [
        'otp_verified' => 'boolean',
        'expires_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Buat reset request baru untuk email
     */
    public static function createForEmail(string $email): self
    {
        // Hapus request lama
        self::where('email', $email)->delete();

        return self::create([
            'email' => $email,
            'otp' => str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT),
            'token' => null,
            'otp_verified' => false,
            'expires_at' => now()->addMinutes(10),
        ]);
    }

    /**
     * Verify OTP dan generate reset token
     */
    public static function verifyOTP(string $email, string $otp): ?self
    {
        $record = self::where('email', $email)
            ->where('otp', $otp)
            ->where('otp_verified', false)
            ->first();

        if (!$record) return null;
        if ($record->expires_at->isPast()) {
            $record->delete();
            return null;
        }

        // OTP valid → generate reset token, extend expiry 15 menit
        $record->token = bin2hex(random_bytes(32));
        $record->otp_verified = true;
        $record->expires_at = now()->addMinutes(15);
        $record->save();

        return $record;
    }

    /**
     * Verify reset token
     */
    public static function verifyToken(string $email, string $token): ?self
    {
        $record = self::where('email', $email)
            ->where('token', $token)
            ->where('otp_verified', true)
            ->first();

        if (!$record) return null;
        if ($record->expires_at->isPast()) {
            $record->delete();
            return null;
        }

        return $record;
    }
}