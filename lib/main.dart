import "dart:async";

import "package:flutter/material.dart";

import "screens/auth/login_screen.dart";
import "screens/lobby/lobby_screen.dart";
import "services/api_service.dart";
import "services/session_service.dart";
import "theme/unicart_theme.dart";
import "widgets/unicart_ui.dart";

void main() {
  // Do not make the first frame wait for the API. Start waking the backend in
  // parallel while the login/auth-gate UI renders immediately.
  unawaited(ApiService.warmUp());
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String?> loadToken() async {
    return SessionService.getToken();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: loadToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: UniCartBackdrop(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UniCartLogoMark(size: 68),
                    SizedBox(height: 24),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    SizedBox(height: 14),
                    Text(
                      "Loading your UniCart",
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

        final token = snapshot.data;
        if (token == null || token.isEmpty) {
          return const LoginScreen();
        }

        return LobbyScreen(token: token);
      },
    );
  }
}