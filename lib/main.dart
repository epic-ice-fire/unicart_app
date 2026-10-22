import "package:flutter/material.dart";

import "screens/auth/login_screen.dart";
import "screens/lobby/lobby_screen.dart";
import "services/auth_service.dart";
import "services/session_service.dart";
import "theme/unicart_theme.dart";
import "widgets/unicart_ui.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // In release builds Flutter replaces a widget that failed to build with a
  // blank grey box, which looks like "the screen went blank". Show a readable
  // notice instead (and keep the technical detail so it can be reported).
  ErrorWidget.builder = (FlutterErrorDetails details) =>
      _UniCartErrorPanel(details: details);

  runApp(const UniCartApp());
}

class _UniCartErrorPanel extends StatelessWidget {
  final FlutterErrorDetails details;

  const _UniCartErrorPanel({required this.details});

  @override
  Widget build(BuildContext context) {
    // Self-contained on purpose: no theme or app state, so it cannot fail too.
    var technical = details.exceptionAsString().replaceAll("\n", " ");
    if (technical.length > 220) technical = "${technical.substring(0, 220)}…";

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFF111827),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B), size: 28),
                const SizedBox(height: 8),
                const Text(
                  "Something went wrong showing this part of UniCart.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Refresh the page or sign in again. Details: $technical",
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UniCartApp extends StatelessWidget {
  const UniCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "UniCart",
      debugShowCheckedModeBanner: false,
      // Keep MaterialApp and Navigator mounted when the selected campus changes.
      // Rebuilding MaterialApp here used to reset the route stack during login,
      // which could leave the user staring at a blank screen.
      theme: UniCartTheme.dark,
      home: const AuthGate(),
      builder: (context, child) => ValueListenableBuilder<String>(
        valueListenable: UniCartColors.schoolId,
        builder: (context, _, __) => Theme(
          data: UniCartTheme.dark,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
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
      final account = await AuthService.me(token);
      UniCartColors.setSchool(account["school_id"]?.toString());
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
          return  Scaffold(
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
                             Icon(
                              Icons.cloud_off_rounded,
                              size: 34,
                              color: UniCartColors.warning,
                            ),
                            const SizedBox(height: 16),
                             Text(
                              "Couldn't reach UniCart",
                              style: TextStyle(
                                color: UniCartColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                             Text(
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
