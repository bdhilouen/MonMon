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

  Future<void> _verifyToken() async {
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();

    if (email.isEmpty) {
      showAppSnack(
        context,
        "Email harus diisi",
        success: false,
      );
      return;
    }

    if (token.isEmpty) {
      showAppSnack(
        context,
        "Token reset harus diisi",
        success: false,
      );
      return;
    }

    setState(() => _isVerifyingToken = true);

    final result = await AuthService.verifyResetToken(
      email: email,
      token: token,
    );

    if (!mounted) return;

    setState(() => _isVerifyingToken = false);

    if (result.success) {
      final resetToken =
      result.data is Map && result.data["reset_token"] != null
          ? result.data["reset_token"].toString()
          : token;

      setState(() {
        _tokenVerified = true;
        _verifiedToken = resetToken;
      });

      showAppSnack(
        context,
        "Token valid. Silakan buat password baru.",
      );
    } else {
      showAppSnack(
        context,
        result.message,
        success: false,
      );
    }
  }

  Future<void> _submitReset() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmation = _confirmPasswordController.text;

    if (!_tokenVerified || _verifiedToken == null) {
      showAppSnack(
        context,
        "Verifikasi token reset terlebih dahulu",
        success: false,
      );
      return;
    }

    if (password.isEmpty || confirmation.isEmpty) {
      showAppSnack(
        context,
        "Password dan konfirmasi wajib diisi",
        success: false,
      );
      return;
    }

    if (password.length < 8) {
      showAppSnack(
        context,
        "Password minimal 8 karakter",
        success: false,
      );
      return;
    }

    if (password != confirmation) {
      showAppSnack(
        context,
        "Konfirmasi password tidak sama",
        success: false,
      );
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
      showAppSnack(
        context,
        "Password berhasil direset. Silakan login.",
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
            (route) => false,
      );
    } else {
      showAppSnack(
        context,
        result.message,
        success: false,
      );
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
      backgroundColor: const Color(0xFFF4F7FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return _buildDesktopLayout();
          }

          return _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1100,
          minHeight: 680,
        ),
        child: Container(
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildBrandPanel(),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(44),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: _buildResetCard(
                        showMobileHeader: false,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _buildResetCard(
          showMobileHeader: true,
        ),
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(44),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.password,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                "MonMon",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const Spacer(),

          const Text(
            "Password baru, hidup baru. Dompet tetap harus diawasi.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            "Verifikasi token reset, lalu buat password baru untuk masuk kembali ke akun MonMon kamu.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 16,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 32),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _FeatureChip(
                icon: Icons.key,
                text: "Verifikasi token",
              ),
              _FeatureChip(
                icon: Icons.lock_reset,
                text: "Reset password",
              ),
              _FeatureChip(
                icon: Icons.login,
                text: "Login ulang",
              ),
            ],
          ),

          const Spacer(),

          Text(
            "Kalau mailer masih mode log, token reset cek di laravel.log. Email pura-pura memang merepotkan.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetCard({
    required bool showMobileHeader,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMobileHeader) ...[
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              const Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],

        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.password,
              size: 46,
              color: Colors.blue.shade700,
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          "Buat Password Baru",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          _tokenVerified
              ? "Token sudah valid. Sekarang masukkan password baru kamu."
              : "Masukkan token reset dari email atau log backend untuk melanjutkan.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 26),

        _InfoBanner(
          tokenVerified: _tokenVerified,
        ),

        const SizedBox(height: 20),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          readOnly: true,
          decoration: _inputDecoration(
            label: "Email",
            icon: Icons.email_outlined,
          ),
        ),

        const SizedBox(height: 14),

        TextField(
          controller: _tokenController,
          enabled: !_tokenVerified,
          onSubmitted: (_) {
            if (!_tokenVerified) {
              _verifyToken();
            }
          },
          decoration: _inputDecoration(
            label: "Token Reset",
            icon: Icons.key,
            fillColor: _tokenVerified
                ? Colors.green.shade50
                : Colors.grey.shade100,
            suffix: _tokenVerified
                ? const Icon(
              Icons.check_circle,
              color: Colors.green,
            )
                : null,
          ),
        ),

        if (!_tokenVerified) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: _isVerifyingToken ? null : _verifyToken,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(
                  color: Colors.blue.shade200,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isVerifyingToken
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text(
                "Verifikasi Token",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],

        if (_tokenVerified) ...[
          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.grey.shade300,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "Password Baru",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _inputDecoration(
              label: "Password Baru",
              icon: Icons.lock_outline,
              helperText: "Minimal 8 karakter",
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            onSubmitted: (_) => _submitReset(),
            decoration: _inputDecoration(
              label: "Konfirmasi Password",
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 18),

        TextButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginPage(),
              ),
                  (route) => false,
            );
          },
          child: const Text("Kembali ke Login"),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
    String? helperText,
    Color? fillColor,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: fillColor ?? Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final bool tokenVerified;

  const _InfoBanner({
    required this.tokenVerified,
  });

  @override
  Widget build(BuildContext context) {
    final color = tokenVerified ? Colors.green : Colors.blue;
    final icon = tokenVerified ? Icons.check_circle_outline : Icons.info_outline;
    final text = tokenVerified
        ? "Token valid. Kamu bisa membuat password baru sekarang."
        : "Token reset telah dikirim. Cek inbox, spam, atau laravel.log kalau mailer masih mode log.";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.shade800,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}