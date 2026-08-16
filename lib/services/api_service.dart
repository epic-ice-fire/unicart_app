import "dart:async";
import "dart:convert";

import "package:http/http.dart" as http;

import "../config/api.dart";

class ApiService {
  ApiService._();

  static const Duration _requestTimeout = Duration(seconds: 25);
  static const Duration _healthAttemptTimeout = Duration(seconds: 12);
  static const Duration _backendReadyCache = Duration(minutes: 5);
  static final http.Client _client = http.Client();
  static DateTime? _lastBackendReadyAt;

  static Future<void> warmUp() async {
    try {
      await ensureBackendReady(maxWait: const Duration(seconds: 75));
    } catch (_) {
      return;
    }
  }

  static Future<void> ensureBackendReady({
    Duration maxWait = const Duration(seconds: 75),
  }) async {
    final lastReady = _lastBackendReadyAt;
    if (lastReady != null &&
        DateTime.now().difference(lastReady) < _backendReadyCache) {
      return;
    }

    final deadline = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(deadline)) {
      try {
        final response = await _client
            .get(
              Uri.parse("${ApiConfig.baseUrl}/health"),
              headers: const {"Accept": "application/json"},
            )
            .timeout(_healthAttemptTimeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _lastBackendReadyAt = DateTime.now();
          return;
        }
      } catch (_) {}

      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) break;
      await Future.delayed(
        remaining < const Duration(seconds: 2)
            ? remaining
            : const Duration(seconds: 2),
      );
    }

    throw TimeoutException(
      "UniCart server is taking longer than expected to wake up.",
    );
  }

  static Future<http.Response> _withTimeout(
    Future<http.Response> request,
  ) async {
    try {
      return await request.timeout(_requestTimeout);
    } on TimeoutException {
      throw TimeoutException("Connection to UniCart timed out.");
    }
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
  }) async {
    final response = await _withTimeout(
      _client.get(
        Uri.parse("${ApiConfig.baseUrl}$endpoint"),
        headers: {
          "Accept": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      ),
    );

    return _handleResponse("GET", endpoint, response);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
    bool formEncoded = false,
  }) async {
    final response = await _withTimeout(
      _client.post(
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
      ),
    );

    return _handleResponse("POST", endpoint, response);
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await _withTimeout(
      _client.patch(
        Uri.parse("${ApiConfig.baseUrl}$endpoint"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(body ?? {}),
      ),
    );

    return _handleResponse("PATCH", endpoint, response);
  }

  static Map<String, dynamic> _handleResponse(
    String method,
    String endpoint,
    http.Response response,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      "$method $endpoint failed: ${response.statusCode} ${response.body}",
    );
  }
}
