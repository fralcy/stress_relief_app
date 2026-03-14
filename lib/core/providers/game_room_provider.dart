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
// GameRoomProvider
// ============================================================

/// Quản lý toàn bộ vòng đời của một phòng game LAN:
/// lobby (danh sách người chơi, trạng thái sẵn sàng) và game session.
///
/// Host là authority: nhận [GameEvent.playerAction] từ client,
/// xử lý logic game, rồi gọi [broadcastGameState] để đẩy state mới.
///
/// Usage (host — sau khi [LanProvider.startHosting]):
/// ```dart
/// provider.init(uid, displayName);
/// provider.createRoom(GameType.rockBalancing);
/// provider.playerActions.listen((action) {
///   final newState = processAction(action);
///   provider.broadcastGameState(newState);
/// });
/// ```
///
/// Usage (client — sau khi [LanProvider.connect]):
/// ```dart
/// provider.init(uid, displayName);
/// provider.joinRoom(displayName);
/// provider.setReady(true);
/// // watch provider.gameState trong widget
/// ```
class GameRoomProvider extends ChangeNotifier {
  GameRoom? _room;
  Map<String, dynamic> _gameState = {};
  Map<String, dynamic>? _gameResults;
  String _localPlayerId = '';
  String _localDisplayName = '';

  StreamSubscription<LanIncomingEvent>? _lanSub;
  final StreamController<GameActionEvent> _actionController =
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

  // ----------------------------------------------------------
  // Init / dispose
  // ----------------------------------------------------------

  /// Khởi tạo provider với ID và tên hiển thị của người chơi cục bộ.
  ///
  /// Gọi sau khi LAN kết nối thành công, trước khi tạo/vào phòng.
  /// [playerId] nên là Firebase Auth UID hoặc ID ổn định tương đương.
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
    super.dispose();
  }

  // ----------------------------------------------------------
  // Host actions
  // ----------------------------------------------------------

  /// Tạo phòng mới (host only). Gọi sau [init].
  ///
  /// Host tự động sẵn sàng; các client join sau sẽ cần [setReady].
  void createRoom(GameType gameType) {
    final host = GamePlayer(
      id: _localPlayerId,
      displayName: _localDisplayName,
      isReady: true,
      isHost: true,
    );
    _room = GameRoom(gameType: gameType, players: [host]);
    _gameState = {};
    _gameResults = null;
    _broadcastLobbyState();
    notifyListeners();
  }

  /// Bắt đầu game (host only). Kèm [initialState] phù hợp với [GameType].
  ///
  /// Ví dụ: `{'stones': [], 'currentTurn': hostId}` cho Xếp đá.
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
  ///
  /// Game widget gọi method này sau mỗi lần xử lý [playerActions].
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
  ///
  /// Host: cập nhật local và rebroadcast lobby.
  /// Client: gửi message đến host.
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
  ///
  /// [actionData] tự định nghĩa theo từng game, ví dụ:
  /// `{'type': 'place_stone', 'x': 3, 'y': 5}` cho Xếp đá.
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
    notifyListeners();
  }

  // ----------------------------------------------------------
  // Incoming event handler
  // ----------------------------------------------------------

  void _handleIncoming(LanIncomingEvent event) {
    final msg = event.message;

    // Xử lý ngắt kết nối bất ngờ (bye message từ transport layer)
    if (msg.messageType == LanMessageType.bye && isHost) {
      _removePlayer(msg.senderId);
      return;
    }

    final gm = GameMessage.tryExtract(msg);
    if (gm == null) return;

    if (isHost) {
      _handleAsHost(gm, msg.senderId);
    } else {
      _handleAsClient(gm);
    }
  }

  void _handleAsHost(GameMessage gm, String fromId) {
    switch (gm.event) {
      case GameEvent.playerJoin:
        if (_room == null) return;
        final name = gm.data['displayName'] as String? ?? fromId;
        final newPlayer = GamePlayer(id: fromId, displayName: name);
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
          _actionController.add(GameActionEvent(playerId: fromId, data: gm.data));
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
}
