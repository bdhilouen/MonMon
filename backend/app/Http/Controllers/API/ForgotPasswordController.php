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
     * Step 1: Request OTP
     * POST /api/forgot-password
     */
    public function forgotPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        // ✅ Selalu return success untuk cegah user enumeration
        if (!$user) {
            return response()->json([
                'success' => true,
                'message' => 'Jika email terdaftar, OTP akan dikirim ke email kamu.',
            ]);
        }

        if (!$user->hasVerifiedEmail()) {
            return response()->json([
                'success' => false,
                'message' => 'Email belum diverifikasi.',
                'error_code' => 'EMAIL_NOT_VERIFIED',
            ], 403);
        }

        $resetToken = PasswordResetToken::createForEmail($user->email);

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
     * Step 2: Verifikasi OTP + Reset Password sekaligus
     * POST /api/reset-password
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
            'password' => 'required|string|min:8|confirmed',
        ]);

        // ✅ Verify OTP
        $record = PasswordResetToken::verifyOTP($request->email, $request->otp);

        if (!$record) {
            return response()->json([
                'success' => false,
                'message' => 'OTP tidak valid atau sudah kadaluarsa.',
            ], 400);
        }

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

        // ✅ Force logout semua device
        $user->tokens()->delete();

        // ✅ Hapus OTP setelah berhasil
        $record->delete();

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil direset. Silakan login dengan password baru.',
        ]);
    }
}