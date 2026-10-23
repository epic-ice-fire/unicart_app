import "package:flutter_test/flutter_test.dart";
import "package:unicart_app/services/api_error.dart";

void main() {
  group("friendlyApiError", () {
    test("reads a string detail", () {
      final error = Exception(
        'POST /auth/account/delete failed: 403 {"detail":"Incorrect password."}',
      );
      expect(friendlyApiError(error), "Incorrect password.");
    });

    test("joins validation messages from a list detail", () {
      final error = Exception(
        'POST /auth/password-reset/confirm failed: 422 '
        '{"detail":[{"type":"value_error","msg":"Value error, Choose a less common password."}]}',
      );
      expect(friendlyApiError(error), "Choose a less common password.");
    });

    test("explains connection problems when there is no JSON", () {
      final error = Exception("ClientException: Failed to fetch");
      expect(friendlyApiError(error), contains("Could not connect"));
    });

    test("explains rate limiting when there is no JSON", () {
      final error = Exception("POST /auth/login failed: 429 Too Many Requests");
      expect(friendlyApiError(error), contains("Too many attempts"));
    });

    test("uses the fallback for anything else", () {
      expect(
        friendlyApiError(Exception("boom"), fallback: "Try again later."),
        "Try again later.",
      );
      expect(friendlyApiError(Exception("boom")), isNotEmpty);
    });
  });

  group("apiErrorStatus", () {
    test("extracts the status code", () {
      final error = Exception('POST /x failed: 409 {"detail":"nope"}');
      expect(apiErrorStatus(error), 409);
    });

    test("returns null when there is no status", () {
      expect(apiErrorStatus(Exception("boom")), isNull);
    });
  });
}
