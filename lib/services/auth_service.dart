import "api_service.dart";

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    await ApiService.ensureBackendReady();
    return await ApiService.post(
      "/auth/register",
      body: {
        "email": email,
        "password": password,
      },
    );
  }

  static Future<String> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    await ApiService.ensureBackendReady();
    final response = await ApiService.post(
      "/auth/login",
      formEncoded: true,
      body: {
        "username": email,
        "password": password,
        "remember_me": rememberMe ? "true" : "false",
      },
    );

    return response["access_token"] as String;
  }

  static Future<void> logout(String token) async {
    await ApiService.post(
      "/auth/logout",
      token: token,
    );
  }

  static Future<void> logoutAll(String token) async {
    await ApiService.post(
      "/auth/logout-all",
      token: token,
    );
  }

  static Future<String> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await ApiService.post(
      "/auth/change-password",
      token: token,
      body: {
        "current_password": currentPassword,
        "new_password": newPassword,
      },
    );
    return response["access_token"] as String;
  }

  static Future<Map<String, dynamic>> me(String token) async {
    await ApiService.ensureBackendReady();
    return await ApiService.get("/auth/me", token: token);
  }

  static Future<Map<String, dynamic>> requestPauCode({
    required String token,
    required String pauEmail,
  }) async {
    return await ApiService.post(
      "/auth/pau/request",
      token: token,
      body: {
        "pau_email": pauEmail,
      },
    );
  }

  static Future<Map<String, dynamic>> verifyPauCode({
    required String token,
    required String code,
  }) async {
    return await ApiService.post(
      "/auth/pau/verify",
      token: token,
      body: {
        "code": code,
      },
    );
  }
}
