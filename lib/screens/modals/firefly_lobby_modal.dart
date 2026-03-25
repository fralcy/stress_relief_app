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
import '../../core/utils/lan/lan_message.dart';
import '../../core/utils/lan/game_message.dart';
import '../../core/utils/lan/lan_host_info.dart';
import '../../core/utils/lan/game_room.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/constants/avatar_presets.dart';
import '../../core/utils/data_manager.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/utils/firefly_world.dart' show FireflyRole;
import 'firefly_modal.dart';

// ──────────────────────────────────────────────────────────────
// FSM States (mirrors rock balancing lobby)
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

class FireflyLobbyModal extends StatefulWidget {
  const FireflyLobbyModal({super.key});

  @override
  State<FireflyLobbyModal> createState() => _FireflyLobbyModalState();

  static Future<void> show(BuildContext context) {
    return AppModal.show(
      context: context,
      title: AppLocalizations.of(context).fireflyCatching,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      enableDrag: false,
      onClose: () => Navigator.of(context).pop(),
      content: const FireflyLobbyModal(),
    );
  }
}

class _FireflyLobbyModalState extends State<FireflyLobbyModal> {
  // ── FSM ──────────────────────────────────────────────────
  _LobbyState _state = _LobbyState.idle;
  bool _transitioning = false;

  // ── Config ───────────────────────────────────────────────
  int _fireflyCount = 10;
  FireflyRole _hostRole = FireflyRole.lamp;
  FireflyRole _clientRole = FireflyRole.jar; // client's chosen role
  bool _gameStarted = false;

  // ── Discovery ────────────────────────────────────────────
  List<LanHostInfo> _discoveredHosts = [];
  String? _errorMessage;
  bool _wasHost = false;
  int _reconnectAttempt = 0;
  static const int _maxReconnectAttempts = 3;

  // ── Role tracking (synced across lobby) ──────────────────
  // uid → chosen role; populated by host selection + clientRoleChange messages
  final Map<String, FireflyRole> _playerRoles = {};

  // ── Subscriptions ────────────────────────────────────────
  StreamSubscription<LobbyErrorType>? _errorSub;
  StreamSubscription<void>? _disconnectSub;
  StreamSubscription<void>? _snapshotAckSub;
  StreamSubscription<Map<String, dynamic>>? _fullSnapshotSub;
  StreamSubscription<LanIncomingEvent>? _roleSub;
  Timer? _syncTimeoutTimer;

  // ── Local player ─────────────────────────────────────────
  String get _localUid => DataManager().userProfile.id;
  String get _localName => DataManager().userProfile.name;
  int get _localAvatarIndex => DataManager().userProfile.resolvedAvatarIndex;

  bool get _isSolo => !LanService().isActive;
  bool get _isHost => _isSolo || LanService().role == LanRole.host;

  // ─────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeState();
      _subscribeRoleChanges();
    });
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    _disconnectSub?.cancel();
    _snapshotAckSub?.cancel();
    _fullSnapshotSub?.cancel();
    _roleSub?.cancel();
    _syncTimeoutTimer?.cancel();
    super.dispose();
  }

  void _subscribeRoleChanges() {
    _roleSub = LanService().incomingEvents.listen((event) {
      if (!mounted) return;
      final gm = GameMessage.tryExtract(event.message);
      if (gm == null) return;

      if (_isHost) {
        final uid = event.message.senderId;
        bool changed = false;
        // New player first message → assign default jar
        if (!_playerRoles.containsKey(uid)) {
          _playerRoles[uid] = FireflyRole.jar;
          changed = true;
        }
        // Client explicitly changed role
        if (gm.event == GameEvent.playerAction &&
            gm.data['type'] == 'clientRoleChange') {
          final roleStr = gm.data['role'] as String? ?? '';
          _playerRoles[uid] = FireflyRole.values.firstWhere(
              (r) => r.name == roleStr, orElse: () => FireflyRole.jar);
          changed = true;
        }
        if (changed) {
          setState(() {});
          _broadcastRoles();
        }
      } else {
        // Client receives host broadcast of full role map
        if (gm.event == GameEvent.gameState &&
            gm.data['type'] == 'roleUpdate') {
          final rolesRaw = gm.data['roles'] as Map<String, dynamic>? ?? {};
          setState(() {
            for (final e in rolesRaw.entries) {
              _playerRoles[e.key] = FireflyRole.values.firstWhere(
                  (r) => r.name == e.value, orElse: () => FireflyRole.jar);
            }
          });
        }
      }
    });
  }

  void _broadcastRoles() {
    if (!LanService().isActive) return;
    LanService().broadcastMessage(GameMessage.gameState(_localUid, {
      'type': 'roleUpdate',
      'roles': {for (final e in _playerRoles.entries) e.key: e.value.name},
    }));
  }

  void _resumeState() {
    if (!mounted) return;
    final lan = LanService();
    final room = context.read<GameRoomProvider>();
    if (!lan.isActive) return;

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

  // ─────────────────────────────────────────────────────────
  // Cancel / cleanup
  // ─────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────
  // Host flow
  // ─────────────────────────────────────────────────────────

  Future<void> _startHosting() async {
    if (_transitioning) return;
    setState(() { _state = _LobbyState.hostStarting; _errorMessage = null; });

    final lan = context.read<LanProvider>();
    await lan.startHosting(displayName: _localName);
    if (!mounted) return;

    if (lan.isActive) {
      final room = context.read<GameRoomProvider>();
      room.init(_localUid, _localName, _localAvatarIndex);
      room.createRoom(GameType.catchFirefly);
      _playerRoles[_localUid] = _hostRole;
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
    final room = context.read<GameRoomProvider>();
    final playerOrder = (room.currentRoom?.players ?? []).map((p) => p.id).toList();
    final seed = DateTime.now().millisecondsSinceEpoch;
    // Build roles map: host knows their own role, clients sent theirs via clientRoleChange
    _playerRoles[_localUid] = _hostRole;
    final roles = {for (final uid in playerOrder)
      uid: (_playerRoles[uid] ??
            (uid == _localUid ? FireflyRole.lamp : FireflyRole.jar)).name};
    room.startGame({
      'maxOnScreen': _fireflyCount,
      'fireflySeed': seed,
      'playerOrder': playerOrder,
      'roles': roles,
    });
    SfxService().buttonClick();
    _openGame({
      'maxOnScreen': _fireflyCount,
      'fireflySeed': seed,
      'playerOrder': playerOrder,
      'roles': roles,
    });
  }

  // ─────────────────────────────────────────────────────────
  // Client scan flow
  // ─────────────────────────────────────────────────────────

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
    setState(() { _state = _LobbyState.clientConnecting; _errorMessage = null; });

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
      setState(() => _state = _LobbyState.syncing);
      _startSyncTimeout();
    } else if (room.localPlayer?.isPending ?? false) {
      setState(() => _state = _LobbyState.clientPending);
    } else {
      setState(() => _state = _LobbyState.clientLobby);
    }
  }

  Future<void> _startReconnecting() async {
    if (_transitioning) return;
    final ip = LanService().lastHostIp;
    if (ip == null) { _doScan(); return; }

    setState(() { _state = _LobbyState.clientReconnecting; _reconnectAttempt = 0; });

    for (int attempt = 1; attempt <= _maxReconnectAttempts; attempt++) {
      if (!mounted || _state != _LobbyState.clientReconnecting) return;
      setState(() => _reconnectAttempt = attempt);
      await LanService().connectByAddress(ip, LanService().lastHostPort);
      if (!mounted) return;
      if (LanService().isActive) { _enterConnectedState(); return; }
      if (attempt < _maxReconnectAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    if (mounted) { setState(() => _state = _LobbyState.clientScanning); _doScan(); }
  }

  // ─────────────────────────────────────────────────────────
  // Syncing / rejoin
  // ─────────────────────────────────────────────────────────

  void _startSyncTimeout() {
    _syncTimeoutTimer?.cancel();
    _syncTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _state != _LobbyState.syncing) return;
      setState(() { _state = _LobbyState.disconnected; _wasHost = false; });
    });

    _snapshotAckSub?.cancel();
    _snapshotAckSub = context.read<GameRoomProvider>().snapshotAckReceived.listen((_) {
      _syncTimeoutTimer?.cancel();
      _snapshotAckSub?.cancel();
      LanService().sendMessage(GameMessage.snapshotRequest(_localUid));
      _syncTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted || _state != _LobbyState.syncing) return;
        setState(() { _state = _LobbyState.error; _errorMessage = 'Sync timeout'; });
      });
    });

    _fullSnapshotSub?.cancel();
    _fullSnapshotSub = context.read<GameRoomProvider>().fullSnapshotReceived.listen((_) {
      _syncTimeoutTimer?.cancel();
      _snapshotAckSub?.cancel();
      _fullSnapshotSub?.cancel();
      if (!mounted || _state != _LobbyState.syncing) return;
      _openGame(context.read<GameRoomProvider>().initialGameParams);
    });
  }

  // ─────────────────────────────────────────────────────────
  // Disconnect / errors
  // ─────────────────────────────────────────────────────────

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
    _errorSub = room.lobbyErrors.listen((type) {
      if (!mounted || _transitioning) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _state = _LobbyState.error;
        _errorMessage = type == LobbyErrorType.kicked
            ? l10n.kickedByHost
            : l10n.deniedByHost;
      });
    });
  }

  // ─────────────────────────────────────────────────────────
  // Open game
  // ─────────────────────────────────────────────────────────

  void _openGame(Map<String, dynamic> gs) {
    if (_gameStarted) return;
    _gameStarted = true;
    final count = gs['maxOnScreen'] as int? ?? _fireflyCount;
    final seed = gs['fireflySeed'] as int? ?? 0;
    final playerOrder = (gs['playerOrder'] as List<dynamic>? ?? []).cast<String>();

    final rolesRaw = gs['roles'] as Map<String, dynamic>? ?? {};
    final int localToolId;
    final FireflyRole role;
    if (_isSolo) {
      localToolId = 1;
      role = FireflyRole.lamp;
    } else {
      final idx = playerOrder.indexOf(_localUid);
      localToolId = idx >= 0 ? idx + 1 : 1;
      // Prefer authoritative roles map from host; fall back to local selection
      final roleStr = rolesRaw[_localUid] as String?;
      role = roleStr != null
          ? FireflyRole.values.firstWhere((r) => r.name == roleStr,
              orElse: () => _isHost ? _hostRole : _clientRole)
          : (_isHost ? _hostRole : _clientRole);
    }

    // Build allRoles map: toolId (1-based) → FireflyRole
    final allRoles = <int, FireflyRole>{};
    for (int i = 0; i < playerOrder.length; i++) {
      final toolId = i + 1;
      final uid = playerOrder[i];
      final roleStr = rolesRaw[uid] as String?;
      final defaultRole = uid == _localUid
          ? (_isHost ? _hostRole : _clientRole)
          : (i == 0 ? FireflyRole.lamp : FireflyRole.jar);
      allRoles[toolId] = roleStr != null
          ? FireflyRole.values.firstWhere(
              (r) => r.name == roleStr, orElse: () => defaultRole)
          : defaultRole;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      FireflyModal.show(context,
          maxOnScreen: count,
          fireflySeed: seed,
          role: role,
          localToolId: localToolId,
          playerOrder: playerOrder,
          allRoles: allRoles);
    });
  }

  void _onStartSolo() {
    if (_gameStarted) return;
    SfxService().buttonClick();
    final seed = DateTime.now().millisecondsSinceEpoch;
    _openGame({'maxOnScreen': _fireflyCount, 'fireflySeed': seed, 'playerOrder': <String>[]});
  }

  // ─────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────

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
      _LobbyState.clientScanResults => _buildScanResults(theme, l10n),
      _LobbyState.clientConnecting => _buildSpinner(theme, l10n,
          label: l10n.connecting, showCancel: true),
      _LobbyState.clientPending => _buildSpinner(theme, l10n,
          label: l10n.pendingApproval, showCancel: true),
      _LobbyState.clientLobby => _buildClientLobby(theme, l10n, room),
      _LobbyState.disconnected => _buildDisconnected(theme, l10n),
      _LobbyState.clientReconnecting => _buildSpinner(theme, l10n,
          label: '${l10n.reconnecting} ($_reconnectAttempt/$_maxReconnectAttempts)',
          showCancel: true),
      _LobbyState.syncing => _buildSpinner(theme, l10n, label: l10n.syncing),
      _LobbyState.error => _buildError(theme, l10n),
    };
  }

  // ─────────────────────────────────────────────────────────
  // State widgets
  // ─────────────────────────────────────────────────────────

  Widget _buildIdle(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFireflyCountConfig(theme, l10n),
        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),
        Text(l10n.singleplayer,
            style: AppTypography.bodyMedium(context,
                color: theme.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        AppButton(label: l10n.startGame, onPressed: _onStartSolo),
        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),
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
          ..._discoveredHosts.map((h) => _buildHostTile(theme, l10n, h)),
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
        const SizedBox(height: 24),
        CircularProgressIndicator(color: theme.primary),
        const SizedBox(height: 20),
        Text(label,
            style: AppTypography.bodyMedium(context,
                color: theme.text.withValues(alpha: 0.6))),
        if (showCancel) ...[
          const SizedBox(height: 20),
          _cancelButton(theme, l10n),
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
        ..._discoveredHosts.map((h) => _buildHostTile(theme, l10n, h)),
        const SizedBox(height: 16),
        _buildButtonRow(theme, l10n,
            actionLabel: l10n.rescan, onAction: _doScan),
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
        Text(
          kAvatarPresets[host.avatarIndex
              .clamp(0, kAvatarPresets.length - 1)],
          style: const TextStyle(fontSize: 22),
        ),
        const SizedBox(width: 10),
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

  Widget _buildHostLobby(AppTheme theme, AppLocalizations l10n, GameRoomProvider room) {
    final currentRoom = room.currentRoom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentRoom != null) ...[
          _buildApprovalToggle(theme, l10n, room, currentRoom),
          const SizedBox(height: 16),
        ],
        _buildPlayerList(theme, l10n, room),
        const SizedBox(height: 20),
        _buildFireflyCountConfig(theme, l10n),
        const SizedBox(height: 12),
        _buildRoleSelector(theme, l10n),
        const SizedBox(height: 16),
        _buildButtonRow(theme, l10n,
            actionLabel: l10n.startGame,
            onAction: (room.currentRoom?.allReady ?? false) ? _onStartGame : null),
      ],
    );
  }

  Widget _buildClientLobby(AppTheme theme, AppLocalizations l10n, GameRoomProvider room) {
    final isReady = room.localPlayer?.isReady ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlayerList(theme, l10n, room),
        const SizedBox(height: 20),
        _buildClientRoleSelector(theme, l10n),
        const SizedBox(height: 16),
        _buildButtonRow(theme, l10n,
            actionLabel: isReady ? l10n.notReadyLabel : l10n.readyLabel,
            onAction: () {
              room.setReady(!isReady);
              SfxService().buttonClick();
            }),
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
        const SizedBox(height: 8),
        _cancelButton(theme, l10n),
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
        Text(_errorMessage ?? 'An error occurred',
            style: AppTypography.bodyMedium(context, color: theme.text),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        AppButton(label: l10n.ok, onPressed: _cancelAndGoIdle),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // Shared sub-widgets
  // ─────────────────────────────────────────────────────────

  Widget _buildFireflyCountConfig(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.maxFireflyCount}: $_fireflyCount',
            style: AppTypography.bodyLarge(context,
                color: theme.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Text('5',
              style: AppTypography.bodySmall(context,
                  color: theme.text.withValues(alpha: 0.5))),
          Expanded(
            child: Slider(
              value: _fireflyCount.toDouble(),
              min: 5,
              max: 20,
              divisions: 3,
              activeColor: theme.primary,
              inactiveColor: theme.border,
              onChanged: (v) =>
                  setState(() => _fireflyCount = (v / 5).round() * 5),
            ),
          ),
          Text('20',
              style: AppTypography.bodySmall(context,
                  color: theme.text.withValues(alpha: 0.5))),
        ]),
      ],
    );
  }

  Widget _buildClientRoleSelector(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.selectStartingRole,
            style: AppTypography.bodySmall(context,
                color: theme.text.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _clientRole = FireflyRole.lamp);
                _sendClientRole(FireflyRole.lamp);
              },
              child: _roleCard(theme, l10n.roleLamp, Icons.flashlight_on,
                  _clientRole == FireflyRole.lamp),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _clientRole = FireflyRole.jar);
                _sendClientRole(FireflyRole.jar);
              },
              child: _roleCard(theme, l10n.roleJar, Icons.science_outlined,
                  _clientRole == FireflyRole.jar),
            ),
          ),
        ]),
      ],
    );
  }

  void _sendClientRole(FireflyRole role) {
    if (!LanService().isActive) return;
    LanService().sendMessage(GameMessage.playerAction(_localUid, {
      'type': 'clientRoleChange',
      'role': role.name,
    }));
  }

  Widget _buildRoleSelector(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.selectStartingRole,
            style: AppTypography.bodySmall(context,
                color: theme.text.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() { _hostRole = FireflyRole.lamp; _playerRoles[_localUid] = FireflyRole.lamp; });
                _broadcastRoles();
              },
              child: _roleCard(theme, l10n.roleLamp, Icons.flashlight_on,
                  _hostRole == FireflyRole.lamp),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() { _hostRole = FireflyRole.jar; _playerRoles[_localUid] = FireflyRole.jar; });
                _broadcastRoles();
              },
              child: _roleCard(theme, l10n.roleJar, Icons.science_outlined,
                  _hostRole == FireflyRole.jar),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _roleCard(AppTheme theme, String label, IconData icon, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected
            ? theme.primary.withValues(alpha: 0.12)
            : theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected ? theme.primary : theme.border,
            width: selected ? 2 : 1),
      ),
      child: Column(
        children: [
          Icon(icon,
              color: selected ? theme.primary : theme.text.withValues(alpha: 0.5),
              size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: AppTypography.bodySmall(context,
                  color: selected
                      ? theme.primary
                      : theme.text.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildApprovalToggle(AppTheme theme, AppLocalizations l10n,
      GameRoomProvider room, GameRoom currentRoom) {
    return Row(children: [
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
    ]);
  }

  Widget _buildPlayerList(AppTheme theme, AppLocalizations l10n, GameRoomProvider room) {
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
          Text('${players.length}/4',
              style: AppTypography.bodySmall(context,
                  color: theme.text.withValues(alpha: 0.5))),
        ]),
        const SizedBox(height: 12),
        ...players.map((p) {
          final isPlayerHost = p.isHost;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ready icon — spans both lines
                Icon(
                  p.isReady || isPlayerHost
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: p.isReady || isPlayerHost ? Colors.green : theme.border,
                  size: 18,
                ),
                const SizedBox(width: 10),
                // Avatar
                Text(
                  kAvatarPresets[p.avatarIndex.clamp(0, kAvatarPresets.length - 1)],
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                // Name + role on two lines
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Line 1: name + host chip + remove
                      Row(children: [
                        Expanded(
                          child: Text(p.displayName,
                              style: AppTypography.bodyMedium(context, color: theme.text),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isPlayerHost) ...[
                          const SizedBox(width: 4),
                          _chip(theme, l10n.lobbyHost, theme.primary),
                        ],
                        if (isHost && !isPlayerHost) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => room.kickPlayer(p.id),
                            child: _chip(theme, l10n.remove, Colors.red),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 3),
                      // Line 2: role chip
                      Builder(builder: (_) {
                        final role = _playerRoles[p.id] ??
                            (isPlayerHost ? FireflyRole.lamp : FireflyRole.jar);
                        return _chip(theme,
                          role == FireflyRole.lamp ? l10n.roleLamp : l10n.roleJar,
                          role == FireflyRole.lamp
                              ? const Color(0xFF5BA3FF)
                              : const Color(0xFF66BB6A));
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(l10n.cancel,
              style: AppTypography.labelLarge(context, fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ElevatedButton(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: onAction != null ? theme.primary : theme.border.withValues(alpha: 0.35),
            foregroundColor: onAction != null ? context.onPrimary : theme.text.withValues(alpha: 0.38),
            minimumSize: const Size.fromHeight(48),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(actionLabel,
                style: AppTypography.labelLarge(context, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    ]);
  }

  Widget _cancelButton(AppTheme theme, AppLocalizations l10n) {
    return ElevatedButton(
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
