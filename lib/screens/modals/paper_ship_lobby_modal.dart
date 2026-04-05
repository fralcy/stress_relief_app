import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/game_room_provider.dart';
import '../../core/providers/lan_provider.dart';
import '../../core/utils/lan/lan_service.dart';
import '../../core/utils/lan/lan_discovery.dart';
import '../../core/utils/lan/game_message.dart';
import '../../core/utils/lan/game_room.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/data_manager.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_modal.dart';
import 'paper_ship_modal.dart';

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

class PaperShipLobbyModal extends StatefulWidget {
  const PaperShipLobbyModal({super.key});

  @override
  State<PaperShipLobbyModal> createState() => _PaperShipLobbyModalState();

  static Future<void> show(BuildContext context) {
    return AppModal.show(
      context: context,
      title: AppLocalizations.of(context).paperShip,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      enableDrag: false,
      onClose: () => Navigator.of(context).pop(),
      content: const PaperShipLobbyModal(),
    );
  }
}

class _PaperShipLobbyModalState extends State<PaperShipLobbyModal> {
  // ── FSM ──────────────────────────────────────────────────────
  _LobbyState _state = _LobbyState.idle;
  bool _transitioning = false;

  // ── Metadata ─────────────────────────────────────────────────
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
    final localIp = await LanDiscovery.getLocalIp();
    if (!mounted) return;
    if (localIp == null) {
      setState(() => _errorMessage = AppLocalizations.of(context).lanNotConnected);
      return;
    }

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
      room.createRoom(GameType.paperShip);
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
    final seed = math.Random().nextInt(0x7FFFFFFF);
    context.read<GameRoomProvider>().startGame({'seed': seed});
    SfxService().buttonClick();
    _openGame({'seed': seed});
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
      setState(() => _state = _LobbyState.syncing);
      _startSyncTimeout();
    } else if (room.localPlayer?.isPending ?? false) {
      setState(() => _state = _LobbyState.clientPending);
    } else {
      setState(() => _state = _LobbyState.clientLobby);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Reconnect flow
  // ─────────────────────────────────────────────────────────────

  Future<void> _startReconnecting() async {
    if (_transitioning) return;
    final ip = LanService().lastHostIp;
    final port = LanService().lastHostPort;

    if (ip == null) { _doScan(); return; }

    setState(() {
      _state = _LobbyState.clientReconnecting;
      _reconnectAttempt = 0;
    });

    for (int attempt = 1; attempt <= _maxReconnectAttempts; attempt++) {
      if (!mounted || _state != _LobbyState.clientReconnecting) return;
      setState(() => _reconnectAttempt = attempt);

      await LanService().connectByAddress(ip, port);
      if (!mounted) return;

      if (LanService().isActive) { _enterConnectedState(); return; }

      if (attempt < _maxReconnectAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (mounted) {
      setState(() => _state = _LobbyState.clientScanning);
      _doScan();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Syncing (mid-game rejoin)
  // ─────────────────────────────────────────────────────────────

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
        setState(() {
          _state = _LobbyState.error;
          _errorMessage = 'Sync timeout';
        });
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
    final msg = type == LobbyErrorType.kicked ? l10n.kickedByHost : l10n.deniedByHost;
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
    final seed = gs['seed'] as int? ?? 0;
    final isHostOrSolo = LanService().role == LanRole.host || !LanService().isActive;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final room = context.read<GameRoomProvider>();
      final playerOrder = room.currentRoom?.players.map((p) => p.id).toList() ?? [];
      final localSlot = playerOrder.indexOf(_localUid) + 1;

      if (isHostOrSolo) {
        await PaperShipModal.show(
          context,
          seed: seed,
          localSlot: localSlot.clamp(1, 4),
          playerOrder: playerOrder,
        );
        if (!mounted) return;
        _gameStarted = false;
        if (LanService().isActive) {
          room.returnToLobby();
          setState(() => _state = _LobbyState.hostLobby);
        } else {
          setState(() => _state = _LobbyState.idle);
        }
      } else {
        await PaperShipModal.show(
          context,
          seed: seed,
          localSlot: localSlot.clamp(1, 4),
          playerOrder: playerOrder,
        );
        if (!mounted) return;
        _gameStarted = false;
        if (LanService().isActive) {
          setState(() => _state = _LobbyState.clientLobby);
        } else {
          setState(() => _state = _LobbyState.disconnected);
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final room = context.watch<GameRoomProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildBody(context, theme, l10n, room),
    );
  }

  Widget _buildBody(BuildContext context, dynamic theme, AppLocalizations l10n,
      GameRoomProvider room) {
    switch (_state) {
      case _LobbyState.idle:
        return _buildIdle(theme, l10n);
      case _LobbyState.hostStarting:
        return _buildLoading(l10n.startGame);
      case _LobbyState.hostLobby:
        return _buildHostLobby(theme, l10n, room);
      case _LobbyState.clientScanning:
        return _buildLoading(l10n.scanning);
      case _LobbyState.clientScanResults:
        return _buildScanResults(theme, l10n);
      case _LobbyState.clientConnecting:
        return _buildLoading(l10n.connecting);
      case _LobbyState.clientPending:
        return _buildPending(theme, l10n);
      case _LobbyState.clientLobby:
        return _buildClientLobby(theme, l10n, room);
      case _LobbyState.disconnected:
        return _buildDisconnected(theme, l10n);
      case _LobbyState.clientReconnecting:
        return _buildLoading('${l10n.reconnecting} ($_reconnectAttempt/$_maxReconnectAttempts)');
      case _LobbyState.syncing:
        return _buildLoading(l10n.syncing);
      case _LobbyState.error:
        return _buildError(theme, l10n);
    }
  }

  // ── Idle ─────────────────────────────────────────────────────

  Widget _buildIdle(dynamic theme, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        // Solo play
        AppButton(
          label: l10n.singleplayer,
          onPressed: () {
            final seed = math.Random().nextInt(0x7FFFFFFF);
            _openGame({'seed': seed});
          },
        ),
        const SizedBox(height: 12),
        // Host LAN
        AppButton(
          label: l10n.createRoom,
          onPressed: _startHosting,
          isActive: true,
        ),
        const SizedBox(height: 12),
        // Join LAN
        AppButton(
          label: l10n.joinGame,
          onPressed: _doScan,
          isActive: true,
        ),
        const Spacer(),
        if (_errorMessage != null)
          Text(_errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.error ?? Colors.red)),
      ],
    );
  }

  // ── Loading ───────────────────────────────────────────────────

  Widget _buildLoading(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label),
        ],
      ),
    );
  }

  // ── Host lobby ────────────────────────────────────────────────

  Widget _buildHostLobby(dynamic theme, AppLocalizations l10n, GameRoomProvider room) {
    final players = room.currentRoom?.players ?? [];
    final allReady = players.where((p) => !p.isHost).every((p) => p.isReady);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.players,
            style: AppTypography.bodySmall(context, color: theme.text,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(child: _buildPlayerList(players, theme, l10n, isHost: true)),
        const SizedBox(height: 12),
        AppButton(
          label: l10n.startGame,
          onPressed: (players.isNotEmpty && (allReady || players.length == 1))
              ? _onStartGame
              : null,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _cancelAndGoIdle,
          child: Text(l10n.cancel, style: TextStyle(color: theme.text)),
        ),
      ],
    );
  }

  // ── Client lobby ─────────────────────────────────────────────

  Widget _buildClientLobby(dynamic theme, AppLocalizations l10n, GameRoomProvider room) {
    final players = room.currentRoom?.players ?? [];
    final local = room.localPlayer;
    final isReady = local?.isReady ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.players,
            style: AppTypography.bodySmall(context, color: theme.text,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(child: _buildPlayerList(players, theme, l10n, isHost: false)),
        const SizedBox(height: 12),
        AppButton(
          label: isReady ? l10n.notReadyLabel : l10n.readyLabel,
          onPressed: () {
            room.setReady(!isReady);
            SfxService().buttonClick();
          },
          isActive: isReady,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _cancelAndGoIdle,
          child: Text(l10n.cancel, style: TextStyle(color: theme.text)),
        ),
      ],
    );
  }

  Widget _buildPlayerList(List<dynamic> players, dynamic theme,
      AppLocalizations l10n, {required bool isHost}) {
    if (players.isEmpty) {
      return Center(child: Text(l10n.waitingForPlayers,
          style: AppTypography.bodySmall(context, color: theme.subText)));
    }
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (_, i) {
        final p = players[i];
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: theme.primary.withValues(alpha: 0.15),
            child: Text(p.displayName.isNotEmpty ? p.displayName[0] : '?',
                style: TextStyle(color: theme.primary)),
          ),
          title: Text(p.displayName,
              style: AppTypography.bodySmall(context, color: theme.text)),
          trailing: p.isHost
              ? Text('HOST',
                  style: AppTypography.bodySmall(context, color: theme.primary))
              : p.isReady
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                  : const Icon(Icons.radio_button_unchecked, size: 18),
        );
      },
    );
  }

  // ── Scan results ──────────────────────────────────────────────

  Widget _buildScanResults(dynamic theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.hostsFound,
            style: AppTypography.bodySmall(context, color: theme.text,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _discoveredHosts.length,
            itemBuilder: (_, i) {
              final host = _discoveredHosts[i];
              return Card(
                child: ListTile(
                  title: Text(host.displayName),
                  subtitle: Text('${host.ip}:${host.wsPort}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _connectToHost(host),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _cancelAndGoIdle,
            child: Text(l10n.cancel, style: TextStyle(color: theme.text))),
      ],
    );
  }

  // ── Pending ───────────────────────────────────────────────────

  Widget _buildPending(dynamic theme, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(l10n.pendingApproval, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextButton(onPressed: _cancelAndGoIdle,
            child: Text(l10n.cancel, style: TextStyle(color: theme.text))),
      ],
    );
  }

  // ── Disconnected ──────────────────────────────────────────────

  Widget _buildDisconnected(dynamic theme, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.connectionLost,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(context, color: theme.text)),
        const SizedBox(height: 16),
        if (!_wasHost)
          AppButton(label: l10n.reconnect, onPressed: _startReconnecting),
        const SizedBox(height: 8),
        TextButton(onPressed: _cancelAndGoIdle,
            child: Text(l10n.cancel, style: TextStyle(color: theme.text))),
      ],
    );
  }

  // ── Error ─────────────────────────────────────────────────────

  Widget _buildError(dynamic theme, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_errorMessage ?? l10n.syncError,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        AppButton(label: l10n.ok, onPressed: _cancelAndGoIdle),
      ],
    );
  }
}
