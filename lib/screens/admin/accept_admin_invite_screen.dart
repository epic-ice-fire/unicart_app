import "package:flutter/material.dart";

import "../../services/auth_service.dart";
import "../../theme/unicart_theme.dart";
import "../../widgets/unicart_ui.dart";

class AcceptAdminInviteScreen extends StatefulWidget {
  const AcceptAdminInviteScreen({super.key});

  @override
  State<AcceptAdminInviteScreen> createState() => _AcceptAdminInviteScreenState();
}

class _AcceptAdminInviteScreenState extends State<AcceptAdminInviteScreen> {
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_email.text.trim().isEmpty || _token.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = "Enter the invited email, invitation token, and a new password.");
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await AuthService.acceptSchoolAdminInvite(
        email: _email.text.trim(),
        token: _token.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      showUniCartSnack(context, "School admin account created. Sign in with your new credentials.", success: true);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Accept admin invitation")),
      body: UniCartBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: UniCartPanel(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const UniCartSectionTitle(
                      title: "Set up your admin account",
                      subtitle: "Use the email selected by the UniCart superior admin. Invitations expire after 48 hours.",
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: "Invited email", prefixIcon: Icon(Icons.alternate_email_rounded)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _token,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "One-time invitation token", prefixIcon: Icon(Icons.key_rounded)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: "Create password (12+ characters)",
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                          icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: UniCartColors.danger)),
                    ],
                    const SizedBox(height: 18),
                    UniCartPrimaryButton(
                      loading: _busy,
                      onPressed: _busy ? null : _accept,
                      leadingIcon: Icons.verified_user_outlined,
                      child: const Text("Create school admin account"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
