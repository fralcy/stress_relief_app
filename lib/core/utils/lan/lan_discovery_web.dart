import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'lan_host_info.dart';
import 'webrtc_signaling.dart';

// ============================================================
// LanDiscovery — Firebase RTDB room discovery (PWA)
// ============================================================

/// PWA implementation of LAN discovery via Firebase RTDB.
///
/// Replaces UDP broadcast (not available in browsers).
/// - Host: writes room metadata to RTDB and generates a short room ID.
/// - Client: fetches the live room list from RTDB; also supports manual
///   room ID entry as a fallback.
///
/// [LanHostInfo.ip] is repurposed to carry the roomId string on web.
/// [LanHostInfo.wsPort] is always 0 on web (signals "webrtc mode" to
/// [LanService.connectByAddress]).
class LanDiscovery {
  static const int discoveryPort = 8766; // kept for API compat, unused on web

  String? _currentRoomId;

  /// The room ID currently being advertised. Null when not hosting.
  String? get advertisedRoomId => _currentRoomId;

  // ----------------------------------------------------------
  // Host-side
  // ----------------------------------------------------------

  /// Write host metadata to RTDB and store the generated room ID.
  Future<void> startAdvertising(
    String displayName,
    int wsPort, {
    int avatarIndex = 0,
  }) async {
    _currentRoomId = generateRoomId(displayName);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    await WebRtcSignaling.writeHostInfo(
      _currentRoomId!,
      displayName: displayName,
      avatarIndex: avatarIndex,
      uid: uid,
    );
  }

  /// Delete the RTDB room entry when the host stops.
  Future<void> stopAdvertising() async {
    if (_currentRoomId != null) {
      await WebRtcSignaling.deleteRoom(_currentRoomId!);
      _currentRoomId = null;
    }
  }

  // ----------------------------------------------------------
  // Client-side
  // ----------------------------------------------------------

  /// One-shot fetch of active rooms from RTDB.
  ///
  /// Prunes stale rooms (> 30 min old) before returning results.
  /// [LanHostInfo.ip] carries the roomId; [wsPort] is 0.
  Future<List<LanHostInfo>> scanForHosts({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    await WebRtcSignaling.pruneStaleRooms();
    final rooms = await WebRtcSignaling.fetchRooms();
    return rooms
        .map(
          (r) => LanHostInfo(
            ip: r.roomId, // roomId stored in ip field
            wsPort: 0,
            displayName: r.displayName,
            avatarIndex: r.avatarIndex,
          ),
        )
        .toList();
  }

  // ----------------------------------------------------------
  // Room ID generation
  // ----------------------------------------------------------

  /// Generates a short, human-readable room ID.
  ///
  /// Format: `pp-{slug}-{suffix}` e.g. `pp-thinh-4271`
  /// - slug: displayName lowercased, ASCII a–z only, max 8 chars
  /// - suffix: 4-digit number derived from current timestamp
  ///   (browser security policy blocks local IP access)
  static String generateRoomId(String displayName) {
    final slug = displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z]'), '');
    final clamped =
        slug.isEmpty ? 'host' : slug.substring(0, slug.length.clamp(0, 8));
    final suffix =
        (DateTime.now().millisecondsSinceEpoch % 9000 + 1000).toString();
    return 'pp-$clamped-$suffix';
  }

  // ----------------------------------------------------------
  // IP helper (no-op on web)
  // ----------------------------------------------------------

  /// Always returns null on web — browser security policy blocks local IP.
  static Future<String?> getLocalIp() async => null;
}
