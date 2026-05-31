import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  // Register
  static Future<ApiResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await ApiService.post(
      '/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  // Verify OTP
  static Future<ApiResponse> verifyOTP({
    required String email,
    required String otp,
  }) async {
    return await ApiService.post(
      '/verify-otp',
      body: {'email': email, 'otp': otp},
    );
  }

  // Resend OTP
  static Future<ApiResponse> resendOTP({required String email}) async {
    return await ApiService.post('/resend-otp', body: {'email': email});
  }

  // Login
  static Future<({bool success, String message, User? user})> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      '/login',
      body: {'email': email, 'password': password},
    );

    if (response.success && response.data != null) {
      final token = response.data['token'];
      await ApiService.saveToken(token);

      final user = User.fromJson(response.data['user']);
      return (success: true, message: response.message, user: user);
    }

    String message = response.message;
    if (response.rawBody?['error_code'] == 'EMAIL_NOT_VERIFIED') {
      message = 'EMAIL_NOT_VERIFIED';
    }

    return (success: false, message: message, user: null);
  }

  // Forgot Password
  static Future<ApiResponse> forgotPassword({required String email}) async {
    return await ApiService.post('/forgot-password', body: {'email': email});
  }

  // Reset Password — OTP langsung dipakai tanpa verify step terpisah
  static Future<ApiResponse> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await ApiService.post(
      '/reset-password',
      body: {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  // Logout
  static Future<void> logout() async {
    await ApiService.post('/logout');
    await ApiService.clearToken();
  }

  // Get current user
  static Future<User?> getUser() async {
    final response = await ApiService.get('/me');
    if (response.success && response.data != null) {
      return User.fromJson(response.data);
    }
    return null;
  }

  // Check if logged in
  static bool get isLoggedIn => ApiService.isLoggedIn;
}
