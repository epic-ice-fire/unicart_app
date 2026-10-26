import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "../../models/school.dart";
import "../../services/auth_service.dart";
import "../../services/session_service.dart";
import "../../theme/unicart_theme.dart";
import "../../widgets/unicart_ui.dart";
import "../lobby/lobby_screen.dart";
import "forgot_password_screen.dart";
import "register_screen.dart";
import "../admin/accept_admin_invite_screen.dart";

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
  String selectedSchoolId = UniCartColors.activeSchoolId;

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

      // Record the self-reported campus for aggregate Power BI analysis.
      // A survey endpoint failure must never prevent a valid login.
      try {
        await AuthService.recordCampusSelection(
          token: token,
          selectedSchoolId: selectedSchoolId,
        );
      } catch (_) {
        // Keep sign-in resilient if analytics is temporarily unavailable.
      }
      if (rememberMe) {
        await SessionService.saveEmail(email);
      } else {
        await SessionService.clearEmail();
      }

      // Let the browser / OS password manager save and autofill credentials.
      // UniCart itself never stores the raw password.
      TextInput.finishAutofillContext(shouldSave: rememberMe);

      await SessionService.saveCampus(selectedSchoolId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LobbyScreen(token: token, campusContextId: selectedSchoolId)),
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

  Future<void> _openForgotPassword() async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: emailController.text.trim(),
        ),
      ),
    );
    if (!mounted) return;
    if (email != null && email.isNotEmpty) {
      setState(() {
        emailController.text = email;
        passwordController.clear();
      });
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
                            Expanded(child: _LoginStory(schoolId: selectedSchoolId)),
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
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UniCartEyebrow(
          icon: Icons.school_outlined,
          label: "Built for university students",
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
            DropdownButtonFormField<String>(
              initialValue: selectedSchoolId,
              decoration: const InputDecoration(
                labelText: "University",
                helperText: "Choose your campus for this session. You can change it next time.",
                prefixIcon: Icon(Icons.account_balance_rounded),
              ),
              items: UniCartSchool.all.map((school) {
                return DropdownMenuItem<String>(
                  value: school.id,
                  child: Row(
                    children: [
                      UniCartSchoolLogo(school: school, size: 30, radius: 6),
                      const SizedBox(width: 10),
                      Flexible(child: Text(school.name)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => selectedSchoolId = value);
                      UniCartColors.setSchool(value);
                    },
            ),
            const SizedBox(height: 20),
             Text(
              "Sign in",
              style: TextStyle(
                color: UniCartColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
             Text(
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
              style:  TextStyle(color: UniCartColors.textPrimary),
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
              style:  TextStyle(color: UniCartColors.textPrimary),
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
                    side:  BorderSide(color: UniCartColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: isLoading
                        ? null
                        : (value) => setState(() => rememberMe = value ?? true),
                  ),
                ),
                const SizedBox(width: 2),
                 Expanded(
                  child: Text(
                    "Remember sign-in",
                    style: TextStyle(
                      color: UniCartColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                 Text(
                  "Stay signed in on this device",
                  style: TextStyle(
                    color: UniCartColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading ? null : _openForgotPassword,
                child: const Text("Forgot password?"),
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: isLoading
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AcceptAdminInviteScreen()),
                      ),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
              label: const Text("Accept a school admin invitation"),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginStory extends StatelessWidget {
  final String schoolId;

  const _LoginStory({required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UniCartLogoMark(size: 64, showWordmark: true),
          SizedBox(height: 42),
          UniCartEyebrow(
            icon: Icons.shield_outlined,
            color: schoolId == "babcock" ? UniCartColors.cyan : null,
            label: schoolId == "augustine"
                ? "AUGUSTINE UNIVERSITY · BURGUNDY EDITION"
                : schoolId == "babcock"
                    ? "BABCOCK UNIVERSITY · FOREST EDITION"
                    : schoolId == "veritas"
                        ? "VERITAS UNIVERSITY · ROYAL EDITION"
                        : "PAU · ORIGINAL UNICART EDITION",
          ),
          SizedBox(height: 20),
          Text(
            schoolId == "augustine"
                ? "A more curated way\nto shop your campus."
                : schoolId == "babcock"
                    ? "Fresh finds.\nBetter campus buys."
                    : schoolId == "veritas"
                        ? "Seeking the truth.\nShopping smarter."
                        : "Campus shopping,\nwithout the chaos.",
            style: TextStyle(
              color: UniCartColors.textPrimary,
              fontFamily: schoolId == "augustine" ? "Georgia" : null,
              fontSize: schoolId == "augustine" ? 44 : 46,
              height: schoolId == "augustine" ? 1.08 : 1.03,
              fontWeight: schoolId == "augustine" ? FontWeight.w600 : FontWeight.w800,
              letterSpacing: schoolId == "augustine" ? -0.8 : -1.6,
            ),
          ),
          SizedBox(height: 18),
          SizedBox(
            width: 430,
            child: Text(
              schoolId == "augustine"
                  ? "Thoughtful group shopping with a warmer, editorial feel—from joining a lobby to tracking every item."
                  : schoolId == "babcock"
                      ? "Bring your campus together, unlock group-buying deals, and track every item with a fresh, energetic feel."
                      : schoolId == "veritas"
                          ? "Team up with fellow Veritas students, pool your Temu and SHEIN orders, and track every item in one place."
                          : "Join a verified lobby, pay securely, add your items, and follow the batch until it is ready for processing.",
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
            body: "Choose the campus you identify with. Your choice helps us understand our campus communities and can be changed on a future login.",
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
                style:  TextStyle(
                  color: UniCartColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style:  TextStyle(
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
