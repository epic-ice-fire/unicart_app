import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../services/api_error.dart";
import "../../services/auth_service.dart";
import "../../theme/unicart_theme.dart";
import "../../widgets/unicart_ui.dart";

/// Two-step password reset: request a 6-digit code by email, then enter the
/// code with a new password. Pops with the email address on success so the
/// login screen can prefill it.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ""});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const int _resendSeconds = 60;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  bool _showPassword = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _resendSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown = _cooldown - 1);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  bool _looksLikeEmail(String value) {
    final email = value.trim();
    return email.contains("@") && email.contains(".") && email.length >= 5;
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!_looksLikeEmail(email)) {
      showUniCartSnack(context, "Enter the email you signed up with.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.requestPasswordReset(email: email);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _startCooldown();
      showUniCartSnack(
        context,
        "If that email has an account, we've sent a 6-digit code.",
        success: true,
      );
    } catch (e) {
      if (mounted) showUniCartSnack(context, friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmReset() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;

    if (code.length != 6) {
      showUniCartSnack(context, "Enter the 6-digit code from your email.");
      return;
    }
    if (password.isEmpty) {
      showUniCartSnack(context, "Choose a new password.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.confirmPasswordReset(
        email: email,
        code: code,
        newPassword: password,
      );
      if (!mounted) return;
      showUniCartSnack(
        context,
        "Password changed. Sign in with your new password.",
        success: true,
      );
      Navigator.pop(context, email);
    } catch (e) {
      if (mounted) showUniCartSnack(context, friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UniCartBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      UniCartIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: "Back",
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 14),
                      const UniCartLogoMark(size: 44, showWordmark: true),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _codeSent ? "Enter your code" : "Reset your password",
                    style: TextStyle(
                      color: UniCartColors.textPrimary,
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _codeSent
                        ? "We emailed a 6-digit code to ${_emailController.text.trim()}. It expires in 15 minutes."
                        : "Enter the email you signed up with and we'll send you a 6-digit code.",
                    style: TextStyle(
                      color: UniCartColors.textSecondary,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 22),
                  UniCartPanel(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _codeSent ? _confirmFields() : _emailFields(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _emailFields() {
    return [
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.email],
        onSubmitted: (_) => _isLoading ? null : _sendCode(),
        style: TextStyle(color: UniCartColors.textPrimary),
        decoration: const InputDecoration(
          labelText: "Email address",
          hintText: "you@example.com",
          prefixIcon: Icon(Icons.alternate_email_rounded),
        ),
      ),
      const SizedBox(height: 18),
      UniCartPrimaryButton(
        onPressed: _isLoading ? null : _sendCode,
        loading: _isLoading,
        leadingIcon: Icons.mark_email_read_outlined,
        child: const Text("Send code"),
      ),
    ];
  }

  List<Widget> _confirmFields() {
    final canResend = _cooldown <= 0 && !_isLoading;
    return [
      TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 20,
          letterSpacing: 6,
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          labelText: "6-digit code",
          prefixIcon: Icon(Icons.pin_outlined),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _passwordController,
        obscureText: !_showPassword,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.newPassword],
        onSubmitted: (_) => _isLoading ? null : _confirmReset(),
        style: TextStyle(color: UniCartColors.textPrimary),
        decoration: InputDecoration(
          labelText: "New password",
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip: _showPassword ? "Hide password" : "Show password",
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(
              _showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      UniCartPrimaryButton(
        onPressed: _isLoading ? null : _confirmReset,
        loading: _isLoading,
        leadingIcon: Icons.check_rounded,
        child: const Text("Change password"),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: canResend ? _sendCode : null,
        child: Text(
          _cooldown > 0 ? "Resend code in ${_cooldown}s" : "Resend code",
        ),
      ),
    ];
  }
}
