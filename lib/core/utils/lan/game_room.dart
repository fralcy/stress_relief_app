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

  const GamePlayer({
    required this.id,
    required this.displayName,
    this.isReady = false,
    this.isHost = false,
  });

  GamePlayer copyWith({bool? isReady, bool? isHost}) => GamePlayer(
        id: id,
        displayName: displayName,
        isReady: isReady ?? this.isReady,
        isHost: isHost ?? this.isHost,
      );

  factory GamePlayer.fromJson(Map<String, dynamic> json) => GamePlayer(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        isReady: json['isReady'] as bool? ?? false,
        isHost: json['isHost'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'isReady': isReady,
        'isHost': isHost,
      };
}

// ============================================================
// GameRoom
// ============================================================

@immutable
class GameRoom {
  final GameType gameType;
  final List<GamePlayer> players;
  final GameRoomStatus status;

  const GameRoom({
    required this.gameType,
    required this.players,
    this.status = GameRoomStatus.waiting,
  });

  GameRoom copyWith({
    List<GamePlayer>? players,
    GameRoomStatus? status,
  }) =>
      GameRoom(
        gameType: gameType,
        players: players ?? this.players,
        status: status ?? this.status,
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
      );

  Map<String, dynamic> toJson() => {
        'gameType': gameType.name,
        'players': players.map((p) => p.toJson()).toList(),
        'status': status.name,
      };

  GamePlayer? get hostPlayer =>
      players.cast<GamePlayer?>().firstWhere((p) => p!.isHost, orElse: () => null);

  /// `true` khi mọi player đã sẵn sàng và có ít nhất 2 người.
  bool get allReady => players.length >= 2 && players.every((p) => p.isReady);
}
