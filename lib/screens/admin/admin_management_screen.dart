import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../models/school.dart";
import "../../services/auth_service.dart";
import "../../theme/unicart_theme.dart";
import "../../widgets/unicart_ui.dart";

class AdminManagementScreen extends StatefulWidget {
  final String token;

  const AdminManagementScreen({super.key, required this.token});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final _emailController = TextEditingController();
  String _schoolId = "pau";
  String? _inviteToken;
  String? _inviteEmail;
  String? _inviteSchoolId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains("@")) {
      setState(() => _error = "Enter the admin's email address.");
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _inviteToken = null;
    });
    try {
      final result = await AuthService.createSchoolAdminInvite(
        token: widget.token,
        email: email,
        schoolId: _schoolId,
      );
      if (!mounted) return;
      setState(() {
        _inviteToken = result["invite_token"]?.toString();
        _inviteEmail = result["email"]?.toString();
        _inviteSchoolId = result["school_id"]?.toString();
      });
      _emailController.clear();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyToken() async {
    final token = _inviteToken;
    if (token == null || token.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: token));
    if (mounted) showUniCartSnack(context, "Invitation token copied.", success: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage school admins")),
      body: UniCartBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: UniCartPanel(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const UniCartSectionTitle(
                      title: "Invite a school admin",
                      subtitle: "Each admin gets a separate account limited to one campus.",
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: "Admin email",
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _schoolId,
                      decoration: const InputDecoration(
                        labelText: "Assigned school",
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: UniCartSchool.all.map((school) {
                        return DropdownMenuItem<String>(
                          value: school.id,
                          child: Text(school.name),
                        );
                      }).toList(),
                      onChanged: _busy ? null : (value) {
                        if (value != null) setState(() => _schoolId = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    UniCartPrimaryButton(
                      loading: _busy,
                      onPressed: _busy ? null : _createInvite,
                      leadingIcon: Icons.person_add_alt_1_rounded,
                      child: const Text("Generate invitation"),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: UniCartColors.danger)),
                    ],
                    if (_inviteToken != null) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text("Invitation created", style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text("School: ${UniCartSchool.byId(_inviteSchoolId ?? _schoolId).name}"),
                      Text("Email: ${_inviteEmail ?? ""}"),
                      const SizedBox(height: 10),
                      const Text("This token expires in 48 hours and can be used once. Share it privately; it will not be shown again."),
                      const SizedBox(height: 10),
                      SelectableText(_inviteToken!, style: const TextStyle(fontFamily: "monospace")),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _copyToken,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text("Copy invitation token"),
                      ),
                    ],
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
