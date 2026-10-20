import "dart:async";
import "dart:convert";

import "package:http/http.dart" as http;

import "../config/api.dart";

class LobbyService {
  static const Duration _requestTimeout = Duration(seconds: 25);

  static String get baseUrl => ApiConfig.baseUrl;

  static Map<String, String> _headers(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<http.Response> _withTimeout(
    Future<http.Response> request,
  ) async {
    try {
      return await request.timeout(_requestTimeout);
    } on TimeoutException {
      throw Exception("UniCart took too long to respond. Please try again.");
    }
  }

  static dynamic _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  static Exception _errorFromResponse(http.Response response) {
    try {
      final data = _decodeResponse(response);
      final detail = data is Map<String, dynamic>
          ? (data["detail"] ?? data["message"] ?? "Request failed.")
          : "Request failed.";
      return Exception(detail.toString());
    } catch (_) {
      return Exception("Request failed with status ${response.statusCode}");
    }
  }

  static Future<Map<String, dynamic>> mainLobbyDetails(String token, {String retailer = "temu"}) async {
    final response = await _withTimeout(
      http.get(
        Uri.parse("$baseUrl/lobbies/main/details").replace(queryParameters: {"retailer": retailer}),
        headers: _headers(token),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> myMainLobbyItems(String token, {String retailer = "temu"}) async {
    final response = await _withTimeout(
      http.get(
        Uri.parse("$baseUrl/lobbies/main/my-items").replace(queryParameters: {"retailer": retailer}),
        headers: _headers(token),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> myBatchHistory(String token, {String retailer = "temu"}) async {
    final response = await _withTimeout(
      http.get(
        Uri.parse("$baseUrl/lobbies/my-history").replace(queryParameters: {"retailer": retailer}),
        headers: _headers(token),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> initializeEntryFeePayment(
    String token, {String retailer = "temu"}
  ) async {
    final response = await _withTimeout(
      http.post(
        Uri.parse("$baseUrl/payments/entry-fee/initialize").replace(queryParameters: {"retailer": retailer}),
        headers: _headers(token),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> verifyEntryFeePayment(
    String token, {
    required String reference,
  }) async {
    final response = await _withTimeout(
      http.get(
        Uri.parse("$baseUrl/payments/verify/$reference"),
        headers: _headers(token),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> leaveLobby(String token, {String retailer = "temu"}) async {
    final response = await _withTimeout(
      http.post(
        Uri.parse("$baseUrl/lobbies/main/leave").replace(queryParameters: {"retailer": retailer}),
        headers: _headers(token),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> addItem(
    String token, {
    required String itemLink,
    required int itemAmount,
    String retailer = "temu",
  }) async {
    final response = await _withTimeout(
      http.post(
        Uri.parse("$baseUrl/lobbies/main/items").replace(queryParameters: {"retailer": retailer}),
        headers: _headers(token),
        body: jsonEncode({"item_link": itemLink, "item_amount": itemAmount}),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> removeItem(
    String token, {
    required int itemId,
    String retailer = "temu",
  }) async {
    final response = await _withTimeout(
      http.post(
        Uri.parse("$baseUrl/lobbies/main/items/$itemId/remove").replace(queryParameters: {"retailer": retailer}),
        headers: _headers(token),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> adminForceRemoveItem(
    String token, {
    required int itemId,
  }) async {
    final response = await _withTimeout(
      http.post(
        Uri.parse("$baseUrl/lobbies/admin/items/$itemId/remove"),
        headers: _headers(token),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> initializeItemPayment(
    String token, {
    required int itemId,
  }) async {
    final response = await _withTimeout(
      http.post(
        Uri.parse("$baseUrl/payments/items/$itemId/initialize"),
        headers: _headers(token),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> verifyItemPayment(
    String token, {
    required String reference,
  }) async {
    final response = await _withTimeout(
      http.get(
        Uri.parse("$baseUrl/payments/items/verify/$reference"),
        headers: _headers(token),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> adminDashboard(String token, {String schoolId = "pau", String retailer = "temu"}) async {
    final response = await _withTimeout(
      http.get(
        Uri.parse("$baseUrl/lobbies/admin/dashboard").replace(queryParameters: {"school_id": schoolId, "retailer": retailer}),
        headers: _headers(token),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> adminUpdateOpenLobbyTarget(
    String token, {
    required int targetItemAmount,
    String schoolId = "pau",
    String retailer = "temu",
  }) async {
    final response = await _withTimeout(
      http.patch(
        Uri.parse("$baseUrl/lobbies/admin/open-lobby/target").replace(queryParameters: {"school_id": schoolId, "retailer": retailer}),
        headers: _headers(token),
        body: jsonEncode({"target_item_amount": targetItemAmount}),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }

  static Future<Map<String, dynamic>> adminUpdateBatchStatus(
    String token, {
    required int lobbyId,
    required String newStatus,
  }) async {
    final response = await _withTimeout(
      http.patch(
        Uri.parse(
          "$baseUrl/lobbies/admin/batches/$lobbyId/status?new_status=$newStatus",
        ),
        headers: _headers(token),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeResponse(response) as Map<String, dynamic>;
    }
    throw _errorFromResponse(response);
  }
}
