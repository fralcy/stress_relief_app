import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_typography.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/game_room_provider.dart';
import '../../core/providers/lan_provider.dart';
import '../../core/utils/lan/lan_service.dart';
import '../../core/utils/lan/game_message.dart';
import '../../core/utils/lan/lan_host_info.dart';
import '../../core/utils/lan/game_room.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/constants/avatar_presets.dart';
import '../../core/utils/data_manager.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_modal.dart';
import 'rock_balancing_modal.dart';

// ──────────────────────────────────────────────────────────────
// FSM States
// ──────────────────────────────────────────────────────────────

enum _LobbyState {
  idle,
  hostStarting,
  hostLobby,
  clientScanning,
  clientScanResults,
  clientConnecting,
  clientPending,
  clientLobby,
  disconnected,
  clientReconnecting,
  syncing,
  error,
}

// ──────────────────────────────────────────────────────────────
// Widget
// ──────────────────────────────────────────────────────────────

class RockBalancingLobbyModal extends StatefulWidget {
  const RockBalancingLobbyModal({super.key});

  @override
  State<RockBalancingLobbyModal> createState() =>
      _RockBalancingLobbyModalState();

  static Future<void> show(BuildContext context) {
    return AppModal.show(
      context: context,
      title: AppLocalizations.of(context).rockBalancing,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      enableDrag: false,
      onClose: () => _closeRequested(context),
      content: const RockBalancingLobbyModal(),
    );
  }

  /// Called by the modal close button — delegate to the live state if possible.
  static void _closeRequested(BuildContext context) {
    // The state will handle cleanup via its own cancel button / PopScope.
    Navigator.of(context).pop();
  }
}

class _RockBalancingLobbyModalState extends State<RockBalancingLobbyModal> {
  // ── FSM ──────────────────────────────────────────────────────
  _LobbyState _state = _LobbyState.idle;

  /// True while async cleanup is in flight — ignore incoming events.
  bool _transitioning = false;

  // ── Metadata ─────────────────────────────────────────────────
  int _rockCount = 4;
  bool _gameStarted = false;
  List<LanHostInfo> _discoveredHosts = [];
  String? _errorMessage;
  bool _wasHost = false;
  int _reconnectAttempt = 0;
  static const int _maxReconnectAttempts = 3;

  // ── Subscriptions / timers ───────────────────────────────────
  StreamSubscription<LobbyErrorType>? _errorSub;
  StreamSubscription<void>? _disconnectSub;
  StreamSubscription<void>? _snapshotAckSub;
  StreamSubscription<Map<String, dynamic>>? _fullSnapshotSub;
  Timer? _syncTimeoutTimer;

  // ── Local player info ────────────────────────────────────────
  String get _localUid => DataManager().userProfile.id;
  String get _localName => DataManager().userProfile.name;
  int get _localAvatarIndex => DataManager().userProfile.resolvedAvatarIndex;

  // ─────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumeState());
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    _disconnectSub?.cancel();
    _snapshotAckSub?.cancel();
    _fullSnapshotSub?.cancel();
    _syncTimeoutTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Resume existing LAN state on modal reopen
  // ─────────────────────────────────────────────────────────────

  void _resumeState() {
    if (!mounted) return;
    final lan = LanService();
    final room = context.read<GameRoomProvider>();

    if (!lan.isActive) return; // nothing to resume

    if (lan.role == LanRole.host) {
      final status = room.currentRoom?.status;
      if (status == GameRoomStatus.playing) {
        _openGame(room.initialGameParams);
      } else {
        setState(() => _state = _LobbyState.hostLobby);
      }
    } else if (lan.role == LanRole.client) {
      _subscribeDisconnect();
      _subscribeToLobbyErrors(room);
      final status = room.currentRoom?.status;
      if (status == GameRoomStatus.playing) {
        _openGame(room.initialGameParams);
      } else if (room.localPlayer?.isPending ?? false) {
        setState(() => _state = _LobbyState.clientPending);
      } else if (room.currentRoom != null) {
        setState(() => _state = _LobbyState.clientLobby);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Cancel / cleanup
  // ─────────────────────────────────────────────────────────────

  Future<void> _cancelAndGoIdle() async {
    if (_transitioning) return;
    _transitioning = true;
    _syncTimeoutTimer?.cancel();
    _snapshotAckSub?.cancel();
    _fullSnapshotSub?.cancel();
    _disconnectSub?.cancel();
    _errorSub?.cancel();

    final lan = LanService();
    final room = context.read<GameRoomProvider>();

    switch (_state) {
      case _LobbyState.hostStarting:
      case _LobbyState.hostLobby:
        await lan.stopHosting();
        room.resetRoom();

      case _LobbyState.clientConnecting:
      case _LobbyState.clientPending:
      case _LobbyState.clientLobby:
      case _LobbyState.syncing:
        room.leaveRoom();
        await lan.disconnect();

      case _LobbyState.clientReconnecting:
        await lan.disconnect();

      case _LobbyState.disconnected:
      case _LobbyState.error:
        room.resetRoom();

      default:
        break;
    }

    if (mounted) {
      setState(() {
        _state = _LobbyState.idle;
        _errorMessage = null;
        _discoveredHosts = [];
        _gameStarted = false;
        _transitioning = false;
      });
    } else {
      _transitioning = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Host flow
  // ─────────────────────────────────────────────────────────────

  Future<void> _startHosting() async {
    if (_transitioning) return;
    setState(() {
      _state = _LobbyState.hostStarting;
      _errorMessage = null;
    });

    final lan = context.read<LanProvider>();
    await lan.startHosting(displayName: _localName, avatarIndex: _localAvatarIndex);
    if (!mounted) return;

    if (lan.isActive) {
      final room = context.read<GameRoomProvider>();
      room.init(_localUid, _localName, _localAvatarIndex);
      room.createRoom(GameType.rockBalancing);
      setState(() => _state = _LobbyState.hostLobby);
    } else {
      setState(() {
        _state = _LobbyState.error;
        _errorMessage = lan.errorMessage ?? 'Failed to start server';
      });
    }
  }

  void _onStartGame() {
    if (_gameStarted) return;
    final seed = DateTime.now().millisecondsSinceEpoch;
    context.read<GameRoomProvider>().startGame({
      'rockCount': _rockCount,
      'rockSeed': seed,
    });
    SfxService().buttonClick();
    _openGame({'rockCount': _rockCount, 'rockSeed': seed});
  }

  // ─────────────────────────────────────────────────────────────
  // Client scan flow
  // ─────────────────────────────────────────────────────────────

  Future<void> _doScan() async {
    if (_transitioning) return;
    setState(() {
      _state = _LobbyState.clientScanning;
      _errorMessage = null;
      _discoveredHosts = [];
    });

    final lan = context.read<LanProvider>();
    await lan.scanForHosts();
    if (!mounted) return;

    final hosts = lan.discoveredHosts;
    if (hosts.isEmpty) {
      setState(() {
        _state = _LobbyState.idle;
        _errorMessage = AppLocalizations.of(context).lanNotConnected;
      });
    } else {
      setState(() {
        _state = _LobbyState.clientScanResults;
        _discoveredHosts = hosts;
      });
    }
  }

  Future<void> _connectToHost(LanHostInfo host) async {
    if (_transitioning) return;
    setState(() {
      _state = _LobbyState.clientConnecting;
      _errorMessage = null;
    });

    final lan = context.read<LanProvider>();
    await lan.connect(host);
    if (!mounted) return;

    if (lan.isActive) {
      _enterConnectedState();
    } else {
      setState(() {
        _state = _LobbyState.error;
        _errorMessage = lan.errorMessage ?? 'Connection failed';
      });
    }
  }

  void _enterConnectedState() {
    final room = context.read<GameRoomProvider>();
    room.init(_localUid, _localName, _localAvatarIndex);
    room.joinRoom();
    _subscribeToLobbyErrors(room);
    _subscribeDisconnect();

    final status = room.currentRoom?.status;
    if (status == GameRoomStatus.playing) {
      // Mid-game rejoin — wait for host to push gameStart + snapshotAck
      setState(() => _state = _LobbyState.syncing);
      _startSyncTimeout();
    } else if (room.localPlayer?.isPending ?? false) {
      setState(() => _state = _LobbyState.clientPending);
    } else {
      setState(() => _state = _LobbyState.clientLobby);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Reconnect flow (direct IP, up to 3 attempts)
  // ─────────────────────────────────────────────────────────────

  Future<void> _startReconnecting() async {
    if (_transitioning) return;
    final ip = LanService().lastHostIp;
    final port = LanService().lastHostPort;

    if (ip == null) {
      _doScan();
      return;
    }

    setState(() {
      _state = _LobbyState.clientReconnecting;
      _reconnectAttempt = 0;
    });

    for (int attempt = 1; attempt <= _maxReconnectAttempts; attempt++) {
      if (!mounted || _state != _LobbyState.clientReconnecting) return;
      setState(() => _reconnectAttempt = attempt);

      await LanService().connectByAddress(ip, port);
      if (!mounted) return;

      if (LanService().isActive) {
        _enterConnectedState();
        return;
      }

      if (attempt < _maxReconnectAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    // All attempts failed
    if (mounted) {
      setState(() => _state = _LobbyState.clientScanning);
      _doScan();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Syncing (mid-game rejoin handshake)
  // ─────────────────────────────────────────────────────────────

  void _startSyncTimeout() {
    _syncTimeoutTimer?.cancel();
    // Phase 1: wait for snapshotAck within 5 s
    _syncTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _state != _LobbyState.syncing) return;
      // No ack → host likely crashed
      setState(() {
        _state = _LobbyState.disconnected;
        _wasHost = false;
      });
    });

    _snapshotAckSub?.cancel();
    _snapshotAckSub = context
        .read<GameRoomProvider>()
        .snapshotAckReceived
        .listen((_) {
      _syncTimeoutTimer?.cancel();
      _snapshotAckSub?.cancel(); // one-shot — prevent re-firing on host's reply ack
      // Request full snapshot so host sends current rock positions.
      LanService().sendMessage(GameMessage.snapshotRequest(_localUid));
      // Phase 2: wait for fullSnapshot within 5 s
      _syncTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted || _state != _LobbyState.syncing) return;
        setState(() {
          _state = _LobbyState.error;
          _errorMessage = 'Sync timeout — host failed to send game state';
        });
      });
    });

    _fullSnapshotSub?.cancel();
    _fullSnapshotSub = context
        .read<GameRoomProvider>()
        .fullSnapshotReceived
        .listen((_) {
      _syncTimeoutTimer?.cancel();
      _snapshotAckSub?.cancel();
      _fullSnapshotSub?.cancel();
      if (!mounted || _state != _LobbyState.syncing) return;
      // Open game with init params (seed/rockCount). Rock positions will be
      // immediately snapped via the snapshot message inside the game modal.
      _openGame(context.read<GameRoomProvider>().initialGameParams);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Disconnect detection
  // ─────────────────────────────────────────────────────────────

  void _subscribeDisconnect() {
    _disconnectSub?.cancel();
    _disconnectSub = LanService().connectionLost.listen((_) {
      if (!mounted || _transitioning) return;
      _wasHost = false;
      setState(() => _state = _LobbyState.disconnected);
    });
  }

  void _subscribeToLobbyErrors(GameRoomProvider room) {
    _errorSub?.cancel();
    _errorSub = room.lobbyErrors.listen(_onLobbyError);
  }

  void _onLobbyError(LobbyErrorType type) {
    if (!mounted || _transitioning) return;
    final l10n = AppLocalizations.of(context);
    final msg = type == LobbyErrorType.kicked
        ? l10n.kickedByHost
        : l10n.deniedByHost;
    setState(() {
      _state = _LobbyState.error;
      _errorMessage = msg;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Open game modal
  // ─────────────────────────────────────────────────────────────

  void _openGame(Map<String, dynamic> gs) {
    if (_gameStarted) return;
    _gameStarted = true;
    final rockCount = gs['rockCount'] as int? ?? _rockCount;
    final rockSeed = gs['rockSeed'] as int? ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      RockBalancingModal.show(context, rockCount: rockCount, rockSeed: rockSeed);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Solo
  // ─────────────────────────────────────────────────────────────

  void _onStartSolo() {
    if (_gameStarted) return;
    SfxService().buttonClick();
    final seed = DateTime.now().millisecondsSinceEpoch;
    _openGame({'rockCount': _rockCount, 'rockSeed': seed});
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final room = context.watch<GameRoomProvider>();

    // Client: auto-transition when game starts
    if (!_transitioning &&
        (_state == _LobbyState.clientLobby ||
            _state == _LobbyState.clientPending) &&
        room.currentRoom?.status == GameRoomStatus.playing) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openGame(room.initialGameParams));
    }

    // Client: pending → lobby once approved
    if (!_transitioning &&
        _state == _LobbyState.clientPending &&
        !(room.localPlayer?.isPending ?? true)) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) { if (mounted) setState(() => _state = _LobbyState.clientLobby); });
    }

    return switch (_state) {
      _LobbyState.idle => _buildIdle(theme, l10n),
      _LobbyState.hostStarting => _buildSpinner(theme, l10n,
          label: l10n.startServer),
      _LobbyState.hostLobby => _buildHostLobby(theme, l10n, room),
      _LobbyState.clientScanning => _buildSpinner(theme, l10n,
          label: l10n.scanning, showCancel: true),
      _LobbyState.clientScanResults =>
        _buildScanResults(theme, l10n),
      _LobbyState.clientConnecting => _buildSpinner(theme, l10n,
          label: l10n.connecting, showCancel: true),
      _LobbyState.clientPending => _buildClientPending(theme, l10n, room),
      _LobbyState.clientLobby => _buildClientLobby(theme, l10n, room),
      _LobbyState.disconnected => _buildDisconnected(theme, l10n),
      _LobbyState.clientReconnecting => _buildSpinner(theme, l10n,
          label: '${l10n.reconnecting} ($_reconnectAttempt/$_maxReconnectAttempts)',
          showCancel: true),
      _LobbyState.syncing => _buildSpinner(theme, l10n,
          label: l10n.syncing),
      _LobbyState.error => _buildError(theme, l10n),
    };
  }

  // ─────────────────────────────────────────────────────────────
  // State widgets
  // ─────────────────────────────────────────────────────────────

  Widget _buildIdle(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section: Settings ──────────────────────────────────
        _buildRockCountConfig(theme, l10n),

        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),

        // ── Section: Singleplayer ──────────────────────────────
        Text(l10n.singleplayer,
            style: AppTypography.bodyMedium(context,
                color: theme.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        AppButton(label: l10n.start, onPressed: _onStartSolo),

        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),

        // ── Section: Multiplayer ───────────────────────────────
        Text(l10n.multiplayer,
            style: AppTypography.bodyMedium(context,
                color: theme.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        AppButton(label: l10n.createRoom, onPressed: _startHosting),
        const SizedBox(height: 10),
        AppButton(label: l10n.joinGame, onPressed: _doScan),
        if (_discoveredHosts.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(l10n.hostsFound,
              style: AppTypography.bodySmall(context,
                  color: theme.text.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          ..._discoveredHosts.map((host) => _buildHostTile(theme, l10n, host)),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(_errorMessage!,
              style: AppTypography.bodySmall(context, color: Colors.redAccent),
              textAlign: TextAlign.center),
        ],
      ],
    );
  }

  Widget _buildSpinner(AppTheme theme, AppLocalizations l10n,
      {required String label, bool showCancel = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        CircularProgressIndicator(color: theme.primary),
        const SizedBox(height: 20),
        Text(label,
            style: AppTypography.bodyMedium(context,
                color: theme.text.withValues(alpha: 0.6))),
        if (showCancel) ...[
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _cancelAndGoIdle,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.border.withValues(alpha: 0.35),
              foregroundColor: theme.text.withValues(alpha: 0.65),
              minimumSize: const Size(160, 48),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.cancel,
                style: AppTypography.labelLarge(context,
                    fontWeight: FontWeight.w600)),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildScanResults(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.hostsFound,
            style: AppTypography.bodyMedium(context,
                color: theme.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._discoveredHosts.map((host) => _buildHostTile(theme, l10n, host)),
        const SizedBox(height: 16),
        _buildButtonRow(theme, l10n, actionLabel: l10n.rescan, onAction: _doScan),
      ],
    );
  }

  Widget _buildHostTile(AppTheme theme, AppLocalizations l10n, LanHostInfo host) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(children: [
        SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              kAvatarPresets[host.avatarIndex.clamp(0, kAvatarPresets.length - 1)],
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            host.displayName.isNotEmpty ? host.displayName : host.ip,
            style: AppTypography.bodyMedium(context, color: theme.text),
          ),
        ),
        GestureDetector(
          onTap: () => _connectToHost(host),
          child: _chip(theme, '>', theme.primary),
        ),
      ]),
    );
  }

  /// Action button + cancel button side-by-side, same format, different colors.
  Widget _buildButtonRow(AppTheme theme, AppLocalizations l10n,
      {required String actionLabel, required VoidCallback? onAction}) {
    return Row(children: [
      Expanded(
        child: ElevatedButton(
          onPressed: _cancelAndGoIdle,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.border.withValues(alpha: 0.35),
            foregroundColor: theme.text.withValues(alpha: 0.65),
            minimumSize: const Size.fromHeight(48),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(l10n.cancel,
              style: AppTypography.labelLarge(context,
                  fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: AppButton(label: actionLabel, onPressed: onAction)),
    ]);
  }

  Widget _buildHostLobby(
      AppTheme theme, AppLocalizations l10n, GameRoomProvider room) {
    final currentRoom = room.currentRoom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentRoom != null) ...[
          _buildApprovalToggle(theme, l10n, room, currentRoom),
          const SizedBox(height: 16),
        ],
        _buildPlayerList(theme, l10n, room),
        if (currentRoom?.pendingPlayers.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          _buildPendingList(theme, l10n, room, currentRoom!),
        ],
        const SizedBox(height: 20),
        _buildRockCountConfig(theme, l10n),
        const SizedBox(height: 16),
        _buildButtonRow(theme, l10n,
          actionLabel: l10n.startGame,
          onAction: (room.currentRoom?.allReady ?? false) ? _onStartGame : null,
        ),
      ],
    );
  }

  Widget _buildClientPending(
      AppTheme theme, AppLocalizations l10n, GameRoomProvider room) {
    final localPlayer = room.localPlayer;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        if (localPlayer != null)
          Text(
            kAvatarPresets[localPlayer.avatarIndex
                .clamp(0, kAvatarPresets.length - 1)],
            style: const TextStyle(fontSize: 40),
          ),
        const SizedBox(height: 12),
        Text(l10n.pendingApproval,
            style: AppTypography.bodyMedium(context, color: theme.primary)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _cancelAndGoIdle,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.border.withValues(alpha: 0.35),
            foregroundColor: theme.text.withValues(alpha: 0.65),
            minimumSize: const Size(160, 48),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(l10n.cancel,
              style: AppTypography.labelLarge(context, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildClientLobby(
      AppTheme theme, AppLocalizations l10n, GameRoomProvider room) {
    final localPlayer = room.localPlayer;
    final isReady = localPlayer?.isReady ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlayerList(theme, l10n, room),
        const SizedBox(height: 20),
        _buildButtonRow(theme, l10n,
          actionLabel: isReady ? l10n.notReadyLabel : l10n.readyLabel,
          onAction: () {
            room.setReady(!isReady);
            SfxService().buttonClick();
          },
        ),
      ],
    );
  }

  Widget _buildDisconnected(AppTheme theme, AppLocalizations l10n) {
    final hasIp = LanService().lastHostIp != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Icon(Icons.wifi_off, color: Colors.redAccent, size: 40),
        const SizedBox(height: 12),
        Text(l10n.connectionLost,
            style: AppTypography.bodyLarge(context,
                color: theme.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        if (_wasHost)
          AppButton(label: l10n.restartServer, onPressed: _startHosting)
        else ...[
          if (hasIp) ...[
            AppButton(label: l10n.reconnect, onPressed: _startReconnecting),
            const SizedBox(height: 8),
          ],
          AppButton(label: l10n.joinGame, onPressed: _doScan),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _cancelAndGoIdle,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.border.withValues(alpha: 0.35),
            foregroundColor: theme.text.withValues(alpha: 0.65),
            minimumSize: const Size.fromHeight(48),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(l10n.cancel,
              style: AppTypography.labelLarge(context, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildError(AppTheme theme, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? l10n.syncError,
          style: AppTypography.bodyMedium(context, color: theme.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        AppButton(
          label: l10n.ok,
          onPressed: _cancelAndGoIdle,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Shared sub-widgets
  // ─────────────────────────────────────────────────────────────

  Widget _buildApprovalToggle(AppTheme theme, AppLocalizations l10n,
      GameRoomProvider room, GameRoom currentRoom) {
    return Row(
      children: [
        Expanded(
          child: Text(l10n.approveJoin,
              style: AppTypography.bodyMedium(context, color: theme.text)),
        ),
        Switch(
          value: currentRoom.requireApproval,
          activeThumbColor: theme.primary,
          onChanged: (_) =>
              room.setRequireApproval(!currentRoom.requireApproval),
        ),
      ],
    );
  }

  Widget _buildPlayerList(
      AppTheme theme, AppLocalizations l10n, GameRoomProvider room) {
    final players = room.currentRoom?.activePlayers ?? [];
    final isHost = LanService().role == LanRole.host;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(l10n.players,
              style: AppTypography.bodyLarge(context,
                  color: theme.text, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text('${players.length}/$kMaxRoomPlayers',
              style: AppTypography.bodySmall(context,
                  color: theme.text.withValues(alpha: 0.5))),
        ]),
        const SizedBox(height: 12),
        ...players.map((p) => _buildPlayerTile(theme, l10n, room, p, isHost)),
        if (players.length < 2)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.waitingForPlayers,
                style: AppTypography.bodySmall(context,
                    color: theme.text.withValues(alpha: 0.5))),
          ),
      ],
    );
  }

  Widget _buildPlayerTile(AppTheme theme, AppLocalizations l10n,
      GameRoomProvider room, GamePlayer p, bool isHost) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(children: [
        // Ready indicator — always present, left-aligned for consistent layout
        Icon(
          p.isReady ? Icons.check_circle : Icons.radio_button_unchecked,
          color: p.isReady ? Colors.green : theme.border,
          size: 20,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              kAvatarPresets[p.avatarIndex.clamp(0, kAvatarPresets.length - 1)],
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(p.displayName,
                style: AppTypography.bodyMedium(context, color: theme.text))),
        if (p.isHost)
          _chip(theme, l10n.lobbyHost, theme.primary)
        else if (isHost)
          GestureDetector(
            onTap: () => room.kickPlayer(p.id),
            child: _chip(theme, l10n.remove, Colors.red),
          ),
      ]),
    );
  }

  Widget _buildPendingList(AppTheme theme, AppLocalizations l10n,
      GameRoomProvider room, GameRoom currentRoom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.pendingApproval,
            style: AppTypography.bodyMedium(context,
                color: theme.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...currentRoom.pendingPlayers.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: theme.border.withValues(alpha: 0.5)),
              ),
              child: Row(children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: Text(
                      kAvatarPresets[p.avatarIndex
                          .clamp(0, kAvatarPresets.length - 1)],
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(p.displayName,
                        style: AppTypography.bodyMedium(context,
                            color: theme.text.withValues(alpha: 0.7)))),
                GestureDetector(
                  onTap: () => room.approvePlayer(p.id),
                  child: _chip(theme, l10n.approveLabel, Colors.green),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => room.kickPlayer(p.id),
                  child: _chip(theme, l10n.remove, Colors.red),
                ),
              ]),
            )),
      ],
    );
  }

  Widget _buildRockCountConfig(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.rockCount}: $_rockCount',
            style: AppTypography.bodyLarge(context,
                color: theme.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Text('4',
              style: AppTypography.bodySmall(context,
                  color: theme.text.withValues(alpha: 0.5))),
          Expanded(
            child: Slider(
              value: _rockCount.toDouble(),
              min: 4,
              max: 20,
              divisions: 16,
              activeColor: theme.primary,
              inactiveColor: theme.border,
              onChanged: (v) => setState(() => _rockCount = v.round()),
            ),
          ),
          Text('20',
              style: AppTypography.bodySmall(context,
                  color: theme.text.withValues(alpha: 0.5))),
        ]),
      ],
    );
  }

  Widget _chip(AppTheme theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: AppTypography.captionSmall(context, color: color)),
    );
  }
}
