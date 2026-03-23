import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/lan/lan_service.dart';
import '../utils/lan/lan_message.dart';
import '../utils/lan/lan_discovery.dart';

// ============================================================
// LanConnectionStatus
// ============================================================

enum LanConnectionStatus {
  /// Chưa kết nối, không hoạt động.
  idle,

  /// Đang chạy WebSocket server và quảng bá UDP (host mode).
  hosting,

  /// Đang quét mạng để tìm host.
  searching,

  /// Đang thực hiện WebSocket handshake.
  connecting,

  /// Đã kết nối thành công (host đang có client, hoặc client đã vào host).
  connected,

  /// Có lỗi xảy ra. Xem [LanProvider.errorMessage].
  error,
}

// ============================================================
// LanProvider
// ============================================================

/// ChangeNotifier wrapper trên [LanService] để UI có thể watch state.
///
/// Usage:
/// ```dart
/// // Trong widget:
/// final lan = context.watch<LanProvider>();
/// Text(lan.status.name);
///
/// // Bắt đầu host:
/// await context.read<LanProvider>().startHosting();
///
/// // Lắng nghe event:
/// lan.incomingEvents.listen((e) { ... });
/// ```
class LanProvider extends ChangeNotifier {
  LanConnectionStatus _status = LanConnectionStatus.idle;
  String? _errorMessage;
  List<LanHostInfo> _discoveredHosts = [];

  // ----------------------------------------------------------
  // Getters
  // ----------------------------------------------------------

  LanConnectionStatus get status => _status;
  LanRole get role => LanService().role;
  bool get isActive => LanService().isActive;

  /// Danh sách clientId đang kết nối (host only).
  List<String> get connectedPeers => LanService().connectedClientIds;

  /// Danh sách host tìm được sau [scanForHosts].
  List<LanHostInfo> get discoveredHosts => _discoveredHosts;

  /// Message lỗi gần nhất. Null nếu không có lỗi.
  String? get errorMessage => _errorMessage;

  /// Địa chỉ IP WiFi của thiết bị (host: dùng để hiển thị "Join at: ...").
  String? get localIp => LanService().localIp;

  /// Unified stream event — delegate thẳng từ [LanService].
  Stream<LanIncomingEvent> get incomingEvents => LanService().incomingEvents;

  // ----------------------------------------------------------
  // Host actions
  // ----------------------------------------------------------

  /// Khởi động host mode.
  /// No-op trên web (kIsWeb).
  Future<void> startHosting({String? displayName, int avatarIndex = 0}) async {
    if (kIsWeb) return;
    _setStatus(LanConnectionStatus.hosting);
    try {
      await LanService().startHosting(displayName: displayName, avatarIndex: avatarIndex);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Dừng host mode.
  Future<void> stopHosting() async {
    try {
      await LanService().stopHosting();
      _setStatus(LanConnectionStatus.idle);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ----------------------------------------------------------
  // Client actions
  // ----------------------------------------------------------

  /// Quét mạng LAN để tìm host.
  /// Cập nhật [discoveredHosts] sau khi scan xong.
  Future<void> scanForHosts({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    _setStatus(LanConnectionStatus.searching);
    try {
      _discoveredHosts = await LanService().discoverHosts(timeout: timeout);
      _setStatus(LanConnectionStatus.idle);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Kết nối đến [host] từ kết quả [scanForHosts].
  Future<void> connect(LanHostInfo host) async {
    await _doConnect(() => LanService().connect(host));
  }

  /// Kết nối trực tiếp bằng IP và port (dùng cho PWA — nhập tay).
  Future<void> connectByAddress(String ip, int port) async {
    await _doConnect(() => LanService().connectByAddress(ip, port));
  }

  Future<void> _doConnect(Future<void> Function() connectFn) async {
    _setStatus(LanConnectionStatus.connecting);
    try {
      await connectFn();
      if (LanService().isActive) {
        _setStatus(LanConnectionStatus.connected);
      } else {
        _setError('Connection failed');
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Ngắt kết nối khỏi host.
  Future<void> disconnect() async {
    try {
      await LanService().disconnect();
      _setStatus(LanConnectionStatus.idle);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ----------------------------------------------------------
  // Messaging (delegate to LanService)
  // ----------------------------------------------------------

  void sendMessage(LanMessage msg) => LanService().sendMessage(msg);
  void broadcastMessage(LanMessage msg) => LanService().broadcastMessage(msg);

  // ----------------------------------------------------------
  // Internal helpers
  // ----------------------------------------------------------

  void _setStatus(LanConnectionStatus status) {
    _status = status;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = LanConnectionStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
