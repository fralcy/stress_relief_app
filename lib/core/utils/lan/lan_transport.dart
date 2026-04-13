import 'dart:async';
import 'lan_message.dart';

// ============================================================
// LanTransportType
// ============================================================

/// Transport protocol in use.
///
/// UI layers check this to decide whether to show a room code (WebRTC)
/// or a local IP address (WebSocket) — avoiding repeated kIsWeb checks.
enum LanTransportType { websocket, webrtc }

// ============================================================
// LanServerBase
// ============================================================

/// Abstract base for LAN server implementations.
///
/// [LanServerIo] (WebSocket) and [LanServerWeb] (WebRTC) both implement this.
/// [LanService] holds a [LanServerBase] field so no dynamic casts are needed.
abstract class LanServerBase {
  /// The local port the server is bound to.
  /// Always 0 on WebRTC (meaningless for P2P).
  int get port;

  bool get isRunning;

  /// Transport type — lets UI decide display format without calling kIsWeb.
  LanTransportType get type;

  /// Unified stream of incoming events from all connected clients.
  Stream<LanIncomingEvent> get events;

  /// List of currently connected client IDs.
  List<String> get connectedClientIds;

  /// Start the server.
  ///
  /// [port] is used by the WebSocket implementation (Android).
  /// [roomId] is used by the WebRTC implementation (PWA) and ignored on Android.
  Future<void> start({int port, String? roomId});

  /// Stop the server and release all resources.
  Future<void> stop();

  /// Send [msg] to all connected clients.
  void broadcast(LanMessage msg);

  /// Send [msg] to a specific client identified by [clientId].
  void sendTo(String clientId, LanMessage msg);

  /// Force-close a specific client connection.
  Future<void> closeClient(String socketId);

  void dispose();
}

// ============================================================
// LanClientBase
// ============================================================

/// Abstract base for LAN client implementations.
///
/// [LanClientIo] (WebSocket) and [LanClientWeb] (WebRTC) both implement this.
abstract class LanClientBase {
  bool get isConnected;
  String? get lastError;

  /// Stream of incoming [LanMessage]s from the host.
  Stream<LanMessage> get messages;

  /// Fires once when the connection drops unexpectedly (not via [disconnect]).
  Stream<void> get onDisconnected;

  /// Connect to a WebSocket host at [host]:[port].
  /// No-op on the WebRTC implementation.
  Future<void> connect(String host, int port);

  /// Connect to a WebRTC host identified by [roomId] via Firebase RTDB signaling.
  /// No-op on the WebSocket implementation.
  Future<void> connectByRoomId(String roomId);

  /// Send [msg] to the host.
  void send(LanMessage msg);

  /// Gracefully disconnect and release resources.
  Future<void> disconnect();

  void dispose();
}
