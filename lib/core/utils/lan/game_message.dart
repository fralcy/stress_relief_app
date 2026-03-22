import 'lan_message.dart';
import 'game_room.dart';

// ============================================================
// GameEvent — loại sự kiện game-level trên LanMessage.data
// ============================================================

enum GameEvent {
  /// Host → broadcast: snapshot đầy đủ trạng thái lobby.
  lobbyState,

  /// Client → host: yêu cầu vào phòng.
  playerJoin,

  /// Bất kỳ → broadcast: thông báo rời phòng.
  playerLeave,

  /// Client → host: cập nhật trạng thái sẵn sàng.
  playerReady,

  /// Host → client cụ thể: chấp nhận vào phòng.
  playerApprove,

  /// Host → client cụ thể: từ chối vào phòng.
  playerDeny,

  /// Host → client cụ thể: kick khỏi phòng.
  playerKick,

  /// Host → broadcast: bắt đầu game với state khởi tạo.
  gameStart,

  /// Bất kỳ → host: hành động của người chơi (game-specific).
  playerAction,

  /// Host → broadcast: state game được cập nhật (authoritative).
  gameState,

  /// Host → broadcast: kết thúc game kèm kết quả.
  gameEnd,

  /// Client → host (targeted): request a full world snapshot after mid-game rejoin.
  snapshotRequest,

  /// Host → client (targeted): ACK for snapshotRequest — sent immediately before building snapshot.
  snapshotAck,

  /// Host → client (targeted): full world state for mid-game rejoin.
  fullSnapshot,
}

// ============================================================
// GameMessage — protocol layer trên LanMessage.data
// ============================================================

/// Tầng giao thức game xây dựng trên [LanMessage.data].
///
/// Payload format:
/// ```json
/// { "event": "<GameEvent.name>", "data": { ... } }
/// ```
///
/// Dùng [tryExtract] để parse một [LanMessage] thành [GameMessage].
/// Dùng các static factory (lobbyState, playerJoin, …) để tạo [LanMessage]
/// sẵn sàng gửi qua [LanService].
class GameMessage {
  final GameEvent event;
  final Map<String, dynamic> data;

  const GameMessage({required this.event, required this.data});

  // ----------------------------------------------------------
  // Parse
  // ----------------------------------------------------------

  /// Trích xuất [GameMessage] từ một [LanMessage].
  ///
  /// Trả về `null` nếu [msg] không phải `data` type hoặc không có `event`.
  static GameMessage? tryExtract(LanMessage msg) {
    if (msg.messageType != LanMessageType.data) return null;
    final eventStr = msg.payload['event'] as String?;
    if (eventStr == null) return null;
    final event = GameEvent.values.cast<GameEvent?>().firstWhere(
          (e) => e?.name == eventStr,
          orElse: () => null,
        );
    if (event == null) return null;
    return GameMessage(
      event: event,
      data: (msg.payload['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  // ----------------------------------------------------------
  // Static factories — trả về LanMessage sẵn sàng gửi
  // ----------------------------------------------------------

  static LanMessage lobbyState(String senderId, GameRoom room) =>
      LanMessage.data(senderId, _wrap(GameEvent.lobbyState, room.toJson()));

  static LanMessage playerJoin(
          String senderId, String displayName, int avatarIndex) =>
      LanMessage.data(
          senderId,
          _wrap(GameEvent.playerJoin,
              {'displayName': displayName, 'avatarIndex': avatarIndex}));

  static LanMessage playerLeave(String senderId) =>
      LanMessage.data(senderId, _wrap(GameEvent.playerLeave, {}));

  static LanMessage playerReady(String senderId, bool isReady) =>
      LanMessage.data(
          senderId, _wrap(GameEvent.playerReady, {'isReady': isReady}));

  /// Host → client cụ thể: chấp nhận vào phòng.
  /// [socketTargetId] là server-internal clientId (không phải player user ID).
  static LanMessage playerApprove(
          String senderId, String socketTargetId, String playerId) =>
      LanMessage.data(
        senderId,
        _wrap(GameEvent.playerApprove, {'playerId': playerId}),
        targetId: socketTargetId,
      );

  /// Host → client cụ thể: từ chối vào phòng.
  static LanMessage playerDeny(
          String senderId, String socketTargetId, String playerId) =>
      LanMessage.data(
        senderId,
        _wrap(GameEvent.playerDeny, {'playerId': playerId}),
        targetId: socketTargetId,
      );

  /// Host → client cụ thể: kick khỏi phòng.
  static LanMessage playerKick(
          String senderId, String socketTargetId, String playerId) =>
      LanMessage.data(
        senderId,
        _wrap(GameEvent.playerKick, {'playerId': playerId}),
        targetId: socketTargetId,
      );

  /// Pass [targetId] (server socket ID) to send only to a reconnecting client.
  static LanMessage gameStart(
          String senderId, Map<String, dynamic> initialState,
          {String? targetId}) =>
      LanMessage.data(senderId, _wrap(GameEvent.gameStart, initialState),
          targetId: targetId);

  static LanMessage playerAction(
          String senderId, Map<String, dynamic> actionData) =>
      LanMessage.data(senderId, _wrap(GameEvent.playerAction, actionData));

  static LanMessage gameState(
          String senderId, Map<String, dynamic> state) =>
      LanMessage.data(senderId, _wrap(GameEvent.gameState, state));

  static LanMessage gameEnd(
          String senderId, Map<String, dynamic> results) =>
      LanMessage.data(senderId, _wrap(GameEvent.gameEnd, results));

  static LanMessage snapshotRequest(String senderId) =>
      LanMessage.data(senderId, _wrap(GameEvent.snapshotRequest, {}));

  static LanMessage snapshotAck(String senderId, String socketTargetId) =>
      LanMessage.data(senderId, _wrap(GameEvent.snapshotAck, {}),
          targetId: socketTargetId);

  static LanMessage fullSnapshot(
          String senderId, String socketTargetId, Map<String, dynamic> state) =>
      LanMessage.data(senderId, _wrap(GameEvent.fullSnapshot, state),
          targetId: socketTargetId);

  // ----------------------------------------------------------

  static Map<String, dynamic> _wrap(
          GameEvent event, Map<String, dynamic> data) =>
      {'event': event.name, 'data': data};
}
