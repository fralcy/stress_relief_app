import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'lan_message.dart';
import 'lan_transport.dart';

/// WebSocket server for Android/desktop (host mode).
///
/// Uses [dart:io] HttpServer + WebSocketTransformer.
/// Each connecting client is assigned a unique internal [clientId].
class LanServer implements LanServerBase {
  HttpServer? _server;
  int _port = 8765;

  final Map<String, WebSocket> _clients = {};
  final StreamController<LanIncomingEvent> _controller =
      StreamController<LanIncomingEvent>.broadcast();

  final _rand = Random();

  // ----------------------------------------------------------
  // Getters
  // ----------------------------------------------------------

  @override
  int get port => _port;

  @override
  bool get isRunning => _server != null;

  @override
  LanTransportType get type => LanTransportType.websocket;

  @override
  Stream<LanIncomingEvent> get events => _controller.stream;

  @override
  List<String> get connectedClientIds => List.unmodifiable(_clients.keys);

  // ----------------------------------------------------------
  // Lifecycle
  // ----------------------------------------------------------

  /// Start WebSocket server on [port]. [roomId] is ignored on Android.
  @override
  Future<void> start({int port = 8765, String? roomId}) async {
    if (_server != null) return;
    _port = port;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
    _server!.listen(_handleRequest);
  }

  @override
  Future<void> stop() async {
    for (final ws in _clients.values) {
      try {
        await ws.close();
      } catch (_) {}
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }

  @override
  void dispose() {
    stop();
    _controller.close();
  }

  // ----------------------------------------------------------
  // Messaging
  // ----------------------------------------------------------

  @override
  void broadcast(LanMessage msg) {
    final json = msg.toJsonString();
    for (final entry in _clients.entries) {
      _safeSend(entry.key, entry.value, json);
    }
  }

  @override
  void sendTo(String clientId, LanMessage msg) {
    final ws = _clients[clientId];
    if (ws != null) _safeSend(clientId, ws, msg.toJsonString());
  }

  @override
  Future<void> closeClient(String clientId) async {
    final ws = _clients[clientId];
    if (ws == null) return;
    _clients.remove(clientId);
    try {
      await ws.close(WebSocketStatus.goingAway);
    } catch (_) {}
  }

  // ----------------------------------------------------------
  // Internal helpers
  // ----------------------------------------------------------

  Future<void> _handleRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final WebSocket ws;
    try {
      ws = await WebSocketTransformer.upgrade(request);
    } catch (_) {
      return;
    }

    // Detect dead clients within ~10 s without manual heartbeat code.
    ws.pingInterval = const Duration(seconds: 5);

    final clientId = _generateClientId();
    _clients[clientId] = ws;

    ws.listen(
      (data) {
        if (data is String) {
          final msg = LanMessage.tryParse(data);
          if (msg != null && !_controller.isClosed) {
            _controller.add(LanIncomingEvent(clientId: clientId, message: msg));
          }
        }
      },
      onDone: () => _clients.remove(clientId),
      onError: (_) => _clients.remove(clientId),
      cancelOnError: true,
    );
  }

  void _safeSend(String clientId, WebSocket ws, String json) {
    try {
      ws.add(json);
    } catch (_) {
      _clients.remove(clientId);
    }
  }

  String _generateClientId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final suffix = _rand.nextInt(9999).toString().padLeft(4, '0');
    return 'client_${ts}_$suffix';
  }
}
