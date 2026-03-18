import 'package:flutter/foundation.dart';

// ============================================================
// GameType
// ============================================================

enum GameType {
  rockBalancing,
  catchFirefly,
  paperShip,
}

// ============================================================
// GameRoomStatus
// ============================================================

enum GameRoomStatus {
  waiting,
  playing,
  finished,
}

// ============================================================
// GamePlayer
// ============================================================

@immutable
class GamePlayer {
  final String id;
  final String displayName;
  final bool isReady;
  final bool isHost;
  final bool isPending; // chờ host xác nhận khi requireApproval = true

  const GamePlayer({
    required this.id,
    required this.displayName,
    this.isReady = false,
    this.isHost = false,
    this.isPending = false,
  });

  GamePlayer copyWith({
    bool? isReady,
    bool? isHost,
    bool? isPending,
  }) =>
      GamePlayer(
        id: id,
        displayName: displayName,
        isReady: isReady ?? this.isReady,
        isHost: isHost ?? this.isHost,
        isPending: isPending ?? this.isPending,
      );

  factory GamePlayer.fromJson(Map<String, dynamic> json) => GamePlayer(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        isReady: json['isReady'] as bool? ?? false,
        isHost: json['isHost'] as bool? ?? false,
        isPending: json['isPending'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'isReady': isReady,
        'isHost': isHost,
        'isPending': isPending,
      };
}

// ============================================================
// GameRoom
// ============================================================

/// Số người chơi tối đa trong một phòng.
const int kMaxRoomPlayers = 8;

@immutable
class GameRoom {
  final GameType gameType;
  final List<GamePlayer> players;
  final GameRoomStatus status;
  final bool requireApproval;

  const GameRoom({
    required this.gameType,
    required this.players,
    this.status = GameRoomStatus.waiting,
    this.requireApproval = false,
  });

  GameRoom copyWith({
    List<GamePlayer>? players,
    GameRoomStatus? status,
    bool? requireApproval,
  }) =>
      GameRoom(
        gameType: gameType,
        players: players ?? this.players,
        status: status ?? this.status,
        requireApproval: requireApproval ?? this.requireApproval,
      );

  factory GameRoom.fromJson(Map<String, dynamic> json) => GameRoom(
        gameType: GameType.values.firstWhere(
          (e) => e.name == json['gameType'],
          orElse: () => GameType.rockBalancing,
        ),
        players: (json['players'] as List<dynamic>)
            .map((p) => GamePlayer.fromJson(p as Map<String, dynamic>))
            .toList(),
        status: GameRoomStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => GameRoomStatus.waiting,
        ),
        requireApproval: json['requireApproval'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'gameType': gameType.name,
        'players': players.map((p) => p.toJson()).toList(),
        'status': status.name,
        'requireApproval': requireApproval,
      };

  GamePlayer? get hostPlayer =>
      players.cast<GamePlayer?>().firstWhere((p) => p!.isHost, orElse: () => null);

  /// Danh sách player đã được chấp nhận (không pending).
  List<GamePlayer> get activePlayers =>
      players.where((p) => !p.isPending).toList();

  /// Danh sách player đang chờ xác nhận.
  List<GamePlayer> get pendingPlayers =>
      players.where((p) => p.isPending).toList();

  /// `true` khi có ít nhất 2 active player và tất cả đều sẵn sàng.
  bool get allReady =>
      activePlayers.length >= 2 && activePlayers.every((p) => p.isReady);

  /// `true` khi phòng còn chỗ.
  bool get isFull => activePlayers.length >= kMaxRoomPlayers;
}
