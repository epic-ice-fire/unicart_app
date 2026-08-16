import "package:flutter/material.dart";

import "screens/auth/login_screen.dart";
import "screens/lobby/lobby_screen.dart";
import "services/auth_service.dart";
import "services/session_service.dart";
import "theme/unicart_theme.dart";
import "widgets/unicart_ui.dart";

void main() {
  runApp(const UniCartApp());
}

class UniCartApp extends StatelessWidget {
  const UniCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "UniCart",
      debugShowCheckedModeBanner: false,
      theme: UniCartTheme.dark,
      home: const AuthGate(),
    );
  }
}

enum _GateStatus { signedOut, signedIn, connectionError }

class _GateResult {
  final _GateStatus status;
  final String? token;

  const _GateResult(this.status, {this.token});
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<_GateResult> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _loadSession();
  }

  Future<_GateResult> _loadSession() async {
    final token = await SessionService.getToken();
    if (token == null || token.isEmpty) {
      return const _GateResult(_GateStatus.signedOut);
    }

    try {
      await AuthService.me(token);
      return _GateResult(_GateStatus.signedIn, token: token);
    } catch (e) {
      final raw = e.toString();
      final invalidSession = raw.contains("401") ||
          raw.contains("Invalid token") ||
          raw.contains("not found");

      if (invalidSession) {
        await SessionService.clearToken();
        return const _GateResult(_GateStatus.signedOut);
      }

      return _GateResult(_GateStatus.connectionError, token: token);
    }
  }

  void _retry() {
    setState(() {
      _sessionFuture = _loadSession();
    });
  }

  Future<void> _signOut() async {
    await SessionService.clearToken();
    if (!mounted) return;
    _retry();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GateResult>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: UniCartBackdrop(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UniCartLogoMark(size: 82),
                    SizedBox(height: 24),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.3),
                    ),
                    SizedBox(height: 14),
                    Text(
                      "Connecting to UniCart",
                      style: TextStyle(
                        color: UniCartColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final result = snapshot.data;
        if (result == null || result.status == _GateStatus.signedOut) {
          return const LoginScreen();
        }

        if (result.status == _GateStatus.signedIn && result.token != null) {
          return LobbyScreen(token: result.token!);
        }

        return Scaffold(
          body: UniCartBackdrop(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const UniCartLogoMark(size: 72, showWordmark: true),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: UniCartColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: UniCartColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 34,
                              color: UniCartColors.warning,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Couldn't reach UniCart",
                              style: TextStyle(
                                color: UniCartColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Your session is still saved. The server or your connection did not respond, so UniCart will not show an empty or unverified account by mistake.",
                              style: TextStyle(
                                color: UniCartColors.textSecondary,
                                fontSize: 13,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 20),
                            UniCartPrimaryButton(
                              onPressed: _retry,
                              child: const Text("Try again"),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _signOut,
                              child: const Text("Sign out on this device"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
