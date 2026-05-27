<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Mail\ResetPasswordMail;
use App\Models\PasswordResetToken;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class ForgotPasswordController extends Controller
{
    /**
     * Step 1: Request OTP untuk reset password
     * POST /api/forgot-password
     */
    public function forgotPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        // ✅ Selalu return success walau email tidak ditemukan
        // Ini untuk mencegah user enumeration attack
        if (!$user) {
            return response()->json([
                'success' => true,
                'message' => 'Jika email terdaftar, OTP akan dikirim ke email kamu.',
            ]);
        }

        // ✅ Cek email sudah verified atau belum
        if (!$user->hasVerifiedEmail()) {
            return response()->json([
                'success' => false,
                'message' => 'Email belum diverifikasi. Silakan verifikasi email terlebih dahulu.',
                'error_code' => 'EMAIL_NOT_VERIFIED',
            ], 403);
        }

        // Generate OTP dan simpan ke database
        $resetToken = PasswordResetToken::createForEmail($user->email);

        // Kirim email
        try {
            Mail::to($user->email)->send(
                new ResetPasswordMail($resetToken->otp, $user->name)
            );
        } catch (\Exception $e) {
            \Log::error('Failed to send reset password email: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengirim email. Coba lagi beberapa saat.',
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'OTP berhasil dikirim ke email kamu.',
            'data' => [
                'email' => $user->email,
                'otp_expires_in' => '10 minutes',
            ],
        ]);
    }

    /**
     * Step 2: Verifikasi OTP
     * POST /api/verify-reset-otp
     */
    public function verifyResetOTP(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
        ]);

        $record = PasswordResetToken::verifyOTP($request->email, $request->otp);

        if (!$record) {
            return response()->json([
                'success' => false,
                'message' => 'OTP tidak valid atau sudah kadaluarsa.',
            ], 400);
        }

        return response()->json([
            'success' => true,
            'message' => 'OTP valid. Silakan reset password kamu.',
            'data' => [
                'email' => $request->email,
                'reset_token' => $record->token, // ✅ Kirim token untuk step selanjutnya
                'token_expires_in' => '15 minutes',
            ],
        ]);
    }

    /**
     * Step 3: Reset password dengan token
     * POST /api/reset-password
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'reset_token' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        // Verify reset token
        $record = PasswordResetToken::verifyToken($request->email, $request->reset_token);

        if (!$record) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid atau sudah kadaluarsa. Silakan ulangi proses forgot password.',
            ], 400);
        }

        // Update password user
        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan.',
            ], 404);
        }

        // ✅ Update password
        $user->password = Hash::make($request->password);
        $user->save();

        // ✅ Hapus semua token Sanctum (force logout semua device)
        $user->tokens()->delete();

        // ✅ Hapus reset token dari database
        $record->delete();

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil direset. Silakan login dengan password baru.',
        ]);
    }
}