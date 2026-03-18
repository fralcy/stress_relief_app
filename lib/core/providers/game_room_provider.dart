import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/lan/lan_service.dart';
import '../utils/lan/lan_message.dart';
import '../utils/lan/game_message.dart';
import '../utils/lan/game_room.dart';

// ============================================================
// GameActionEvent — action của player gửi đến host
// ============================================================

/// Được emit trên [GameRoomProvider.playerActions] khi host nhận action từ client.
class GameActionEvent {
  final String playerId;
  final Map<String, dynamic> data;

  const GameActionEvent({required this.playerId, required this.data});
}

// ============================================================
// LobbyErrorType — lý do client bị đẩy ra khỏi lobby
// ============================================================

enum LobbyErrorType { denied, kicked }

// ============================================================
// GameRoomProvider
// ============================================================

/// Quản lý toàn bộ vòng đời của một phòng game LAN:
/// lobby (danh sách người chơi, trạng thái sẵn sàng) và game session.
///
/// Host là authority: nhận [GameEvent.playerAction] từ client,
/// xử lý logic game, rồi gọi [broadcastGameState] để đẩy state mới.
class GameRoomProvider extends ChangeNotifier {
  GameRoom? _room;
  Map<String, dynamic> _gameState = {};
  Map<String, dynamic>? _gameResults;
  String _localPlayerId = '';
  String _localDisplayName = '';

  /// Map từ player user ID → server-internal socket clientId.
  /// Host dùng để gửi targeted message đến client cụ thể.
  final Map<String, String> _playerSocketIds = {};

  StreamSubscription<LanIncomingEvent>? _lanSub;
  final StreamController<GameActionEvent> _actionController =
      StreamController.broadcast();

  /// Stream lỗi cho client: bị từ chối hoặc bị kick.
  final StreamController<LobbyErrorType> _lobbyErrorController =
      StreamController.broadcast();

  // ----------------------------------------------------------
  // Getters
  // ----------------------------------------------------------

  /// Trạng thái phòng hiện tại. `null` khi chưa vào phòng nào.
  GameRoom? get currentRoom => _room;

  /// State game hiện tại (shape tuỳ theo từng game).
  Map<String, dynamic> get gameState => _gameState;

  /// Kết quả game sau khi [GameRoomStatus.finished].
  Map<String, dynamic>? get gameResults => _gameResults;

  String get localPlayerId => _localPlayerId;
  bool get isHost => LanService().role == LanRole.host;

  GamePlayer? get localPlayer => _room?.players
      .cast<GamePlayer?>()
      .firstWhere((p) => p?.id == _localPlayerId, orElse: () => null);

  /// Host lắng nghe stream này để xử lý action từ client,
  /// rồi gọi [broadcastGameState] với state mới.
  Stream<GameActionEvent> get playerActions => _actionController.stream;

  /// Client lắng nghe stream này để biết khi bị từ chối hoặc kick.
  Stream<LobbyErrorType> get lobbyErrors => _lobbyErrorController.stream;

  // ----------------------------------------------------------
  // Init / dispose
  // ----------------------------------------------------------

  /// Khởi tạo provider với ID và tên hiển thị của người chơi cục bộ.
  void init(String playerId, String displayName) {
    _localPlayerId = playerId;
    _localDisplayName = displayName;
    _lanSub?.cancel();
    _lanSub = LanService().incomingEvents.listen(_handleIncoming);
  }

  @override
  void dispose() {
    _lanSub?.cancel();
    _actionController.close();
    _lobbyErrorController.close();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Host actions
  // ----------------------------------------------------------

  /// Tạo phòng mới (host only). Gọi sau [init].
  void createRoom(GameType gameType, {bool requireApproval = false}) {
    final host = GamePlayer(
      id: _localPlayerId,
      displayName: _localDisplayName,
      isReady: true,
      isHost: true,
    );
    _room = GameRoom(
      gameType: gameType,
      players: [host],
      requireApproval: requireApproval,
    );
    _gameState = {};
    _gameResults = null;
    _broadcastLobbyState();
    notifyListeners();
  }

  /// Thay đổi chế độ xác nhận (host only, chỉ khi đang waiting).
  void setRequireApproval(bool value) {
    if (!isHost || _room == null) return;
    if (_room!.status != GameRoomStatus.waiting) return;
    _room = _room!.copyWith(requireApproval: value);
    _broadcastLobbyState();
    notifyListeners();
  }

  /// Chấp nhận player đang pending (host only).
  void approvePlayer(String playerId) {
    if (!isHost || _room == null) return;
    final socketId = _playerSocketIds[playerId];
    if (socketId == null) return;
    _updatePlayerPending(playerId, false);
    LanService().sendMessage(
      GameMessage.playerApprove(_localPlayerId, socketId, playerId),
    );
    _broadcastLobbyState();
  }

  /// Từ chối hoặc kick player (host only).
  /// Gửi [playerKick] nếu player đã được chấp nhận, [playerDeny] nếu còn pending.
  void kickPlayer(String playerId) {
    if (!isHost || _room == null) return;
    final socketId = _playerSocketIds[playerId];
    final player = _room!.players.cast<GamePlayer?>()
        .firstWhere((p) => p?.id == playerId, orElse: () => null);
    if (player == null) return;

    if (socketId != null) {
      final event = player.isPending
          ? GameMessage.playerDeny(_localPlayerId, socketId, playerId)
          : GameMessage.playerKick(_localPlayerId, socketId, playerId);
      LanService().sendMessage(event);
    }
    _removePlayer(playerId);
  }

  /// Bắt đầu game (host only). Kèm [initialState] phù hợp với [GameType].
  void startGame(Map<String, dynamic> initialState) {
    if (!isHost) return;
    _gameState = initialState;
    _room = _room?.copyWith(status: GameRoomStatus.playing);
    LanService().broadcastMessage(
      GameMessage.gameStart(_localPlayerId, initialState),
    );
    notifyListeners();
  }

  /// Broadcast state game mới đến tất cả client (host only).
  void broadcastGameState(Map<String, dynamic> state) {
    if (!isHost) return;
    _gameState = state;
    LanService().broadcastMessage(
      GameMessage.gameState(_localPlayerId, state),
    );
    notifyListeners();
  }

  /// Kết thúc game và broadcast kết quả (host only).
  void endGame(Map<String, dynamic> results) {
    if (!isHost) return;
    _gameResults = results;
    _room = _room?.copyWith(status: GameRoomStatus.finished);
    LanService().broadcastMessage(
      GameMessage.gameEnd(_localPlayerId, results),
    );
    notifyListeners();
  }

  // ----------------------------------------------------------
  // Client actions
  // ----------------------------------------------------------

  /// Gửi yêu cầu vào phòng (client only). Gọi sau [init] và sau khi LAN connected.
  void joinRoom() {
    LanService().sendMessage(
      GameMessage.playerJoin(_localPlayerId, _localDisplayName),
    );
  }

  // ----------------------------------------------------------
  // Shared actions
  // ----------------------------------------------------------

  /// Cập nhật trạng thái sẵn sàng.
  void setReady(bool isReady) {
    if (isHost) {
      _updatePlayerReady(_localPlayerId, isReady);
      _broadcastLobbyState();
    } else {
      LanService().sendMessage(
        GameMessage.playerReady(_localPlayerId, isReady),
      );
    }
  }

  /// Gửi action game đến host.
  void sendAction(Map<String, dynamic> actionData) {
    LanService().sendMessage(
      GameMessage.playerAction(_localPlayerId, actionData),
    );
  }

  /// Rời phòng và reset state.
  void leaveRoom() {
    LanService().sendMessage(GameMessage.playerLeave(_localPlayerId));
    _room = null;
    _gameState = {};
    _gameResults = null;
    _playerSocketIds.clear();
    notifyListeners();
  }

  // ----------------------------------------------------------
  // Incoming event handler
  // ----------------------------------------------------------

  void _handleIncoming(LanIncomingEvent event) {
    final msg = event.message;

    if (msg.messageType == LanMessageType.bye && isHost) {
      _removePlayer(msg.senderId);
      return;
    }

    final gm = GameMessage.tryExtract(msg);
    if (gm == null) return;

    if (isHost) {
      _handleAsHost(gm, msg.senderId, event.clientId);
    } else {
      _handleAsClient(gm);
    }
  }

  void _handleAsHost(GameMessage gm, String fromId, String socketId) {
    switch (gm.event) {
      case GameEvent.playerJoin:
        if (_room == null) return;
        if (_room!.isFull) return; // phòng đầy, bỏ qua
        _playerSocketIds[fromId] = socketId;
        final name = gm.data['displayName'] as String? ?? fromId;
        final isPending = _room!.requireApproval;
        final newPlayer = GamePlayer(
          id: fromId,
          displayName: name,
          isPending: isPending,
        );
        _room = _room!.copyWith(players: [..._room!.players, newPlayer]);
        _broadcastLobbyState();
        notifyListeners();

      case GameEvent.playerLeave:
        _removePlayer(fromId);

      case GameEvent.playerReady:
        final isReady = gm.data['isReady'] as bool? ?? false;
        _updatePlayerReady(fromId, isReady);
        _broadcastLobbyState();

      case GameEvent.playerAction:
        if (!_actionController.isClosed) {
          _actionController
              .add(GameActionEvent(playerId: fromId, data: gm.data));
        }

      default:
        break;
    }
  }

  void _handleAsClient(GameMessage gm) {
    switch (gm.event) {
      case GameEvent.lobbyState:
        _room = GameRoom.fromJson(gm.data);
        notifyListeners();

      case GameEvent.playerApprove:
        // Lobby state được broadcast ngay sau đó — không cần xử lý thêm.
        break;

      case GameEvent.playerDeny:
        if (!_lobbyErrorController.isClosed) {
          _lobbyErrorController.add(LobbyErrorType.denied);
        }

      case GameEvent.playerKick:
        if (!_lobbyErrorController.isClosed) {
          _lobbyErrorController.add(LobbyErrorType.kicked);
        }

      case GameEvent.gameStart:
        _gameState = gm.data;
        _room = _room?.copyWith(status: GameRoomStatus.playing);
        notifyListeners();

      case GameEvent.gameState:
        _gameState = gm.data;
        notifyListeners();

      case GameEvent.gameEnd:
        _gameResults = gm.data;
        _room = _room?.copyWith(status: GameRoomStatus.finished);
        notifyListeners();

      default:
        break;
    }
  }

  // ----------------------------------------------------------
  // Internal helpers
  // ----------------------------------------------------------

  void _broadcastLobbyState() {
    if (_room == null) return;
    LanService().broadcastMessage(
      GameMessage.lobbyState(_localPlayerId, _room!),
    );
  }

  void _removePlayer(String playerId) {
    if (_room == null) return;
    _playerSocketIds.remove(playerId);
    final updated = _room!.players.where((p) => p.id != playerId).toList();
    _room = _room!.copyWith(players: updated);
    _broadcastLobbyState();
    notifyListeners();
  }

  void _updatePlayerReady(String playerId, bool isReady) {
    if (_room == null) return;
    final updated = _room!.players
        .map((p) => p.id == playerId ? p.copyWith(isReady: isReady) : p)
        .toList();
    _room = _room!.copyWith(players: updated);
    notifyListeners();
  }

  void _updatePlayerPending(String playerId, bool isPending) {
    if (_room == null) return;
    final updated = _room!.players
        .map((p) => p.id == playerId ? p.copyWith(isPending: isPending) : p)
        .toList();
    _room = _room!.copyWith(players: updated);
    notifyListeners();
  }
}
