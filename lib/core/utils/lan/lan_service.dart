import 'dart:async';
import 'package:flutter/foundation.dart';
import 'lan_message.dart';
import 'lan_server.dart';
import 'lan_client.dart';
import 'lan_discovery.dart';
import 'lan_transport.dart';

// ============================================================
// LanRole
// ============================================================

enum LanRole {
  /// Not connected, no active role.
  none,

  /// This device is the host.
  host,

  /// This device is a client connected to a host.
  client,
}

// ============================================================
// LanService — singleton orchestrator
// ============================================================

/// Orchestrates LAN networking: discovery, server, client.
///
/// Singleton — lives for the entire app lifecycle.
///
/// On Android: WebSocket transport (UDP discovery + WS server/client).
/// On PWA: WebRTC transport (Firebase RTDB discovery + WebRTC host/client).
///
/// The game protocol layer ([GameMessage], [GameRoomProvider]) is transport-
/// agnostic — it only sees [incomingEvents] and calls [sendMessage].
///
/// Usage (Android host):
/// ```dart
/// await LanService().startHosting(displayName: 'My Phone');
/// LanService().incomingEvents.listen((e) { ... });
/// await LanService().stopHosting();
/// ```
///
/// Usage (PWA host):
/// ```dart
/// await LanService().startHosting(displayName: 'Thinh');
/// print(LanService().roomId); // e.g. 'pp-thinh-4271'
/// ```
///
/// Usage (PWA client):
/// ```dart
/// await LanService().connectByRoomId('pp-thinh-4271');
/// ```
class LanService {
  static final LanService _instance = LanService._internal();
  factory LanService() => _instance;
  LanService._internal();

  // Typed as base classes so no dynamic casts are needed anywhere.
  final LanServerBase _server = LanServer();
  final LanClientBase _client = LanClient();
  final _discovery = LanDiscovery();

  LanRole _role = LanRole.none;
  String? _localIp;
  String? _lastHostIp;
  int _lastHostPort = 8765;
  String? _roomId; // WebRTC room ID (PWA host mode only)

  StreamSubscription? _serverSub;
  StreamSubscription? _clientSub;

  // Unified stream — lives for the entire app lifetime (never closed).
  final StreamController<LanIncomingEvent> _incomingController =
      StreamController<LanIncomingEvent>.broadcast();

  // ----------------------------------------------------------
  // Getters
  // ----------------------------------------------------------

  LanRole get role => _role;

  /// Transport type in use (websocket on Android, webrtc on PWA).
  LanTransportType get transportType => _server.type;

  /// True if the server is running (host) or client is connected.
  bool get isActive {
    if (_role == LanRole.host) return _server.isRunning;
    if (_role == LanRole.client) return _client.isConnected;
    return false;
  }

  /// Connected client IDs (host only).
  List<String> get connectedClientIds => _server.connectedClientIds;

  /// Local WiFi IP (Android host only; null on PWA).
  String? get localIp => _localIp;

  /// Last host IP / room ID this device connected to as a client.
  String? get lastHostIp => _lastHostIp;
  int get lastHostPort => _lastHostPort;

  /// WebRTC room ID (PWA host mode only; null otherwise).
  String? get roomId => _roomId;

  /// Fires once when the client connection drops unexpectedly.
  Stream<void> get connectionLost => _client.onDisconnected;

  /// Unified stream of all incoming events.
  ///
  /// Host: each event carries the internal socket/peer ID as clientId.
  /// Client: each event has clientId == 'host'.
  Stream<LanIncomingEvent> get incomingEvents => _incomingController.stream;

  // ----------------------------------------------------------
  // Host API
  // ----------------------------------------------------------

  /// Start hosting.
  ///
  /// On Android: starts WebSocket server + UDP advertising.
  /// On PWA: starts WebRTC host + writes room to Firebase RTDB.
  ///
  /// Auto-stops any previous role first.
  Future<void> startHosting({
    String? displayName,
    int avatarIndex = 0,
    int port = 8765,
  }) async {
    if (kIsWeb) {
      // ── PWA / WebRTC path ───────────────────────────────
      await _resetRole();
      final name = displayName ?? 'PeacePal Host';
      await _discovery.startAdvertising(name, 0, avatarIndex: avatarIndex);
      _roomId = _discovery.advertisedRoomId;
      await _server.start(port: 0, roomId: _roomId);
      _role = LanRole.host;
      _serverSub = _server.events.listen((event) {
        if (!_incomingController.isClosed) _incomingController.add(event);
      });
      return;
    }

    // ── Android / WebSocket path ────────────────────────────
    await _resetRole();
    _localIp = await LanDiscovery.getLocalIp();
    final name = displayName ?? _localIp ?? 'PeacePal Host';
    await _server.start(port: port);
    await _discovery.startAdvertising(name, port, avatarIndex: avatarIndex);
    _role = LanRole.host;
    _serverSub = _server.events.listen((event) {
      if (!_incomingController.isClosed) _incomingController.add(event);
    });
  }

  /// Stop hosting and release all resources.
  Future<void> stopHosting() async {
    if (_role != LanRole.host) return;
    await _serverSub?.cancel();
    _serverSub = null;
    await _discovery.stopAdvertising();
    await _server.stop();
    _roomId = null;
    _role = LanRole.none;
  }

  // ----------------------------------------------------------
  // Client API
  // ----------------------------------------------------------

  /// Scan for hosts on the LAN.
  ///
  /// Android: UDP broadcast scan.
  /// PWA: one-shot fetch of active rooms from Firebase RTDB.
  Future<List<LanHostInfo>> discoverHosts({
    Duration timeout = const Duration(seconds: 3),
  }) {
    return _discovery.scanForHosts(timeout: timeout);
  }

  /// Connect to a discovered host.
  Future<void> connect(LanHostInfo host) async {
    await connectByAddress(host.ip, host.wsPort);
  }

  /// Connect by address.
  ///
  /// On PWA, [ip] carries the room ID and [port] is 0 — automatically
  /// redirects to [connectByRoomId].
  Future<void> connectByAddress(String ip, int port) async {
    if (kIsWeb) {
      await connectByRoomId(ip);
      return;
    }
    await _resetRole();
    _lastHostIp = ip;
    _lastHostPort = port;
    await _client.connect(ip, port);
    if (!_client.isConnected) return;
    _role = LanRole.client;
    _clientSub = _client.messages.listen((msg) {
      if (!_incomingController.isClosed) {
        _incomingController.add(LanIncomingEvent(clientId: 'host', message: msg));
      }
    });
  }

  /// Connect to a PWA WebRTC host by room ID (PWA client only).
  Future<void> connectByRoomId(String roomId) async {
    if (!kIsWeb) return;
    await _resetRole();
    _lastHostIp = roomId; // reused for reconnect logic
    _lastHostPort = 0;
    await _client.connectByRoomId(roomId);
    if (!_client.isConnected) return;
    _role = LanRole.client;
    _clientSub = _client.messages.listen((msg) {
      if (!_incomingController.isClosed) {
        _incomingController.add(LanIncomingEvent(clientId: 'host', message: msg));
      }
    });
  }

  /// Disconnect from the host.
  Future<void> disconnect() async {
    if (_role != LanRole.client) return;
    await _clientSub?.cancel();
    _clientSub = null;
    await _client.disconnect();
    _role = LanRole.none;
  }

  // ----------------------------------------------------------
  // Messaging
  // ----------------------------------------------------------

  /// Send [msg]:
  /// - Host: broadcast, or unicast if [LanMessage.targetId] is set.
  /// - Client: send to host.
  void sendMessage(LanMessage msg) {
    switch (_role) {
      case LanRole.host:
        final target = msg.targetId;
        if (target != null) {
          _server.sendTo(target, msg);
        } else {
          _server.broadcast(msg);
        }
      case LanRole.client:
        _client.send(msg);
      case LanRole.none:
        break;
    }
  }

  /// Force-close a specific client by ID (host only).
  Future<void> closeClient(String socketId) => _server.closeClient(socketId);

  /// Broadcast [msg] to all clients (host only).
  void broadcastMessage(LanMessage msg) {
    if (_role == LanRole.host) _server.broadcast(msg);
  }

  // ----------------------------------------------------------
  // Internal helpers
  // ----------------------------------------------------------

  Future<void> _resetRole() async {
    if (_role == LanRole.host) await stopHosting();
    if (_role == LanRole.client) await disconnect();
  }
}
