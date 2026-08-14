import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "../../services/auth_service.dart";
import "../../theme/unicart_theme.dart";
import "../../widgets/unicart_ui.dart";

class VerifyPauScreen extends StatefulWidget {
  final String token;

  const VerifyPauScreen({super.key, required this.token});

  @override
  State<VerifyPauScreen> createState() => _VerifyPauScreenState();
}

class _VerifyPauScreenState extends State<VerifyPauScreen> {
  final pauEmailController = TextEditingController();
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;
  bool codeSent = false;
  String? devCode;
  int resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    pauEmailController.dispose();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final focus in _codeFocusNodes) {
      focus.dispose();
    }
    super.dispose();
  }

  Future<void> requestCode() async {
    final pauEmail = pauEmailController.text.trim();

    if (pauEmail.isEmpty) {
      showUniCartSnack(context, "Enter your PAU email.");
      return;
    }

    if (!pauEmail.toLowerCase().endsWith("@pau.edu.ng")) {
      showUniCartSnack(context, "Use your @pau.edu.ng student email.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await AuthService.requestPauCode(
        token: widget.token,
        pauEmail: pauEmail,
      );

      if (!mounted) return;
      setState(() {
        devCode = response["dev_code"]?.toString();
        codeSent = true;
      });
      _startResendTimer();
      showUniCartSnack(
        context,
        "Verification code sent to $pauEmail.",
        success: true,
      );

      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _codeFocusNodes.first.requestFocus();
      });
    } catch (e) {
      if (mounted) showUniCartSnack(context, _friendlyError(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> verifyCode() async {
    final code = _codeControllers.map((controller) => controller.text).join();

    if (code.length != 6) {
      showUniCartSnack(context, "Enter the full 6-digit verification code.");
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.verifyPauCode(
        token: widget.token,
        code: code,
      );

      if (!mounted) return;
      showUniCartSnack(context, "PAU email verified successfully.", success: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showUniCartSnack(context, _friendlyError(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _friendlyError(Object error) {
    final raw = error.toString();
    if (raw.toLowerCase().contains("expired")) {
      return "That verification code has expired. Request a new one.";
    }
    if (raw.toLowerCase().contains("invalid") || raw.contains("400")) {
      return "That verification code is not valid. Check it and try again.";
    }
    if (raw.contains("429")) {
      return "Please wait before requesting another verification code.";
    }
    if (raw.contains("503")) {
      return "UniCart could not send the verification email. Please try again shortly.";
    }
    if (raw.contains("Connection") || raw.contains("ClientException")) {
      return "Could not connect to UniCart. Check your connection and try again.";
    }
    return raw.replaceFirst("Exception: ", "");
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (resendSeconds <= 1) {
        timer.cancel();
        setState(() => resendSeconds = 0);
      } else {
        setState(() => resendSeconds--);
      }
    });
  }

  void _editEmail() {
    _resendTimer?.cancel();
    for (final controller in _codeControllers) {
      controller.clear();
    }
    setState(() {
      codeSent = false;
      devCode = null;
      resendSeconds = 0;
    });
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < _codeFocusNodes.length - 1) {
      _codeFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _codeFocusNodes[index - 1].requestFocus();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UniCartBackdrop(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  UniCartIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: "Back",
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "PAU verification",
                    style: TextStyle(
                      color: UniCartColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StepIndicator(codeSent: codeSent),
                        const SizedBox(height: 28),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: codeSent ? _codeStep() : _emailStep(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emailStep() {
    return Column(
      key: const ValueKey("email-step"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UniCartEyebrow(
          icon: Icons.verified_user_outlined,
          label: "Student-only access",
        ),
        const SizedBox(height: 18),
        const Text(
          "Verify your PAU email.",
          style: TextStyle(
            color: UniCartColors.textPrimary,
            fontSize: 32,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "We will send a six-digit code to your @pau.edu.ng inbox. This links your student identity to UniCart.",
          style: TextStyle(
            color: UniCartColors.textSecondary,
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 24),
        UniCartPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: pauEmailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => isLoading ? null : requestCode(),
                style: const TextStyle(color: UniCartColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: "PAU email address",
                  hintText: "you@pau.edu.ng",
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 18),
              UniCartPrimaryButton(
                onPressed: isLoading ? null : requestCode,
                loading: isLoading,
                leadingIcon: Icons.send_rounded,
                child: const Text("Send verification code"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _codeStep() {
    final email = pauEmailController.text.trim();

    return Column(
      key: const ValueKey("code-step"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UniCartEyebrow(
          icon: Icons.mark_email_read_outlined,
          label: "Code sent",
        ),
        const SizedBox(height: 18),
        const Text(
          "Check your inbox.",
          style: TextStyle(
            color: UniCartColors.textPrimary,
            fontSize: 32,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Enter the six-digit code sent to $email. The code expires after 10 minutes.",
          style: const TextStyle(
            color: UniCartColors.textSecondary,
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 24),
        UniCartPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Verification code",
                style: TextStyle(
                  color: UniCartColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(6, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
                      child: TextField(
                        controller: _codeControllers[index],
                        focusNode: _codeFocusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) => _onCodeChanged(index, value),
                        style: const TextStyle(
                          color: UniCartColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          filled: true,
                          fillColor: UniCartColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: UniCartColors.border,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (devCode != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UniCartColors.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: UniCartColors.warning.withValues(alpha: 0.28),
                    ),
                  ),
                  child: SelectableText(
                    "Development code: $devCode",
                    style: const TextStyle(
                      color: UniCartColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              UniCartPrimaryButton(
                onPressed: isLoading ? null : verifyCode,
                loading: isLoading,
                leadingIcon: Icons.verified_rounded,
                child: const Text("Verify student email"),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : _editEmail,
                    child: const Text(
                      "Change email",
                      style: TextStyle(color: UniCartColors.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading || resendSeconds > 0 ? null : requestCode,
                    child: Text(
                      resendSeconds > 0
                          ? "Resend in ${resendSeconds}s"
                          : "Resend code",
                      style: TextStyle(
                        color: resendSeconds > 0
                            ? UniCartColors.textMuted
                            : UniCartColors.primarySoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final bool codeSent;

  const _StepIndicator({required this.codeSent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(
          number: 1,
          label: "Email",
          active: true,
          complete: codeSent,
        ),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            height: 2,
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
            color: codeSent ? UniCartColors.primary : UniCartColors.divider,
          ),
        ),
        _StepDot(
          number: 2,
          label: "Code",
          active: codeSent,
          complete: false,
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final String label;
  final bool active;
  final bool complete;

  const _StepDot({
    required this.number,
    required this.label,
    required this.active,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: active ? UniCartColors.primary : UniCartColors.surfaceRaised,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? UniCartColors.primaryBright : UniCartColors.border,
            ),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: UniCartColors.primaryGlow,
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: complete
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    "$number",
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : UniCartColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: active
                ? UniCartColors.primarySoft
                : UniCartColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
