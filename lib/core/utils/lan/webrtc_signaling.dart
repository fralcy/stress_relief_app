import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// ============================================================
// WebRtcRoomInfo
// ============================================================

/// Metadata for a live WebRTC room fetched from Firebase RTDB.
class WebRtcRoomInfo {
  final String roomId;
  final String displayName;
  final int avatarIndex;
  final int createdAt;

  const WebRtcRoomInfo({
    required this.roomId,
    required this.displayName,
    required this.avatarIndex,
    required this.createdAt,
  });

  factory WebRtcRoomInfo.fromMap(String roomId, Map<dynamic, dynamic> map) {
    final hostInfo = map['host_info'] as Map? ?? {};
    return WebRtcRoomInfo(
      roomId: roomId,
      displayName: hostInfo['displayName'] as String? ?? 'Unknown',
      avatarIndex: (hostInfo['avatarIndex'] as num?)?.toInt() ?? 0,
      createdAt: (hostInfo['createdAt'] as num?)?.toInt() ?? 0,
    );
  }
}

// ============================================================
// WebRtcSignaling
// ============================================================

/// Handles Firebase RTDB signaling for a single WebRTC peer connection.
///
/// One instance per (roomId, clientPeerId) pair.
/// - Host creates one instance for every joining client.
/// - Client creates one instance per connection attempt.
///
/// ICE candidate buffering:
/// Trickle-ICE candidates may arrive on RTDB before [setRemoteDescription]
/// has been called. [_handleIncomingCandidate] buffers them; calling
/// [onRemoteDescriptionSet] flushes the buffer in order.
class WebRtcSignaling {
  final String roomId;
  final String clientPeerId;
  final bool isHost;

  WebRtcSignaling({
    required this.roomId,
    required this.clientPeerId,
    required this.isHost,
  });

  // ── ICE buffering ─────────────────────────────────────────

  bool _remoteDescSet = false;
  final List<RTCIceCandidate> _pending = [];
  RTCPeerConnection? _pc;
  final List<StreamSubscription> _subs = [];

  // ── Attachment ────────────────────────────────────────────

  /// Attach the [RTCPeerConnection] before calling any listen/write methods.
  void attach(RTCPeerConnection pc) => _pc = pc;

  /// Buffer a candidate or apply it immediately if remote desc is already set.
  void handleIncomingCandidate(RTCIceCandidate c) {
    if (_remoteDescSet) {
      _pc?.addCandidate(c);
    } else {
      _pending.add(c);
    }
  }

  /// Call after [RTCPeerConnection.setRemoteDescription] to flush buffered
  /// ICE candidates.
  Future<void> onRemoteDescriptionSet() async {
    _remoteDescSet = true;
    for (final c in _pending) {
      await _pc?.addCandidate(c);
    }
    _pending.clear();
  }

  // ── RTDB path helpers ─────────────────────────────────────

  DatabaseReference get _peerRef =>
      FirebaseDatabase.instance.ref('lan_rooms/$roomId/peers/$clientPeerId');

  // ── Host-side operations ──────────────────────────────────

  /// Returns a [Stream] that emits once when the client's offer is written
  /// to RTDB. Completes after the first value.
  Stream<RTCSessionDescription> watchForOffer() {
    final controller = StreamController<RTCSessionDescription>.broadcast();
    final sub = _peerRef.child('offer').onValue.listen((event) {
      final val = event.snapshot.value;
      if (val == null) return;
      final map = Map<String, dynamic>.from(val as Map);
      final sdp = RTCSessionDescription(
        map['sdp'] as String,
        map['type'] as String,
      );
      if (!controller.isClosed) {
        controller.add(sdp);
        controller.close();
      }
    });
    _subs.add(sub);
    return controller.stream;
  }

  /// Writes the host's answer to RTDB.
  Future<void> writeAnswer(RTCSessionDescription answer) async {
    await _peerRef.child('answer').set({
      'sdp': answer.sdp,
      'type': answer.type,
    });
  }

  /// Writes a single ICE candidate from the host side.
  Future<void> addHostIceCandidate(RTCIceCandidate candidate) async {
    await _peerRef.child('host_ice').push().set({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  /// Subscribes to the client's ICE candidates on RTDB.
  /// Calls [onCandidate] (via [handleIncomingCandidate]) for each entry.
  StreamSubscription listenClientIce(
      void Function(RTCIceCandidate) onCandidate) {
    final sub = _peerRef.child('client_ice').onChildAdded.listen((event) {
      final val = event.snapshot.value;
      if (val == null) return;
      final map = Map<String, dynamic>.from(val as Map);
      final c = RTCIceCandidate(
        map['candidate'] as String?,
        map['sdpMid'] as String?,
        (map['sdpMLineIndex'] as num?)?.toInt(),
      );
      onCandidate(c);
    });
    _subs.add(sub);
    return sub;
  }

  // ── Client-side operations ────────────────────────────────

  /// Writes the client's offer to RTDB.
  Future<void> writeOffer(RTCSessionDescription offer) async {
    await _peerRef.child('offer').set({
      'sdp': offer.sdp,
      'type': offer.type,
    });
  }

  /// Returns a [Stream] that emits once when the host's answer arrives.
  Stream<RTCSessionDescription> watchForAnswer() {
    final controller = StreamController<RTCSessionDescription>.broadcast();
    final sub = _peerRef.child('answer').onValue.listen((event) {
      final val = event.snapshot.value;
      if (val == null) return;
      final map = Map<String, dynamic>.from(val as Map);
      final sdp = RTCSessionDescription(
        map['sdp'] as String,
        map['type'] as String,
      );
      if (!controller.isClosed) {
        controller.add(sdp);
        controller.close();
      }
    });
    _subs.add(sub);
    return controller.stream;
  }

  /// Writes a single ICE candidate from the client side.
  Future<void> addClientIceCandidate(RTCIceCandidate candidate) async {
    await _peerRef.child('client_ice').push().set({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  /// Subscribes to the host's ICE candidates on RTDB.
  StreamSubscription listenHostIce(void Function(RTCIceCandidate) onCandidate) {
    final sub = _peerRef.child('host_ice').onChildAdded.listen((event) {
      final val = event.snapshot.value;
      if (val == null) return;
      final map = Map<String, dynamic>.from(val as Map);
      final c = RTCIceCandidate(
        map['candidate'] as String?,
        map['sdpMid'] as String?,
        (map['sdpMLineIndex'] as num?)?.toInt(),
      );
      onCandidate(c);
    });
    _subs.add(sub);
    return sub;
  }

  // ── Cleanup ───────────────────────────────────────────────

  /// Cancel all RTDB subscriptions for this peer.
  Future<void> close() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    _pending.clear();
    _pc = null;
  }

  // ── Static room management ────────────────────────────────

  /// Write host metadata to RTDB when a PWA starts hosting.
  static Future<void> writeHostInfo(
    String roomId, {
    required String displayName,
    required int avatarIndex,
    required String uid,
  }) async {
    await FirebaseDatabase.instance.ref('lan_rooms/$roomId/host_info').set({
      'displayName': displayName,
      'avatarIndex': avatarIndex,
      'uid': uid,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Register a Firebase onDisconnect() hook that auto-deletes the room
  /// if the host tab crashes or is closed without calling [deleteRoom].
  static Future<void> registerHostDisconnect(String roomId) async {
    await FirebaseDatabase.instance
        .ref('lan_rooms/$roomId')
        .onDisconnect()
        .remove();
  }

  /// Explicitly delete a room from RTDB (called on clean stopHosting).
  static Future<void> deleteRoom(String roomId) async {
    await FirebaseDatabase.instance.ref('lan_rooms/$roomId').remove();
  }

  /// One-shot read of all active rooms.
  static Future<List<WebRtcRoomInfo>> fetchRooms() async {
    final snapshot =
        await FirebaseDatabase.instance.ref('lan_rooms').get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    return map.entries
        .map((e) => WebRtcRoomInfo.fromMap(
              e.key,
              Map<dynamic, dynamic>.from(e.value as Map),
            ))
        .toList();
  }

  /// Live stream of active rooms — used by UI for real-time room list.
  ///
  /// Filters out entries older than 30 minutes and the caller's own [currentUid].
  static Stream<List<WebRtcRoomInfo>> roomStream({required String currentUid}) {
    return FirebaseDatabase.instance
        .ref('lan_rooms')
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];

      final now = DateTime.now().millisecondsSinceEpoch;
      const thirtyMin = 30 * 60 * 1000;

      final map = Map<String, dynamic>.from(event.snapshot.value as Map);
      final rooms = <WebRtcRoomInfo>[];
      for (final entry in map.entries) {
        final info = WebRtcRoomInfo.fromMap(
          entry.key,
          Map<dynamic, dynamic>.from(entry.value as Map),
        );
        // Filter own room and stale entries
        final hostUid =
            ((entry.value as Map)['host_info'] as Map?)?['uid'] as String?;
        if (hostUid == currentUid) continue;
        if (now - info.createdAt > thirtyMin) continue;
        rooms.add(info);
      }
      return rooms;
    });
  }

  /// Remove stale rooms older than 30 minutes (fallback GC).
  static Future<void> pruneStaleRooms() async {
    final snapshot =
        await FirebaseDatabase.instance.ref('lan_rooms').get();
    if (!snapshot.exists || snapshot.value == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    const thirtyMin = 30 * 60 * 1000;
    final map = Map<String, dynamic>.from(snapshot.value as Map);

    for (final entry in map.entries) {
      final hostInfo =
          ((entry.value as Map)['host_info'] as Map?);
      final createdAt = (hostInfo?['createdAt'] as num?)?.toInt() ?? 0;
      if (now - createdAt > thirtyMin) {
        await FirebaseDatabase.instance
            .ref('lan_rooms/${entry.key}')
            .remove();
      }
    }
  }
}
