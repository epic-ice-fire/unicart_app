import "dart:async";
import "dart:convert";

import "package:http/http.dart" as http;

import "../config/api.dart";

class ApiService {
  ApiService._();

  // Keep one client for the life of the app so requests can reuse the browser's
  // existing network connection instead of creating a new top-level client for
  // every call.
  static final http.Client _client = http.Client();

  // Fire this as soon as UniCart starts. It does not block the UI. Its job is
  // to start waking the API before the user presses Login when the host has
  // idled the backend.
  static Future<void> warmUp() async {
    try {
      await _client
          .get(
            Uri.parse(ApiConfig.baseUrl),
            headers: const {"Accept": "application/json"},
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      // Warm-up is best-effort only. Real requests still surface their own
      // errors normally.
    }
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
  }) async {
    final response = await _client.get(
      Uri.parse("${ApiConfig.baseUrl}$endpoint"),
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    return _handleResponse("GET", endpoint, response);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
    bool formEncoded = false,
  }) async {
    final response = await _client.post(
      Uri.parse("${ApiConfig.baseUrl}$endpoint"),
      headers: formEncoded
          ? {
              "Accept": "application/json",
              "Content-Type": "application/x-www-form-urlencoded",
              if (token != null) "Authorization": "Bearer $token",
            }
          : {
              "Accept": "application/json",
              "Content-Type": "application/json",
              if (token != null) "Authorization": "Bearer $token",
            },
      body: formEncoded ? body : jsonEncode(body ?? {}),
    );

    return _handleResponse("POST", endpoint, response);
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await _client.patch(
      Uri.parse("${ApiConfig.baseUrl}$endpoint"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse("PATCH", endpoint, response);
  }

  static Map<String, dynamic> _handleResponse(
    String method,
    String endpoint,
    http.Response response,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      "$method $endpoint failed: ${response.statusCode} ${response.body}",
    );
  }
}