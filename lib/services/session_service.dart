import "package:flutter/foundation.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:shared_preferences/shared_preferences.dart";

class SessionService {
  static const String _tokenKey = "unicart_token";
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  /// The sign-in token lives in the Android Keystore / iOS Keychain on phones.
  /// On the web there is no secure store, so it stays in browser storage.
  /// Any secure-storage failure falls back to SharedPreferences so a keystore
  /// problem can never stop someone from signing in.
  static bool get _useSecure => !kIsWeb;
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
    if (_useSecure) {
      try {
        await _secure.write(key: _tokenKey, value: token);
        await prefs.remove(_tokenKey);
        return;
      } catch (_) {
        // Fall through to SharedPreferences.
      }
    }
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    await _purgeLegacySensitiveData(prefs);
    if (!_useSecure) return prefs.getString(_tokenKey);

    try {
      final secureToken = await _secure.read(key: _tokenKey);
      if (secureToken != null && secureToken.isNotEmpty) return secureToken;
    } catch (_) {
      // Fall through to the SharedPreferences copy.
    }

    final legacyToken = prefs.getString(_tokenKey);
    if (legacyToken == null || legacyToken.isEmpty) return null;

    // Move an older plain-storage token into secure storage.
    try {
      await _secure.write(key: _tokenKey, value: legacyToken);
      await prefs.remove(_tokenKey);
    } catch (_) {
      // Keep the SharedPreferences copy if the move failed.
    }
    return legacyToken;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await _purgeLegacySensitiveData(prefs);
    if (_useSecure) {
      try {
        await _secure.delete(key: _tokenKey);
      } catch (_) {
        // Ignore; the SharedPreferences copy is removed below regardless.
      }
    }
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
    await clearToken();
  }
}
