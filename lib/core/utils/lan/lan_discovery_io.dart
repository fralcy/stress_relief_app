import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'lan_host_info.dart';

/// UDP broadcast discovery — Android/desktop only.
///
/// Protocol (UTF-8 text over UDP port 8766):
///   Client → broadcast: `PEACPAL_DISCOVER:request`
///   Host   → unicast:   `PEACPAL_DISCOVER:response:<ip>:<wsPort>:<displayName>`
///
/// [displayName] có thể chứa ký tự Unicode (Vietnamese, v.v.).
class LanDiscovery {
  static const int discoveryPort = 8766;
  static const String _requestTag = 'PEACPAL_DISCOVER:request';
  static const String _responsePrefix = 'PEACPAL_DISCOVER:response:';

  RawDatagramSocket? _advertisingSocket;

  // ----------------------------------------------------------
  // Host mode: lắng nghe request và phản hồi
  // ----------------------------------------------------------

  /// Bắt đầu quảng bá trên mạng LAN.
  ///
  /// Khi nhận được discovery request, phản hồi với thông tin
  /// IP + [wsPort] + [displayName] của thiết bị này.
  /// No-op nếu đã đang quảng bá.
  Future<void> startAdvertising(String displayName, int wsPort) async {
    if (_advertisingSocket != null) return;

    final localIp = await getLocalIp() ?? '0.0.0.0';

    _advertisingSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
    );

    _advertisingSocket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = _advertisingSocket?.receive();
      if (datagram == null) return;

      final data = utf8.decode(datagram.data, allowMalformed: true);
      if (data.trim() != _requestTag) return;

      // Phản hồi về cổng nguồn của client
      final response = '$_responsePrefix$localIp:$wsPort:$displayName';
      _advertisingSocket?.send(
        utf8.encode(response),
        datagram.address,
        datagram.port,
      );
    });
  }

  /// Dừng quảng bá.
  Future<void> stopAdvertising() async {
    _advertisingSocket?.close();
    _advertisingSocket = null;
  }

  // ----------------------------------------------------------
  // Client mode: quét host trên mạng LAN
  // ----------------------------------------------------------

  /// Gửi broadcast và thu thập phản hồi trong [timeout].
  ///
  /// Trả về danh sách host tìm thấy (không trùng lặp theo IP).
  Future<List<LanHostInfo>> scanForHosts({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final hosts = <LanHostInfo>[];
    RawDatagramSocket? socket;

    try {
      // Bind cổng bất kỳ để nhận phản hồi
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final done = Completer<void>();
      final timer = Timer(timeout, () {
        if (!done.isCompleted) done.complete();
      });

      socket.listen(
        (event) {
          if (event != RawSocketEvent.read) return;
          final datagram = socket?.receive();
          if (datagram == null) return;

          final data = utf8.decode(datagram.data, allowMalformed: true);
          if (!data.startsWith(_responsePrefix)) return;

          // Format: <ip>:<wsPort>:<displayName>
          // displayName có thể chứa ':', nên chỉ split 2 lần đầu
          final body = data.substring(_responsePrefix.length);
          final firstColon = body.indexOf(':');
          if (firstColon < 0) return;
          final secondColon = body.indexOf(':', firstColon + 1);
          if (secondColon < 0) return;

          final ip = body.substring(0, firstColon);
          final wsPort = int.tryParse(
            body.substring(firstColon + 1, secondColon),
          );
          final displayName = body.substring(secondColon + 1);

          if (wsPort == null || ip.isEmpty) return;

          if (!hosts.any((h) => h.ip == ip)) {
            hosts.add(LanHostInfo(
              ip: ip,
              wsPort: wsPort,
              displayName: displayName,
            ));
          }
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );

      // Gửi broadcast request
      socket.send(
        utf8.encode(_requestTag),
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );

      await done.future;
      timer.cancel();
    } catch (_) {
      // Trả về danh sách đã tìm được cho đến thời điểm lỗi
    } finally {
      socket?.close();
    }

    return hosts;
  }

  // ----------------------------------------------------------
  // Helper
  // ----------------------------------------------------------

  /// Lấy địa chỉ IP WiFi của thiết bị này.
  /// Trả về `null` nếu không kết nối WiFi hoặc lỗi permission.
  static Future<String?> getLocalIp() async {
    try {
      return await NetworkInfo().getWifiIP();
    } catch (_) {
      return null;
    }
  }
}
