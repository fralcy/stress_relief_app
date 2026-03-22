import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'lan_message.dart';

// ============================================================
// LanClientStatus
// ============================================================

enum LanClientStatus {
  disconnected,
  connecting,
  connected,
  error,
}

// ============================================================
// LanClient — WebSocket client (Android + PWA)
// ============================================================

/// Kết nối đến một LanServer WebSocket.
///
/// Dùng [web_socket_channel] — hoạt động trên cả Android và web/PWA.
/// Kết nối qua URI `ws://$host:$port`.
///
/// Usage:
/// ```dart
/// final client = LanClient();
/// await client.connect('192.168.1.100', 8765);
/// client.messages.listen((msg) { ... });
/// client.send(LanMessage.hello('device_id', displayName: 'My Phone'));
/// await client.disconnect();
/// ```
class LanClient {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  LanClientStatus _status = LanClientStatus.disconnected;
  String? _lastError;
  bool _intentionalDisconnect = false;

  final StreamController<LanMessage> _controller =
      StreamController<LanMessage>.broadcast();

  /// Fires once when the connection is lost unexpectedly (not via [disconnect]).
  final StreamController<void> _disconnectController =
      StreamController<void>.broadcast();

  // ----------------------------------------------------------
  // Getters
  // ----------------------------------------------------------

  LanClientStatus get status => _status;
  bool get isConnected => _status == LanClientStatus.connected;

  /// Message lỗi cuối cùng (nếu có). Null khi không có lỗi.
  String? get lastError => _lastError;

  /// Stream các [LanMessage] nhận được từ server (host).
  Stream<LanMessage> get messages => _controller.stream;

  /// Fires once when the connection drops unexpectedly (not via [disconnect]).
  Stream<void> get onDisconnected => _disconnectController.stream;

  // ----------------------------------------------------------
  // Connection
  // ----------------------------------------------------------

  /// Kết nối đến host tại [host]:[port].
  ///
  /// No-op nếu đang connecting hoặc đã connected.
  /// Throws nếu [host] hoặc [port] không hợp lệ.
  Future<void> connect(String host, int port) async {
    if (_status == LanClientStatus.connecting ||
        _status == LanClientStatus.connected) {
      return;
    }

    _status = LanClientStatus.connecting;
    _lastError = null;

    try {
      final uri = Uri.parse('ws://$host:$port');
      _channel = WebSocketChannel.connect(uri);

      // Đợi kết nối được thiết lập (hoặc throw nếu lỗi)
      await _channel!.ready;

      _status = LanClientStatus.connected;

      _sub = _channel!.stream.listen(
        _onData,
        onDone: _onDone,
        onError: _onError,
        cancelOnError: false,
      );
    } catch (e) {
      _status = LanClientStatus.error;
      _lastError = e.toString();
      _channel = null;
    }
  }

  /// Ngắt kết nối và giải phóng resource.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _status = LanClientStatus.disconnected;
    _lastError = null;
    _intentionalDisconnect = false;
  }

  // ----------------------------------------------------------
  // Messaging
  // ----------------------------------------------------------

  /// Gửi [msg] đến server (host).
  /// No-op nếu chưa kết nối.
  void send(LanMessage msg) {
    if (!isConnected || _channel == null) return;
    try {
      _channel!.sink.add(msg.toJsonString());
    } catch (e) {
      _status = LanClientStatus.error;
      _lastError = e.toString();
    }
  }

  // ----------------------------------------------------------
  // Internal handlers
  // ----------------------------------------------------------

  void _onData(dynamic data) {
    if (data is! String) return;
    final msg = LanMessage.tryParse(data);
    if (msg != null && !_controller.isClosed) {
      _controller.add(msg);
    }
  }

  void _onDone() {
    _sub = null;
    _channel = null;
    final wasConnected = _status == LanClientStatus.connected;
    _status = LanClientStatus.disconnected;
    if (wasConnected && !_intentionalDisconnect && !_disconnectController.isClosed) {
      _disconnectController.add(null);
    }
  }

  void _onError(Object error) {
    _status = LanClientStatus.error;
    _lastError = error.toString();
    _sub = null;
    _channel = null;
    if (!_intentionalDisconnect && !_disconnectController.isClosed) {
      _disconnectController.add(null);
    }
  }

  // ----------------------------------------------------------
  // Dispose
  // ----------------------------------------------------------

  void dispose() {
    disconnect();
    _controller.close();
    _disconnectController.close();
  }
}
