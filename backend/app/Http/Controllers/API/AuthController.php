<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use App\Notifications\OTPVerification;
use App\Models\EmailVerification;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'balance' => 0,
            'points' => 0,
            'level' => 1,
            'streak' => 0,
            'last_active_date' => now(),
            'email_verified_at' => null,
        ]);

        // Generate and store OTP
        $verification = EmailVerification::createForEmail($user->email);

        // Send OTP via email
        try {
            $user->notify(new OTPVerification($verification->otp));
        } catch (\Exception $e) {
            // If email fails, still return success but log error
            \Log::error('Failed to send OTP email: ' . $e->getMessage());
        }

        return response()->json([
            'success' => true,
            'message' => 'Registration successful. Please check your email for OTP verification.',
            'data' => [
                'email' => $user->email,
                'otp_expires_in' => '10 minutes',
            ]
        ], 201);
    }

    /**
     * Verify OTP
     */
    public function verifyOTP(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
        ]);

        // Find user
        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found'
            ], 404);
        }

        // Check if already verified
        if ($user->hasVerifiedEmail()) {
            return response()->json([
                'success' => false,
                'message' => 'Email already verified'
            ], 400);
        }

        // Verify OTP
        $isValid = EmailVerification::verify($request->email, $request->otp);

        if (!$isValid) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired OTP'
            ], 400);
        }

        // Mark email as verified
        $user->markEmailAsVerified();

        return response()->json([
            'success' => true,
            'message' => 'Email verified successfully! You can now login.',
            'data' => [
                'email' => $user->email,
                'verified_at' => $user->email_verified_at,
            ]
        ], 200);
    }

    /**
     * Resend OTP
     */
    public function resendOTP(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found'
            ], 404);
        }

        if ($user->hasVerifiedEmail()) {
            return response()->json([
                'success' => false,
                'message' => 'Email already verified'
            ], 400);
        }

        // Generate new OTP
        $verification = EmailVerification::createForEmail($user->email);

        // Send OTP via email
        try {
            $user->notify(new OTPVerification($verification->otp));
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to send OTP email'
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'OTP has been resent to your email',
            'data' => [
                'email' => $user->email,
                'otp_expires_in' => '10 minutes',
            ]
        ], 200);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        // Check if email is verified
        if (!$user->hasVerifiedEmail()) {
            return response()->json([
                'success' => false,
                'message' => 'Please verify your email first. Check your inbox for OTP.',
                'error_code' => 'EMAIL_NOT_VERIFIED'
            ], 403);
        }

        // Update streak logic
        $this->updateStreak($user);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'user' => $user->fresh(),
                'token' => $token,
            ]
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully'
        ]);
    }

    public function me(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => $request->user()
        ]);
    }

    private function updateStreak(User $user)
    {
        $lastActive = $user->last_active_date;
        $now = now();

        if ($lastActive) {
            $daysDiff = $lastActive->diffInDays($now);

            if ($daysDiff == 1) {
                // Consecutive day
                $user->streak += 1;
                $user->points += 10; // Bonus points untuk streak
            } elseif ($daysDiff > 1) {
                // Streak broken
                $user->streak = 1;
            }
            // Same day = no change
        } else {
            $user->streak = 1;
        }

        $user->last_active_date = $now;
        $user->save();
    }
}
