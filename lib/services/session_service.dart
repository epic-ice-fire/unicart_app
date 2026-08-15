import "package:shared_preferences/shared_preferences.dart";

class SessionService {
  static const String _tokenKey = "unicart_token";
  static const String _emailKey = "unicart_email";
  static const String _legacyPasswordKey = "unicart_password";

  static Future<void> _purgeLegacySensitiveData(
    SharedPreferences prefs,
  ) async {
    if (prefs.containsKey(_legacyPasswordKey)) {
      await prefs.remove(_legacyPasswordKey);
    }
  }

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

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await _purgeLegacySensitiveData(prefs);
    await prefs.remove(_tokenKey);
  }
}
