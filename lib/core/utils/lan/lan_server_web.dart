import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'game_room.dart';
import 'lan_message.dart';
import 'lan_transport.dart';
import 'webrtc_signaling.dart';

// ============================================================
// LanServer — WebRTC multi-peer host (PWA)
// ============================================================

/// WebRTC host server for PWA-to-PWA LAN multiplayer.
///
/// Manages N [RTCPeerConnection]s (one per client, max [kMaxRoomPlayers]).
/// Uses Firebase RTDB for signaling. Mirrors the API of [LanServerIo] so
/// [LanService] can use it without any special-casing beyond the initial
/// `start()` call that requires a [roomId].
class LanServer implements LanServerBase {
  String? _roomId;
  bool _running = false;

  // clientPeerId → _WebRtcPeer
  final Map<String, _WebRtcPeer> _peers = {};

  final StreamController<LanIncomingEvent> _controller =
      StreamController<LanIncomingEvent>.broadcast();

  StreamSubscription? _newPeerSub;

  // ── ICE server config ─────────────────────────────────────
  static const Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  // ----------------------------------------------------------
  // LanServerBase — Getters
  // ----------------------------------------------------------

  @override
  int get port => 0; // meaningless for WebRTC

  @override
  bool get isRunning => _running;

  @override
  LanTransportType get type => LanTransportType.webrtc;

  @override
  Stream<LanIncomingEvent> get events => _controller.stream;

  @override
  List<String> get connectedClientIds =>
      _peers.entries
          .where((e) => e.value.isOpen)
          .map((e) => e.key)
          .toList();

  // ----------------------------------------------------------
  // Lifecycle
  // ----------------------------------------------------------

  /// Start the WebRTC host.
  ///
  /// [roomId] is required on web; [port] is ignored.
  /// Registers an RTDB onDisconnect hook so the room is auto-deleted
  /// if the browser tab closes unexpectedly.
  @override
  Future<void> start({int port = 8765, String? roomId}) async {
    if (_running || roomId == null) return;
    _running = true;
    _roomId = roomId;

    // Auto-delete room on unexpected disconnect (tab crash / network loss).
    await WebRtcSignaling.registerHostDisconnect(roomId);

    // Listen for new client join requests on RTDB.
    _newPeerSub = FirebaseDatabase.instance
        .ref('lan_rooms/$roomId/peers')
        .onChildAdded
        .listen((event) {
      final clientPeerId = event.snapshot.key;
      if (clientPeerId == null) return;
      if (_peers.containsKey(clientPeerId)) return; // already handling
      _handleNewPeer(clientPeerId);
    });
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    await _newPeerSub?.cancel();
    _newPeerSub = null;

    for (final peer in _peers.values) {
      await peer.close();
    }
    _peers.clear();

    // Explicit delete (belt-and-suspenders alongside onDisconnect).
    if (_roomId != null) {
      await WebRtcSignaling.deleteRoom(_roomId!);
      _roomId = null;
    }
    _running = false;
  }

  @override
  void dispose() {
    stop();
    if (!_controller.isClosed) _controller.close();
  }

  // ----------------------------------------------------------
  // Messaging
  // ----------------------------------------------------------

  @override
  void broadcast(LanMessage msg) {
    final json = msg.toJsonString();
    for (final peer in _peers.values) {
      if (peer.isOpen) peer.send(json);
    }
  }

  @override
  void sendTo(String clientId, LanMessage msg) {
    _peers[clientId]?.send(msg.toJsonString());
  }

  @override
  Future<void> closeClient(String clientId) async {
    final peer = _peers.remove(clientId);
    await peer?.close();
  }

  // ----------------------------------------------------------
  // New peer handshake
  // ----------------------------------------------------------

  Future<void> _handleNewPeer(String clientPeerId) async {
    // Enforce max player limit — silent reject: host simply does not respond,
    // so the client times out on watchForAnswer() after 15 s.
    if (_peers.length >= kMaxRoomPlayers) return;
    await WebRtcSignaling.ensureAuth();

    // Reserve the slot immediately to prevent race with concurrent joins.
    _peers[clientPeerId] = _WebRtcPeer.placeholder();

    final signaling = WebRtcSignaling(
      roomId: _roomId!,
      clientPeerId: clientPeerId,
      isHost: true,
    );

    RTCPeerConnection? pc;
    try {
      pc = await createPeerConnection(_iceConfig);
      signaling.attach(pc);

      // The client creates the data channel (it is the offerer).
      // The host receives it via onDataChannel.
      final channelCompleter = Completer<RTCDataChannel>();
      pc.onDataChannel = (ch) {
        if (!channelCompleter.isCompleted) channelCompleter.complete(ch);
      };

      // Subscribe to client ICE BEFORE watchForOffer so no candidates are
      // missed between the offer write and the subscription.
      signaling.listenClientIce(signaling.handleIncomingCandidate);

      // Wire up host-side outgoing ICE candidates.
      pc.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          signaling.addHostIceCandidate(candidate);
        }
      };

      // Wait for the client's offer (30 s timeout).
      final offer = await signaling
          .watchForOffer()
          .timeout(const Duration(seconds: 30))
          .first;

      await pc.setRemoteDescription(offer);
      // Flush any ICE candidates that arrived before setRemoteDescription.
      await signaling.onRemoteDescriptionSet();

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      await signaling.writeAnswer(answer);

      // Wait for the data channel to be delivered (15 s timeout).
      final channel = await channelCompleter.future
          .timeout(const Duration(seconds: 15));

      final peer = _WebRtcPeer(
        peerId: clientPeerId,
        pc: pc,
        channel: channel,
      );

      peer.onMessage = (msg) {
        if (!_controller.isClosed) {
          _controller.add(LanIncomingEvent(clientId: clientPeerId, message: msg));
        }
      };

      peer.onClosed = () {
        _peers.remove(clientPeerId);
        // Emit synthetic bye so GameRoomProvider handles the player leave.
        if (!_controller.isClosed) {
          _controller.add(LanIncomingEvent(
            clientId: clientPeerId,
            message: LanMessage.bye(clientPeerId),
          ));
        }
      };

      // Replace the placeholder with the real peer.
      _peers[clientPeerId] = peer;
    } catch (e) {
      _peers.remove(clientPeerId);
      await pc?.close();
      await signaling.close();
      rethrow;
    }
  }
}

// ============================================================
// _WebRtcPeer — internal peer holder
// ============================================================

class _WebRtcPeer {
  final String peerId;
  final RTCPeerConnection? pc;
  final RTCDataChannel? channel;

  void Function(LanMessage)? onMessage;
  void Function()? onClosed;

  _WebRtcPeer({
    required this.peerId,
    required this.pc,
    required this.channel,
  }) {
    channel?.onMessage = (msg) {
      final parsed = LanMessage.tryParse(msg.text);
      if (parsed != null) onMessage?.call(parsed);
    };
    channel?.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelClosed) {
        onClosed?.call();
      }
    };
  }

  /// Placeholder used to reserve a slot before the handshake completes.
  _WebRtcPeer.placeholder()
      : peerId = '',
        pc = null,
        channel = null;

  bool get isOpen =>
      channel?.state == RTCDataChannelState.RTCDataChannelOpen;

  void send(String json) {
    if (!isOpen) return;
    try {
      channel!.send(RTCDataChannelMessage(json));
    } catch (_) {}
  }

  Future<void> close() async {
    try {
      await channel?.close();
    } catch (_) {}
    try {
      await pc?.close();
    } catch (_) {}
  }
}
