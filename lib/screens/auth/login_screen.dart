import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "../../services/auth_service.dart";
import "../../services/session_service.dart";
import "../../theme/unicart_theme.dart";
import "../../widgets/unicart_ui.dart";
import "../lobby/lobby_screen.dart";
import "register_screen.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool rememberMe = true;
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final savedEmail = await SessionService.getSavedEmail();
    if (!mounted) return;

    setState(() {
      if (savedEmail != null && savedEmail.isNotEmpty) {
        emailController.text = savedEmail;
        rememberMe = true;
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showUniCartSnack(context, "Enter your email and password.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final token = await AuthService.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      await SessionService.saveToken(token);
      if (rememberMe) {
        await SessionService.saveEmail(email);
      } else {
        await SessionService.clearEmail();
      }

      // Let the browser / OS password manager save and autofill credentials.
      // UniCart itself never stores the raw password.
      TextInput.finishAutofillContext(shouldSave: rememberMe);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LobbyScreen(token: token)),
      );
    } catch (e) {
      final raw = e.toString();
      String message;

      if (raw.contains("401") || raw.contains("Invalid email or password")) {
        message = "Incorrect email or password. Please try again.";
      } else if (raw.contains("Failed to fetch") ||
          raw.contains("SocketException") ||
          raw.contains("ClientException") ||
          raw.contains("Connection")) {
        message = "Could not connect to UniCart. Check your connection and try again.";
      } else if (raw.contains("500")) {
        message = "The server is waking up. Try again in a moment.";
      } else {
        message = "Login failed. Please try again.";
      }

      if (mounted) showUniCartSnack(context, message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UniCartBackdrop(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 480 ? 20 : 32,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: wide
                      ? Row(
                          children: [
                            const Expanded(child: _LoginStory()),
                            const SizedBox(width: 56),
                            Expanded(child: _loginCard()),
                          ],
                        )
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: UniCartLogoMark(
                                  size: 58,
                                  showWordmark: true,
                                ),
                              ),
                              const SizedBox(height: 36),
                              _mobileHeader(),
                              const SizedBox(height: 24),
                              _loginCard(),
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _mobileHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UniCartEyebrow(
          icon: Icons.school_outlined,
          label: "Built for PAU students",
        ),
        SizedBox(height: 18),
        Text(
          "Welcome back.",
          style: TextStyle(
            color: UniCartColors.textPrimary,
            fontSize: 34,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 10),
        Text(
          "Sign in to join a lobby, lock in your items, and track the batch from one place.",
          style: TextStyle(
            color: UniCartColors.textSecondary,
            fontSize: 15,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _loginCard() {
    return AutofillGroup(
      child: UniCartPanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Sign in",
              style: TextStyle(
                color: UniCartColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Use the account you created for UniCart.",
              style: TextStyle(
                color: UniCartColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              style: const TextStyle(color: UniCartColors.textPrimary),
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
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => isLoading ? null : login(),
              style: const TextStyle(color: UniCartColors.textPrimary),
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: showPassword ? "Hide password" : "Show password",
                  onPressed: () => setState(() => showPassword = !showPassword),
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Checkbox(
                    value: rememberMe,
                    activeColor: UniCartColors.primary,
                    checkColor: Colors.white,
                    side: const BorderSide(color: UniCartColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: isLoading
                        ? null
                        : (value) => setState(() => rememberMe = value ?? true),
                  ),
                ),
                const SizedBox(width: 2),
                const Expanded(
                  child: Text(
                    "Remember sign-in",
                    style: TextStyle(
                      color: UniCartColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text(
                  "Stay signed in on this device",
                  style: TextStyle(
                    color: UniCartColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            UniCartPrimaryButton(
              onPressed: isLoading ? null : login,
              loading: isLoading,
              leadingIcon: Icons.arrow_forward_rounded,
              child: Text(isLoading ? "Signing in" : "Continue to UniCart"),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "New here?",
                    style: TextStyle(
                      color: UniCartColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 18),
            UniCartPrimaryButton(
              outlined: true,
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
              child: const Text("Create an account"),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginStory extends StatelessWidget {
  const _LoginStory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UniCartLogoMark(size: 64, showWordmark: true),
          SizedBox(height: 42),
          UniCartEyebrow(
            icon: Icons.shield_outlined,
            label: "PAU-verified group buying",
          ),
          SizedBox(height: 20),
          Text(
            "Campus shopping,\nwithout the chaos.",
            style: TextStyle(
              color: UniCartColors.textPrimary,
              fontSize: 46,
              height: 1.03,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.6,
            ),
          ),
          SizedBox(height: 18),
          SizedBox(
            width: 430,
            child: Text(
              "Join a verified lobby, pay securely, add your items, and follow the batch until it is ready for processing.",
              style: TextStyle(
                color: UniCartColors.textSecondary,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
          SizedBox(height: 32),
          _StoryPoint(
            icon: Icons.verified_user_outlined,
            title: "Verified campus access",
            body: "PAU email verification keeps the community student-only.",
          ),
          SizedBox(height: 14),
          _StoryPoint(
            icon: Icons.account_balance_wallet_outlined,
            title: "Clear payment states",
            body: "Know what is pending, paid, locked, or ready at a glance.",
          ),
          SizedBox(height: 14),
          _StoryPoint(
            icon: Icons.inventory_2_outlined,
            title: "One batch, one source of truth",
            body: "Your lobby progress and items stay organized in one dashboard.",
          ),
        ],
      ),
    );
  }
}

class _StoryPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _StoryPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: UniCartColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: UniCartColors.primaryBright.withValues(alpha: 0.22),
            ),
          ),
          child: Icon(icon, color: UniCartColors.primarySoft, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: UniCartColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  color: UniCartColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
