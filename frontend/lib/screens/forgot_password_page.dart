import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/app_state_widgets.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showAppSnack(context, 'Email harus diisi', success: false);
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.forgotPassword(email: email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      showAppSnack(context, 'Token reset dikirim ke email kamu. Cek inbox atau folder spam.');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(initialEmail: email),
        ),
      );
    } else {
      // Handle error_code spesifik dari backend
      final errorCode = result.rawBody?['error_code'];
      if (errorCode == 'EMAIL_NOT_VERIFIED') {
        showAppSnack(
          context,
          'Email belum diverifikasi. Silakan verifikasi email terlebih dahulu.',
          success: false,
        );
      } else {
        showAppSnack(context, result.message, success: false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(Icons.lock_reset, size: 72, color: Colors.blue.shade700),
              const SizedBox(height: 24),
              const Text(
                'Reset password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Token reset akan dikirim ke email akun MonMon kamu.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
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
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kirim Token Reset'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
