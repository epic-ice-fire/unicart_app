class Lobby {
  final int lobbyId;
  final String status;
  final int currentItemAmount;
  final int targetItemAmount;
  final int memberCount;

  Lobby({
    required this.lobbyId,
    required this.status,
    required this.currentItemAmount,
    required this.targetItemAmount,
    required this.memberCount,
  });

  factory Lobby.fromJson(Map<String, dynamic> json) {
    return Lobby(
      lobbyId: json["lobby_id"] as int,
      status: json["status"] as String,
      currentItemAmount: json["current_item_amount"] as int,
      targetItemAmount: json["target_item_amount"] as int,
      memberCount: json["member_count"] as int,
    );
  }
}