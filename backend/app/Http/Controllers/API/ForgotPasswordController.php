<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Mail\ResetPasswordMail;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\ValidationException;

class ForgotPasswordController extends Controller
{
    /**
     * Request password reset token via Laravel Password Broker.
     * POST /api/forgot-password
     */
    public function forgotPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user) {
            return response()->json([
                'success' => true,
                'message' => 'Jika email terdaftar, token reset akan dikirim ke email kamu.',
            ]);
        }

        if (! $user->hasVerifiedEmail()) {
            return response()->json([
                'success' => false,
                'message' => 'Email belum diverifikasi. Silakan verifikasi email terlebih dahulu.',
                'error_code' => 'EMAIL_NOT_VERIFIED',
            ], 403);
        }

        try {
            $status = Password::broker()->sendResetLink(
                ['email' => $user->email],
                function ($user, string $token) {
                    Mail::to($user->email)->send(
                        new ResetPasswordMail($token, $user->name)
                    );
                }
            );
        } catch (\Exception $e) {
            \Log::error('Failed to send reset password email: '.$e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengirim email. Coba lagi beberapa saat.',
            ], 500);
        }

        if ($status === Password::RESET_THROTTLED) {
            return response()->json([
                'success' => false,
                'message' => 'Tunggu sebentar sebelum meminta token reset baru.',
            ], 429);
        }

        if ($status !== Password::RESET_LINK_SENT) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat token reset password.',
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Token reset password berhasil dikirim ke email kamu.',
            'data' => [
                'email' => $user->email,
                'token_expires_in' => config('auth.passwords.users.expire').' minutes',
            ],
        ]);
    }

    /**
     * Backward-compatible token verification endpoint.
     * POST /api/verify-reset-otp
     */
    public function verifyResetOTP(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'nullable|string',
            'token' => 'nullable|string',
            'reset_token' => 'nullable|string',
        ]);

        $token = $request->input('token')
            ?? $request->input('reset_token')
            ?? $request->input('otp');

        if (! $token) {
            throw ValidationException::withMessages([
                'token' => ['Token reset wajib diisi.'],
            ]);
        }

        $user = User::where('email', $request->email)->first();
        $valid = $user && Password::broker()->tokenExists($user, $token);

        if (! $valid) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid atau sudah kadaluarsa.',
            ], 400);
        }

        return response()->json([
            'success' => true,
            'message' => 'Token valid. Silakan reset password kamu.',
            'data' => [
                'email' => $request->email,
                'reset_token' => $token,
            ],
        ]);
    }

    /**
     * Reset password with broker token.
     * POST /api/reset-password
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'token' => 'nullable|string',
            'reset_token' => 'nullable|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $token = $request->input('token') ?? $request->input('reset_token');
        if (! $token) {
            throw ValidationException::withMessages([
                'token' => ['Token reset wajib diisi.'],
            ]);
        }

        $status = Password::broker()->reset(
            [
                'email' => $request->email,
                'password' => $request->password,
                'password_confirmation' => $request->password_confirmation,
                'token' => $token,
            ],
            function (User $user, string $password) {
                $user->password = Hash::make($password);
                $user->save();
                $user->tokens()->delete();
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid atau sudah kadaluarsa. Silakan ulangi proses forgot password.',
            ], 400);
        }

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil direset. Silakan login dengan password baru.',
        ]);
    }
}
