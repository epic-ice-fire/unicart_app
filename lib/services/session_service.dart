import "package:shared_preferences/shared_preferences.dart";

class SessionService {
  static const String _tokenKey = "unicart_token";
  static const String _emailKey = "unicart_email";

  // Legacy versions of UniCart stored the user's plaintext password in
  // SharedPreferences for automatic re-login. Never keep passwords in app
  // storage. This key is removed opportunistically whenever session storage is
  // accessed so existing installations are cleaned automatically.
  static const String _legacyPasswordKey = "unicart_password";

  static Future<void> _purgeLegacySensitiveData(
    SharedPreferences prefs,
  ) async {
    if (prefs.containsKey(_legacyPasswordKey)) {
      await prefs.remove(_legacyPasswordKey);
    }
  }

  // ── Token ──────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await _purgeLegacySensitiveData(prefs);
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    await _purgeLegacySensitiveData(prefs);
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await _purgeLegacySensitiveData(prefs);
    await prefs.remove(_tokenKey);
  }

  // ── Email only ─────────────────────────────────────────────────────────────

  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await _purgeLegacySensitiveData(prefs);
    await prefs.setString(_emailKey, email);
  }

  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await _purgeLegacySensitiveData(prefs);
    return prefs.getString(_emailKey);
  }

  static Future<void> clearEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await _purgeLegacySensitiveData(prefs);
    await prefs.remove(_emailKey);
  }

  // ── Full local sign-out ────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await _purgeLegacySensitiveData(prefs);
    await prefs.remove(_tokenKey);
    // The remembered email is intentionally preserved unless the user disables
    // "Remember email" on the login screen. Passwords are never persisted.
  }
}
