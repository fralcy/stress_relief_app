import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'lan_message.dart';

/// WebSocket server chạy trên Android/desktop (host mode).
///
/// Dùng [dart:io] HttpServer + WebSocketTransformer.
/// Mỗi client kết nối được gán một [clientId] nội bộ duy nhất.
///
/// Usage:
/// ```dart
/// final server = LanServer();
/// await server.start(port: 8765);
/// server.events.listen((event) { ... });
/// server.broadcast(LanMessage.data('host', {'key': 'value'}));
/// await server.stop();
/// ```
class LanServer {
  HttpServer? _server;
  int _port = 8765;

  final Map<String, WebSocket> _clients = {};
  final StreamController<LanIncomingEvent> _controller =
      StreamController<LanIncomingEvent>.broadcast();

  final _rand = Random();

  // ----------------------------------------------------------
  // Getters
  // ----------------------------------------------------------

  int get port => _port;
  bool get isRunning => _server != null;

  /// Stream các event nhận được từ bất kỳ client nào.
  Stream<LanIncomingEvent> get events => _controller.stream;

  /// Danh sách clientId của các kết nối hiện tại.
  List<String> get connectedClientIds => List.unmodifiable(_clients.keys);

  // ----------------------------------------------------------
  // Lifecycle
  // ----------------------------------------------------------

  /// Khởi động WebSocket server trên [port].
  /// No-op nếu server đang chạy.
  Future<void> start({int port = 8765}) async {
    if (_server != null) return;
    _port = port;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
    _server!.listen(_handleRequest);
  }

  /// Đóng tất cả kết nối và dừng server.
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

  void dispose() {
    stop();
    _controller.close();
  }

  // ----------------------------------------------------------
  // Messaging
  // ----------------------------------------------------------

  /// Gửi [msg] đến tất cả client đang kết nối.
  void broadcast(LanMessage msg) {
    final json = msg.toJsonString();
    for (final entry in _clients.entries) {
      _safeSend(entry.key, entry.value, json);
    }
  }

  /// Gửi [msg] đến một client cụ thể theo [clientId].
  void sendTo(String clientId, LanMessage msg) {
    final ws = _clients[clientId];
    if (ws != null) {
      _safeSend(clientId, ws, msg.toJsonString());
    }
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
