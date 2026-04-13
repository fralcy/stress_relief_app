import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'lan_message.dart';
import 'lan_transport.dart';

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
// LanClient — WebSocket client (Android)
// ============================================================

/// WebSocket client for connecting to a [LanServer] on Android.
///
/// Connects via `ws://$host:$port`.
class LanClient implements LanClientBase {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  LanClientStatus _status = LanClientStatus.disconnected;
  String? _lastError;
  bool _intentionalDisconnect = false;

  final StreamController<LanMessage> _controller =
      StreamController<LanMessage>.broadcast();

  final StreamController<void> _disconnectController =
      StreamController<void>.broadcast();

  // ----------------------------------------------------------
  // Getters
  // ----------------------------------------------------------

  LanClientStatus get status => _status;

  @override
  bool get isConnected => _status == LanClientStatus.connected;

  @override
  String? get lastError => _lastError;

  @override
  Stream<LanMessage> get messages => _controller.stream;

  @override
  Stream<void> get onDisconnected => _disconnectController.stream;

  // ----------------------------------------------------------
  // Connection
  // ----------------------------------------------------------

  @override
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

  /// No-op on Android — WebRTC room IDs are only used by the web client.
  @override
  Future<void> connectByRoomId(String roomId) async {}

  @override
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

  @override
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
    if (wasConnected &&
        !_intentionalDisconnect &&
        !_disconnectController.isClosed) {
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

  @override
  void dispose() {
    disconnect();
    _controller.close();
    _disconnectController.close();
  }
}
