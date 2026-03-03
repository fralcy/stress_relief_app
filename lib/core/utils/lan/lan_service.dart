import 'dart:async';
import 'package:flutter/foundation.dart';
import 'lan_message.dart';
import 'lan_server.dart';
import 'lan_client.dart';
import 'lan_discovery.dart';

// ============================================================
// LanRole
// ============================================================

enum LanRole {
  /// Chưa kết nối, không ở vai trò nào.
  none,

  /// Thiết bị này là host — đang chạy WebSocket server.
  host,

  /// Thiết bị này là client — đang kết nối đến một host.
  client,
}

// ============================================================
// LanService — singleton orchestrator
// ============================================================

/// Điều phối toàn bộ LAN networking: discovery, server, client.
///
/// Singleton pattern giống [DataManager], [SfxService].
/// Sống suốt vòng đời app — không cần khởi tạo trước.
///
/// Usage (host):
/// ```dart
/// await LanService().startHosting(displayName: 'My Phone');
/// LanService().incomingEvents.listen((e) { ... });
/// LanService().broadcastMessage(LanMessage.data('host', {'key': 'val'}));
/// await LanService().stopHosting();
/// ```
///
/// Usage (client — Android):
/// ```dart
/// final hosts = await LanService().discoverHosts();
/// await LanService().connect(hosts.first);
/// LanService().incomingEvents.listen((e) { ... });
/// LanService().sendMessage(LanMessage.data('me', {'action': 'join'}));
/// await LanService().disconnect();
/// ```
///
/// Usage (client — PWA):
/// ```dart
/// await LanService().connectByAddress('192.168.1.100', 8765);
/// ```
class LanService {
  static final LanService _instance = LanService._internal();
  factory LanService() => _instance;
  LanService._internal();

  final _server = LanServer();
  final _client = LanClient();
  final _discovery = LanDiscovery();

  LanRole _role = LanRole.none;
  String? _localIp;

  StreamSubscription? _serverSub;
  StreamSubscription? _clientSub;

  // Unified stream tồn tại suốt vòng đời app (không close)
  final StreamController<LanIncomingEvent> _incomingController =
      StreamController<LanIncomingEvent>.broadcast();

  // ----------------------------------------------------------
  // Getters
  // ----------------------------------------------------------

  LanRole get role => _role;

  /// `true` nếu server đang chạy (host) hoặc client đang kết nối.
  bool get isActive {
    if (_role == LanRole.host) return _server.isRunning;
    if (_role == LanRole.client) return _client.isConnected;
    return false;
  }

  /// Danh sách clientId đang kết nối (host only).
  List<String> get connectedClientIds => _server.connectedClientIds;

  /// Địa chỉ IP WiFi của thiết bị này (được set khi startHosting).
  String? get localIp => _localIp;

  /// Unified stream nhận tất cả event từ server hoặc client.
  ///
  /// Trên host: mỗi event có [LanIncomingEvent.clientId] là UUID của client.
  /// Trên client: mỗi event có [LanIncomingEvent.clientId] == `'host'`.
  Stream<LanIncomingEvent> get incomingEvents => _incomingController.stream;

  // ----------------------------------------------------------
  // Host API (Android only — no-op nếu kIsWeb)
  // ----------------------------------------------------------

  /// Bắt đầu host: khởi động WebSocket server và quảng bá UDP.
  ///
  /// Nếu đang ở role khác, tự động dừng trước.
  /// No-op trên web (kIsWeb).
  Future<void> startHosting({
    String? displayName,
    int port = 8765,
  }) async {
    if (kIsWeb) return;
    await _resetRole();

    _localIp = await LanDiscovery.getLocalIp();
    final name = displayName ?? _localIp ?? 'PeacePal Host';

    await _server.start(port: port);
    await _discovery.startAdvertising(name, port);
    _role = LanRole.host;

    // Pipe server events vào unified stream
    _serverSub = _server.events.listen((event) {
      if (!_incomingController.isClosed) {
        _incomingController.add(event);
      }
    });
  }

  /// Dừng host và giải phóng resource.
  Future<void> stopHosting() async {
    if (_role != LanRole.host) return;
    await _serverSub?.cancel();
    _serverSub = null;
    await _discovery.stopAdvertising();
    await _server.stop();
    _role = LanRole.none;
  }

  // ----------------------------------------------------------
  // Client API (Android + PWA)
  // ----------------------------------------------------------

  /// Quét mạng LAN để tìm host đang quảng bá.
  ///
  /// Trả về danh sách rỗng trên web (PWA không hỗ trợ UDP broadcast).
  Future<List<LanHostInfo>> discoverHosts({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (kIsWeb) return const [];
    return _discovery.scanForHosts(timeout: timeout);
  }

  /// Kết nối đến host từ kết quả [discoverHosts].
  Future<void> connect(LanHostInfo host) async {
    await connectByAddress(host.ip, host.wsPort);
  }

  /// Kết nối trực tiếp bằng IP và port — dùng cho PWA (nhập tay).
  ///
  /// Nếu đang ở role khác, tự động dừng trước.
  Future<void> connectByAddress(String ip, int port) async {
    await _resetRole();
    await _client.connect(ip, port);

    if (!_client.isConnected) return; // connect thất bại

    _role = LanRole.client;

    // Wrap LanMessage thành LanIncomingEvent với clientId = 'host'
    _clientSub = _client.messages.listen((msg) {
      if (!_incomingController.isClosed) {
        _incomingController.add(
          LanIncomingEvent(clientId: 'host', message: msg),
        );
      }
    });
  }

  /// Ngắt kết nối khỏi host.
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

  /// Gửi [msg]:
  /// - Host: broadcast đến tất cả, hoặc [sendTo] nếu [LanMessage.targetId] != null.
  /// - Client: gửi đến host.
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

  /// Broadcast [msg] đến tất cả client (host only).
  void broadcastMessage(LanMessage msg) {
    if (_role == LanRole.host) {
      _server.broadcast(msg);
    }
  }

  // ----------------------------------------------------------
  // Internal helpers
  // ----------------------------------------------------------

  /// Dừng role hiện tại trước khi chuyển sang role mới.
  Future<void> _resetRole() async {
    if (_role == LanRole.host) await stopHosting();
    if (_role == LanRole.client) await disconnect();
  }
}
