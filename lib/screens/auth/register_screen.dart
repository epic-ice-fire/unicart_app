import "package:flutter/material.dart";
import "../../services/auth_service.dart";
import "../../services/session_service.dart";
import "../../theme/unicart_theme.dart";
import "../../widgets/unicart_ui.dart";
import "../lobby/lobby_screen.dart";

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_refreshStrength);
  }

  void _refreshStrength() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    passwordController.removeListener(_refreshStrength);
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showUniCartSnack(context, "Fill in all fields.");
      return;
    }

    if (password != confirmPassword) {
      showUniCartSnack(context, "Passwords do not match.");
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.register(email: email, password: password);

      final token = await AuthService.login(
        email: email,
        password: password,
      );

      await SessionService.saveToken(token);
      await SessionService.saveEmail(email);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LobbyScreen(token: token)),
        (_) => false,
      );
    } catch (e) {
      final raw = e.toString();
      String message;

      if (raw.contains("already") || raw.contains("409")) {
        message = "An account with that email already exists.";
      } else if (raw.contains("422")) {
        message = "Check your email and password, then try again.";
      } else if (raw.contains("Failed to fetch") ||
          raw.contains("ClientException") ||
          raw.contains("Connection")) {
        message = "Could not connect to UniCart. Try again in a moment.";
      } else {
        message = "Account creation failed. Please try again.";
      }

      if (mounted) showUniCartSnack(context, message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  int get _passwordStrength {
    final value = passwordController.text;
    if (value.isEmpty) return 0;

    var score = 1;
    if (value.length >= 8) score++;
    if (RegExp(r"[A-Z]").hasMatch(value) && RegExp(r"[a-z]").hasMatch(value)) {
      score++;
    }
    if (RegExp(r"[0-9]").hasMatch(value) ||
        RegExp(r"[^A-Za-z0-9]").hasMatch(value)) {
      score++;
    }

    return score.clamp(1, 4).toInt();
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
                    tooltip: "Back to sign in",
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Create account",
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
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: UniCartEyebrow(
                            icon: Icons.person_add_alt_1_rounded,
                            label: "Start your UniCart account",
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Join UniCart.",
                          style: TextStyle(
                            color: UniCartColors.textPrimary,
                            fontSize: 34,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Create an account with any email. Inside the app, you will verify your @pau.edu.ng address before joining a lobby.",
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
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                style: const TextStyle(
                                  color: UniCartColors.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  labelText: "Email address",
                                  hintText: "you@example.com",
                                  prefixIcon: Icon(Icons.alternate_email_rounded),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: passwordController,
                                obscureText: !showPassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.newPassword],
                                style: const TextStyle(
                                  color: UniCartColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  hintText: "Choose a password",
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    tooltip: showPassword
                                        ? "Hide password"
                                        : "Show password",
                                    onPressed: () => setState(
                                      () => showPassword = !showPassword,
                                    ),
                                    icon: Icon(
                                      showPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              if (passwordController.text.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _PasswordStrength(level: _passwordStrength),
                              ],
                              const SizedBox(height: 14),
                              TextField(
                                controller: confirmPasswordController,
                                obscureText: !showConfirmPassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => isLoading ? null : register(),
                                style: const TextStyle(
                                  color: UniCartColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Confirm password",
                                  prefixIcon:
                                      const Icon(Icons.verified_user_outlined),
                                  suffixIcon: IconButton(
                                    tooltip: showConfirmPassword
                                        ? "Hide password"
                                        : "Show password",
                                    onPressed: () => setState(
                                      () => showConfirmPassword =
                                          !showConfirmPassword,
                                    ),
                                    icon: Icon(
                                      showConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              UniCartPrimaryButton(
                                onPressed: isLoading ? null : register,
                                loading: isLoading,
                                leadingIcon: Icons.person_add_alt_1_rounded,
                                child: Text(
                                  isLoading
                                      ? "Creating account"
                                      : "Create account",
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: UniCartColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text(
                                "Sign in",
                                style: TextStyle(
                                  color: UniCartColors.primarySoft,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
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
}

class _PasswordStrength extends StatelessWidget {
  final int level;

  const _PasswordStrength({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      1 => UniCartColors.danger,
      2 => UniCartColors.warning,
      3 => UniCartColors.primarySoft,
      _ => UniCartColors.success,
    };

    final label = switch (level) {
      1 => "Weak",
      2 => "Fair",
      3 => "Good",
      _ => "Strong",
    };

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: index < level ? color : UniCartColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
