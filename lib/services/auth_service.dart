import "api_service.dart";

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String phoneNumber,
    String schoolId = "pau",
  }) async {
    await ApiService.ensureBackendReady();
    return await ApiService.post(
      "/auth/register",
      body: {
        "email": email,
        "password": password,
        "school_id": schoolId,
        "phone_number": phoneNumber,
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

  static Future<Map<String, dynamic>> bootstrapSuperAdmin({
    required String token,
    required String bootstrapSecret,
  }) async {
    return ApiService.post(
      "/auth/admin/bootstrap",
      token: token,
      body: {"bootstrap_secret": bootstrapSecret},
    );
  }

  static Future<Map<String, dynamic>> createSchoolAdminInvite({
    required String token,
    required String email,
    required String schoolId,
  }) async {
    return ApiService.post(
      "/auth/admin/invites",
      token: token,
      body: {"email": email, "school_id": schoolId},
    );
  }

  static Future<void> recordCampusSelection({
    required String token,
    required String selectedSchoolId,
  }) async {
    await ApiService.post(
      "/auth/campus-selection",
      token: token,
      body: {"selected_school_id": selectedSchoolId},
    );
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

  /// Always succeeds from the shopper's point of view: the server never says
  /// whether the email has an account.
  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    await ApiService.ensureBackendReady();
    return await ApiService.post(
      "/auth/password-reset/request",
      body: {"email": email},
    );
  }

  static Future<Map<String, dynamic>> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await ApiService.ensureBackendReady();
    return await ApiService.post(
      "/auth/password-reset/confirm",
      body: {
        "email": email,
        "code": code,
        "new_password": newPassword,
      },
    );
  }

  /// Permanently removes the signed-in account's personal details.
  static Future<Map<String, dynamic>> deleteAccount({
    required String token,
    required String password,
  }) async {
    return await ApiService.post(
      "/auth/account/delete",
      token: token,
      body: {"password": password},
    );
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
