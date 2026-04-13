import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'lan_message.dart';
import 'lan_transport.dart';
import 'webrtc_signaling.dart';

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
// LanClient — WebRTC client (PWA)
// ============================================================

/// WebRTC P2P client for connecting to a PWA host via Firebase RTDB signaling.
///
/// The class is exported as [LanClient] on web via the conditional export in
/// `lan_client.dart`. [LanService] calls [connectByRoomId] when kIsWeb is true.
///
/// Data channel is created by this client (offerer side) with ordered=true
/// (TCP-like reliability, consistent with the existing WebSocket transport).
class LanClient implements LanClientBase {
  LanClientStatus _status = LanClientStatus.disconnected;
  String? _lastError;
  bool _intentionalDisconnect = false;

  RTCPeerConnection? _pc;
  RTCDataChannel? _dataChannel;
  WebRtcSignaling? _signaling;

  final StreamController<LanMessage> _controller =
      StreamController<LanMessage>.broadcast();
  final StreamController<void> _disconnectController =
      StreamController<void>.broadcast();

  // ── ICE server config ────────────────────────────────────
  // STUN is sufficient for home LAN. TURN would be needed for
  // symmetric NAT on corporate/school networks.
  static const Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

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

  /// No-op on web — WebSocket IP connections are blocked by HTTPS mixed-content.
  @override
  Future<void> connect(String host, int port) async {}

  /// Connect to a PWA host identified by [roomId] via Firebase RTDB signaling.
  ///
  /// Flow:
  /// 1. Create RTCPeerConnection
  /// 2. Create data channel (before offer so it appears in SDP)
  /// 3. Create offer → setLocalDescription → write to RTDB
  /// 4. Subscribe to host ICE candidates (before awaiting answer)
  /// 5. Wait for host answer → setRemoteDescription → flush buffered ICE
  /// 6. Wait for data channel to open
  @override
  Future<void> connectByRoomId(String roomId) async {
    if (_status == LanClientStatus.connecting ||
        _status == LanClientStatus.connected) return;

    _status = LanClientStatus.connecting;
    _lastError = null;

    final clientPeerId = _generatePeerId();
    _signaling = WebRtcSignaling(
      roomId: roomId,
      clientPeerId: clientPeerId,
      isHost: false,
    );

    try {
      _pc = await createPeerConnection(_iceConfig);
      _signaling!.attach(_pc!);

      // Create data channel BEFORE createOffer so it is included in the SDP.
      _dataChannel = await _pc!.createDataChannel(
        'game',
        RTCDataChannelInit()..ordered = true,
      );
      _setupDataChannel(_dataChannel!);

      // Wire up outgoing ICE candidates.
      _pc!.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          _signaling!.addClientIceCandidate(candidate);
        }
      };

      // Subscribe to host ICE BEFORE awaiting the answer so no candidates
      // are missed between the answer write and the subscription.
      _signaling!.listenHostIce(_signaling!.handleIncomingCandidate);

      // Create and publish offer.
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      await _signaling!.writeOffer(offer);

      // Wait for host answer (15 s timeout).
      final answer = await _signaling!
          .watchForAnswer()
          .timeout(const Duration(seconds: 15))
          .first;

      await _pc!.setRemoteDescription(answer);
      // Flush any ICE candidates that arrived before setRemoteDescription.
      await _signaling!.onRemoteDescriptionSet();

      // Wait for data channel to open (10 s timeout).
      await _waitForChannelOpen()
          .timeout(const Duration(seconds: 10));

      _status = LanClientStatus.connected;
    } catch (e) {
      _status = LanClientStatus.error;
      _lastError = e.toString();
      await _cleanup();
    }
  }

  // ----------------------------------------------------------
  // Messaging
  // ----------------------------------------------------------

  @override
  void send(LanMessage msg) {
    if (!isConnected || _dataChannel == null) return;
    try {
      _dataChannel!.send(RTCDataChannelMessage(msg.toJsonString()));
    } catch (e) {
      _status = LanClientStatus.error;
      _lastError = e.toString();
    }
  }

  // ----------------------------------------------------------
  // Disconnect / Dispose
  // ----------------------------------------------------------

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    await _cleanup();
    _status = LanClientStatus.disconnected;
    _lastError = null;
    _intentionalDisconnect = false;
  }

  @override
  void dispose() {
    disconnect();
    if (!_controller.isClosed) _controller.close();
    if (!_disconnectController.isClosed) _disconnectController.close();
  }

  // ----------------------------------------------------------
  // Internal helpers
  // ----------------------------------------------------------

  void _setupDataChannel(RTCDataChannel ch) {
    ch.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelClosed) {
        final wasConnected = _status == LanClientStatus.connected;
        _status = LanClientStatus.disconnected;
        if (wasConnected &&
            !_intentionalDisconnect &&
            !_disconnectController.isClosed) {
          _disconnectController.add(null);
        }
      }
    };
    ch.onMessage = (msg) {
      final parsed = LanMessage.tryParse(msg.text);
      if (parsed != null && !_controller.isClosed) {
        _controller.add(parsed);
      }
    };
  }

  /// Completes when the data channel transitions to open state.
  Future<void> _waitForChannelOpen() {
    if (_dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
      return Future.value();
    }
    final completer = Completer<void>();
    // Override the state handler temporarily to detect open.
    final originalHandler = _dataChannel?.onDataChannelState;
    _dataChannel?.onDataChannelState = (state) {
      originalHandler?.call(state);
      if (state == RTCDataChannelState.RTCDataChannelOpen &&
          !completer.isCompleted) {
        completer.complete();
      }
    };
    return completer.future;
  }

  Future<void> _cleanup() async {
    await _signaling?.close();
    _signaling = null;
    try {
      await _dataChannel?.close();
    } catch (_) {}
    _dataChannel = null;
    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;
  }

  String _generatePeerId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'peer_${ts}_${(ts % 9999).toString().padLeft(4, '0')}';
  }
}
