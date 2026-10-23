import "dart:convert";

/// HTTP status code embedded in an ApiService exception message such as
/// `Exception: POST /x failed: 403 {"detail":"..."}`. Null if there is none.
int? apiErrorStatus(Object error) {
  final match = RegExp(r"failed:\s*(\d{3})").firstMatch(error.toString());
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

/// Turns an exception thrown by ApiService/LobbyService into a short message
/// that is safe to show to a shopper.
///
/// Understands FastAPI error bodies where `detail` is either a string or a
/// list of `{"msg": ...}` validation errors.
String friendlyApiError(
  Object error, {
  String fallback = "Something went wrong. Please try again.",
}) {
  var raw = error.toString();
  if (raw.startsWith("Exception: ")) raw = raw.substring(11);

  final jsonStart = raw.indexOf("{");
  if (jsonStart >= 0) {
    try {
      final decoded = jsonDecode(raw.substring(jsonStart));
      if (decoded is Map) {
        final detail = decoded["detail"] ?? decoded["message"];
        final message = _detailToText(detail);
        if (message != null && message.isNotEmpty) return message;
      }
    } catch (_) {
      // Not JSON; fall through to the generic handling below.
    }
  }

  final status = apiErrorStatus(error);
  if (status == 429) {
    return "Too many attempts. Please wait a few minutes and try again.";
  }

  if (raw.contains("Failed to fetch") ||
      raw.contains("SocketException") ||
      raw.contains("ClientException") ||
      raw.contains("Connection") ||
      raw.contains("TimeoutException") ||
      raw.contains("timed out")) {
    return "Could not connect to UniCart. Check your connection and try again.";
  }

  return fallback;
}

String? _detailToText(Object? detail) {
  if (detail is String) return detail.trim();
  if (detail is List) {
    final parts = <String>[];
    for (final item in detail) {
      if (item is Map && item["msg"] is String) {
        var msg = (item["msg"] as String).trim();
        const prefix = "Value error, ";
        if (msg.startsWith(prefix)) msg = msg.substring(prefix.length);
        if (msg.isNotEmpty) parts.add(msg);
      } else if (item is String && item.trim().isNotEmpty) {
        parts.add(item.trim());
      }
    }
    if (parts.isNotEmpty) return parts.join(" ");
  }
  return null;
}
