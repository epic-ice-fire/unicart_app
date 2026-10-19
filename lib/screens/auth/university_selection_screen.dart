import "package:flutter/material.dart";

import "../../services/auth_service.dart";
import "../../services/session_service.dart";
import "../../theme/unicart_theme.dart";
import "../../widgets/unicart_ui.dart";
import "../lobby/lobby_screen.dart";
import "login_screen.dart";

class UniversitySelectionScreen extends StatefulWidget {
  final String token;

  const UniversitySelectionScreen({super.key, required this.token});

  @override
  State<UniversitySelectionScreen> createState() =>
      _UniversitySelectionScreenState();
}

class _UniversitySelectionScreenState extends State<UniversitySelectionScreen> {
  bool isLoading = false;
  String? loadingCode;

  Future<void> selectCampus(String code) async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      loadingCode = code;
    });

    try {
      await AuthService.selectUniversity(
        token: widget.token,
        universityCode: code,
      );
      await SessionService.saveUniversityCode(code);
      UniversityBranding.setActive(code);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LobbyScreen(token: widget.token)),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        final raw = error.toString();
        showUniCartSnack(
          context,
          raw.contains("Connection") || raw.contains("ClientException")
              ? "Could not connect to UniCart. Please try again."
              : "We couldn't select that campus. Please try again.",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          loadingCode = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UniCartBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final cardWidth = availableWidth >= 960
                  ? (availableWidth - 36) / 3
                  : availableWidth >= 620
                      ? (availableWidth - 18) / 2
                      : availableWidth;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: availableWidth < 480 ? 20 : 32,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: UniCartLogoMark(size: 58, showWordmark: true),
                        ),
                        const SizedBox(height: 38),
                        const UniCartEyebrow(
                          icon: Icons.public_rounded,
                          label: "One platform · three campuses",
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Choose your university.",
                          style: TextStyle(
                            color: UniCartColors.textPrimary,
                            fontSize: 34,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Pick the campus marketplace you want to use. Your batches, payments and order updates will be scoped to that university. You can switch campuses later.",
                          style: TextStyle(
                            color: UniCartColors.textSecondary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          spacing: 18,
                          runSpacing: 18,
                          children: [
                            for (final code in UniversityBranding.supportedCodes)
                              SizedBox(
                                width: cardWidth,
                                child: _CampusCard(
                                  code: code,
                                  loading: isLoading && loadingCode == code,
                                  disabled: isLoading,
                                  onTap: () => selectCampus(code),
                                ),
                              ),
                          ],
                        ),
                        if (isLoading) ...[
                          const SizedBox(height: 24),
                          const Center(
                            child: Text(
                              "Opening your campus marketplace…",
                              style: TextStyle(
                                color: UniCartColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton.icon(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    await SessionService.clearToken();
                                    await SessionService.clearUniversityCode();
                                    if (!context.mounted) return;
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                      (_) => false,
                                    );
                                  },
                            icon: const Icon(Icons.logout_rounded, size: 17),
                            label: const Text("Sign out"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CampusCard extends StatelessWidget {
  final String code;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  const _CampusCard({
    required this.code,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = UniversityBranding.primaryFor(code);

    return UniCartPanel(
      elevated: true,
      padding: const EdgeInsets.all(22),
      borderColor: accent.withValues(alpha: 0.48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: accent.withValues(alpha: 0.42)),
                ),
                child: Text(
                  UniversityBranding.shortNameFor(code),
                  style: TextStyle(
                    color: UniversityBranding.primarySoftFor(code),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.school_rounded, color: accent, size: 25),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            UniversityBranding.nameFor(code),
            style: const TextStyle(
              color: UniCartColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your campus. Your batch. One organised buying experience.",
            style: TextStyle(
              color: UniCartColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          UniCartPrimaryButton(
            accentColor: accent,
            loading: loading,
            onPressed: disabled ? null : onTap,
            leadingIcon: Icons.arrow_forward_rounded,
            child: Text(loading ? "Opening campus" : "Enter campus"),
          ),
        ],
      ),
    );
  }
}
