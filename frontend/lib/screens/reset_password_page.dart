import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/app_state_widgets.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String initialEmail;

  const ResetPasswordPage({
    super.key,
    required this.initialEmail,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final TextEditingController _emailController;
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isVerifyingToken = false;
  bool _tokenVerified = false;
  String? _verifiedToken;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  /// Step 1: Verifikasi token via POST /verify-reset-otp
  Future<void> _verifyToken() async {
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();

    if (email.isEmpty) {
      showAppSnack(context, 'Email harus diisi', success: false);
      return;
    }
    if (token.isEmpty) {
      showAppSnack(context, 'Token reset harus diisi', success: false);
      return;
    }

    setState(() => _isVerifyingToken = true);
    final result = await AuthService.verifyResetToken(email: email, token: token);
    if (!mounted) return;
    setState(() => _isVerifyingToken = false);

    if (result.success) {
      // Backend returns reset_token in data
      final resetToken = result.data?['reset_token'] ?? token;
      setState(() {
        _tokenVerified = true;
        _verifiedToken = resetToken;
      });
      showAppSnack(context, 'Token valid. Silakan buat password baru.');
    } else {
      showAppSnack(context, result.message, success: false);
    }
  }

  /// Step 2: Reset password via POST /reset-password
  Future<void> _submitReset() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;

    if (password.isEmpty || confirmation.isEmpty) {
      showAppSnack(context, 'Password dan konfirmasi wajib diisi', success: false);
      return;
    }
    if (password.length < 8) {
      showAppSnack(context, 'Password minimal 8 karakter', success: false);
      return;
    }
    if (password != confirmation) {
      showAppSnack(context, 'Konfirmasi password tidak sama', success: false);
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.resetPassword(
      email: email,
      token: _verifiedToken!,
      password: password,
      passwordConfirmation: confirmation,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      showAppSnack(context, 'Password berhasil direset. Silakan login.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else {
      showAppSnack(context, result.message, success: false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Token reset telah dikirim ke email kamu. Cek inbox atau folder spam, lalu masukkan token di bawah.',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Email field (read-only karena sudah dari ForgotPasswordPage)
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Step 1: Token input & verify
              TextField(
                controller: _tokenController,
                enabled: !_tokenVerified,
                decoration: InputDecoration(
                  labelText: 'Token Reset (dari email)',
                  prefixIcon: const Icon(Icons.key),
                  filled: true,
                  fillColor: _tokenVerified
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _tokenVerified
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
              ),

              if (!_tokenVerified) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _isVerifyingToken ? null : _verifyToken,
                    child: _isVerifyingToken
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verifikasi Token'),
                  ),
                ),
              ],

              // Step 2: Form password baru (muncul setelah token terverifikasi)
              if (_tokenVerified) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Buat Password Baru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    helperText: 'Minimal 8 karakter',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _submitReset(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submitReset,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Reset Password'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
