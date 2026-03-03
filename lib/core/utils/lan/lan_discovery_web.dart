import 'dart:async';
import 'lan_host_info.dart';

/// Stub — LanDiscovery không khả dụng trên web (browser không hỗ trợ UDP).
///
/// PWA chỉ có thể là client, kết nối bằng cách nhập thủ công IP của host.
class LanDiscovery {
  static const int discoveryPort = 8766;

  Future<void> startAdvertising(String displayName, int wsPort) async {}
  Future<void> stopAdvertising() async {}

  Future<List<LanHostInfo>> scanForHosts({
    Duration timeout = const Duration(seconds: 3),
  }) async =>
      const [];

  static Future<String?> getLocalIp() async => null;
}
