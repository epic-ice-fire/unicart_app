import "package:flutter_test/flutter_test.dart";
import "package:unicart_app/models/lobby.dart";

void main() {
  test("Lobby.fromJson maps API payload", () {
    final lobby = Lobby.fromJson({
      "lobby_id": 7,
      "status": "open",
      "current_item_amount": 18000,
      "target_item_amount": 50000,
      "member_count": 4,
    });

    expect(lobby.lobbyId, 7);
    expect(lobby.status, "open");
    expect(lobby.currentItemAmount, 18000);
    expect(lobby.targetItemAmount, 50000);
    expect(lobby.memberCount, 4);
  });
}
