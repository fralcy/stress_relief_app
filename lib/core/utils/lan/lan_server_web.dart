import 'dart:async';
import 'lan_message.dart';

/// Stub — LanServer không khả dụng trên web (PWA chỉ là client mode).
///
/// Tất cả method là no-op để tránh compile error khi build web.
/// [LanService] dùng kIsWeb guard để không gọi start() trên browser.
class LanServer {
  int get port => 0;
  bool get isRunning => false;
  Stream<LanIncomingEvent> get events => const Stream.empty();
  List<String> get connectedClientIds => const [];

  Future<void> start({int port = 8765}) async {}
  Future<void> stop() async {}
  void broadcast(LanMessage msg) {}
  void sendTo(String clientId, LanMessage msg) {}
  void dispose() {}
}
