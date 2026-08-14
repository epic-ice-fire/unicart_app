import "package:flutter/foundation.dart";

class ApiConfig {
  static const String baseUrl = kReleaseMode
      ? "https://unicart-backend-v6u9.onrender.com"
      : "http://localhost:8000";
}
