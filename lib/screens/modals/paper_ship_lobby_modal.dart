import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_tutorial_overlay/flutter_tutorial_overlay.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/avatar_presets.dart';
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
import '../../core/widgets/app_slider.dart';
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
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    if (size.width >= 720 && size.width > size.height && size.height >= 600) {
      return _showLandscape(context);
    }
    final modalKey = GlobalKey<_PaperShipLobbyModalState>();
    return AppModal.show(
      context: context,
      title: l10n.paperShip,
      maxHeight: size.height * 0.92,
      enableDrag: false,
      onClose: () => Navigator.of(context).pop(),
      onHelpPressed: () => modalKey.currentState?._showTutorial(),
      content: PaperShipLobbyModal(key: modalKey),
    );
  }

  static Future<void> _showLandscape(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width.clamp(0.0, 640.0);
    final dialogHeight = size.height * 0.92;
    final modalKey = GlobalKey<_PaperShipLobbyModalState>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: AppModal(
            isDialog: true,
            title: l10n.paperShip,
            onClose: () => Navigator.of(context).pop(),
            onHelpPressed: () => modalKey.currentState?._showTutorial(),
            content: PaperShipLobbyModal(key: modalKey),
          ),
        ),
      ),
    );
  }
}

class _PaperShipLobbyModalState extends State<PaperShipLobbyModal> {
  // ── Tutorial keys ─────────────────────────────────────────────
  final GlobalKey _createJoinKey = GlobalKey();
  final GlobalKey _playerListKey = GlobalKey();
  final GlobalKey _startKey      = GlobalKey();
  final GlobalKey _readyKey      = GlobalKey();
  final GlobalKey _sliderKey     = GlobalKey();

  void _showTutorial() {
    final l10n = AppLocalizations.of(context);
    final List<TutorialStep> steps;
    switch (_state) {
      case _LobbyState.hostLobby:
        steps = [
          TutorialStep(targetKey: _playerListKey, title: l10n.tutorialRockLobbyPlayersTitle, description: l10n.tutorialRockLobbyPlayersDesc, tag: 'ship_lobby_players'),
          TutorialStep(targetKey: _startKey,      title: l10n.tutorialRockLobbyStartTitle,   description: l10n.tutorialRockLobbyStartDesc,   tag: 'ship_lobby_start'),
        ];
      case _LobbyState.clientLobby:
        steps = [
          TutorialStep(targetKey: _playerListKey, title: l10n.tutorialRockLobbyPlayersTitle, description: l10n.tutorialRockLobbyPlayersDesc, tag: 'ship_lobby_players'),
          TutorialStep(targetKey: _readyKey,      title: l10n.tutorialRockLobbyReadyTitle,   description: l10n.tutorialRockLobbyReadyDesc,   tag: 'ship_lobby_ready'),
        ];
      default:
        steps = [
          TutorialStep(targetKey: _sliderKey,     title: l10n.tutorialPaperShipLobbyScoreTargetTitle, description: l10n.tutorialPaperShipLobbyScoreTargetDesc, tag: 'ship_lobby_target'),
          TutorialStep(targetKey: _createJoinKey, title: l10n.tutorialRockLobbyRoomTitle,             description: l10n.tutorialRockLobbyRoomDesc,             tag: 'ship_lobby_room'),
        ];
    }
    final theme = context.theme;
    TutorialOverlay(
      context: context,
      steps: steps,
      nextText: l10n.tutorialNext,
      skipText: l10n.tutorialSkip,
      finshText: l10n.tutorialGotIt,
      onComplete: () => SfxService().buttonClick(),
      tooltipBackgroundColor: theme.background,
      titleTextColor: theme.text,
      descriptionTextColor: theme.text,
      nextButtonStyle: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      skipButtonStyle: TextButton.styleFrom(foregroundColor: theme.text),
      finishButtonStyle: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ).show();
  }

  // ── FSM ──────────────────────────────────────────────────────
  _LobbyState _state = _LobbyState.idle;
  bool _transitioning = false;

  // ── Config ───────────────────────────────────────────────────
  int _scoreTarget = 0;

  // ── Metadata ─────────────────────────────────────────────────
  bool _gameStarted = false;
  List<LanHostInfo> _discoveredHosts = [];
  String? _errorMessage;
  bool _wasHost = false;
  int _reconnectAttempt = 0;
  static const int _maxReconnectAttempts = 3;
  final TextEditingController _roomIdController = TextEditingController();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LanProvider>().prepareForMultiplayer();
      _resumeState();
    });
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    _disconnectSub?.cancel();
    _snapshotAckSub?.cancel();
    _fullSnapshotSub?.cancel();
    _syncTimeoutTimer?.cancel();
    _roomIdController.dispose();
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
    if (!kIsWeb) {
      final localIp = await LanDiscovery.getLocalIp();
      if (!mounted) return;
      if (localIp == null) {
        setState(() => _errorMessage = AppLocalizations.of(context).lanNotConnected);
        return;
      }
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
        _errorMessage = lan.errorMessage ?? AppLocalizations.of(context).failedToStartServer;
      });
    }
  }

  void _onStartSolo() {
    if (_gameStarted) return;
    SfxService().buttonClick();
    final seed = math.Random().nextInt(0x7FFFFFFF);
    _openGame({'seed': seed, 'scoreTarget': _scoreTarget});
  }

  void _onStartGame() {
    if (_gameStarted) return;
    final seed = math.Random().nextInt(0x7FFFFFFF);
    context.read<GameRoomProvider>().startGame({'seed': seed, 'scoreTarget': _scoreTarget});
    SfxService().buttonClick();
    _openGame({'seed': seed, 'scoreTarget': _scoreTarget});
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
    if (hosts.isEmpty && !kIsWeb) {
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
        _errorMessage = lan.errorMessage ?? AppLocalizations.of(context).connectionFailed;
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
          _errorMessage = AppLocalizations.of(context).syncTimeout;
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
    final scoreTarget = gs['scoreTarget'] as int? ?? 0;
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
          scoreTarget: scoreTarget,
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
          scoreTarget: scoreTarget,
        );
        if (!mounted) return;
        _gameStarted = false;
        setState(() => _state =
            LanService().isActive ? _LobbyState.clientLobby : _LobbyState.idle);
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

    // Client: auto-transition when host starts game
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
      _LobbyState.idle             => _buildIdle(theme, l10n),
      _LobbyState.hostStarting     => _buildSpinner(theme, l10n, label: l10n.startServer),
      _LobbyState.hostLobby        => _buildHostLobby(theme, l10n, room),
      _LobbyState.clientScanning   => _buildSpinner(theme, l10n, label: l10n.scanning, showCancel: true),
      _LobbyState.clientScanResults => _buildScanResults(theme, l10n),
      _LobbyState.clientConnecting  => _buildSpinner(theme, l10n, label: l10n.connectingToRoom, showCancel: true),
      _LobbyState.clientPending    => _buildClientPending(theme, l10n, room),
      _LobbyState.clientLobby      => _buildClientLobby(theme, l10n, room),
      _LobbyState.disconnected     => _buildDisconnected(theme, l10n),
      _LobbyState.clientReconnecting => _buildSpinner(theme, l10n,
          label: '${l10n.reconnecting} ($_reconnectAttempt/$_maxReconnectAttempts)',
          showCancel: true),
      _LobbyState.syncing          => _buildSpinner(theme, l10n, label: l10n.syncingGame),
      _LobbyState.error            => _buildError(theme, l10n),
    };
  }

  // ─────────────────────────────────────────────────────────────
  // State widgets
  // ─────────────────────────────────────────────────────────────

  Widget _buildIdle(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section: Singleplayer ──────────────────────────────
        Text(l10n.singleplayer,
            style: AppTypography.bodyMedium(context,
                color: theme.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildScoreTargetConfig(theme, l10n),
        const SizedBox(height: 10),
        AppButton(label: l10n.start, onPressed: _onStartSolo),

        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),

        // ── Section: Multiplayer ───────────────────────────────
        Column(
          key: _createJoinKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.multiplayer,
                style: AppTypography.bodyMedium(context,
                    color: theme.text, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            AppButton(label: l10n.createRoom, onPressed: _startHosting),
            const SizedBox(height: 10),
            AppButton(label: l10n.joinGame, onPressed: _doScan),
          ],
        ),
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
            style: AppTypography.bodyMedium(context, color: theme.border)),
        if (showCancel) ...[
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _cancelAndGoIdle,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.border,
              foregroundColor: theme.background,
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
    if (kIsWeb) return _buildWebScanResults(theme, l10n);
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

  Widget _buildWebScanResults(AppTheme theme, AppLocalizations l10n) {
    final lan = context.read<LanProvider>();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.activeRooms,
              style: AppTypography.bodyMedium(context,
                  color: theme.text, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<List<LanHostInfo>>(
            stream: lan.roomStream,
            builder: (context, snapshot) {
              final hosts = snapshot.data ?? _discoveredHosts;
              if (hosts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.scanning,
                    style: AppTypography.bodySmall(context, color: theme.border),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Column(
                children: hosts
                    .map((h) => _buildHostTile(theme, l10n, h))
                    .toList(),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Text(l10n.enterRoomCode,
              style: AppTypography.bodySmall(context, color: theme.border)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _roomIdController,
                style: AppTypography.bodyMedium(context, color: theme.text),
                decoration: InputDecoration(
                  hintText: 'pp-name-1234',
                  hintStyle: AppTypography.bodyMedium(context, color: theme.border),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final code = _roomIdController.text.trim();
                if (code.isEmpty) return;
                _connectToHost(LanHostInfo(
                  ip: code,
                  wsPort: 0,
                  displayName: code,
                  avatarIndex: 0,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.background,
                minimumSize: const Size(64, 48),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.joinGame,
                  style: AppTypography.labelLarge(context,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 16),
          _buildButtonRow(theme, l10n, actionLabel: l10n.rescan, onAction: _doScan),
        ],
      ),
    );
  }

  Widget _buildRoomCodeDisplay(AppTheme theme, AppLocalizations l10n) {
    final roomId = context.read<LanProvider>().roomId ?? '...';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.roomCode,
                  style: AppTypography.bodySmall(context, color: theme.border)),
              const SizedBox(height: 2),
              Text(roomId,
                  style: AppTypography.bodyMedium(context,
                      color: theme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          color: theme.border,
          tooltip: 'Copy',
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: roomId)),
        ),
      ]),
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

  Widget _buildScoreTargetConfig(AppTheme theme, AppLocalizations l10n) {
    return AppSlider(
      key: _sliderKey,
      label: _scoreTarget == 0
          ? l10n.endless
          : '${l10n.target}: $_scoreTarget cm',
      value: _scoreTarget.toDouble(),
      min: 0,
      max: 1000,
      onChanged: (v) =>
          setState(() => _scoreTarget = (v / 200).round() * 200),
    );
  }

  Widget _buildHostLobby(AppTheme theme, AppLocalizations l10n, GameRoomProvider room) {
    final currentRoom = room.currentRoom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kIsWeb) ...[
          _buildRoomCodeDisplay(theme, l10n),
          const SizedBox(height: 16),
        ],
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
        _buildButtonRow(theme, l10n,
          rowKey: _startKey,
          actionLabel: l10n.startGame,
          onAction: (room.currentRoom?.allReady ?? false) ? _onStartGame : null,
        ),
      ],
    );
  }

  Widget _buildClientPending(AppTheme theme, AppLocalizations l10n, GameRoomProvider room) {
    final localPlayer = room.localPlayer;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        if (localPlayer != null)
          Text(
            kAvatarPresets[localPlayer.avatarIndex.clamp(0, kAvatarPresets.length - 1)],
            style: const TextStyle(fontSize: 40),
          ),
        const SizedBox(height: 12),
        Text(l10n.pendingApprovalShort,
            style: AppTypography.bodyMedium(context, color: theme.primary)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _cancelAndGoIdle,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.border,
            foregroundColor: theme.background,
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

  Widget _buildClientLobby(AppTheme theme, AppLocalizations l10n, GameRoomProvider room) {
    final localPlayer = room.localPlayer;
    final isReady = localPlayer?.isReady ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlayerList(theme, l10n, room),
        const SizedBox(height: 20),
        _buildButtonRow(theme, l10n,
          rowKey: _readyKey,
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
        const Icon(Icons.wifi_off, color: Colors.redAccent, size: 40),
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
            backgroundColor: theme.border,
            foregroundColor: theme.background,
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
        AppButton(label: l10n.ok, onPressed: _cancelAndGoIdle),
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
          onChanged: (_) => room.setRequireApproval(!currentRoom.requireApproval),
        ),
      ],
    );
  }

  Widget _buildPlayerList(AppTheme theme, AppLocalizations l10n, GameRoomProvider room) {
    final players = room.currentRoom?.activePlayers ?? [];
    final isHost = LanService().role == LanRole.host;
    return Column(
      key: _playerListKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(l10n.players,
              style: AppTypography.bodyLarge(context,
                  color: theme.text, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text('${players.length}/$kMaxRoomPlayers',
              style: AppTypography.bodySmall(context, color: theme.border)),
        ]),
        const SizedBox(height: 12),
        ...players.map((p) => _buildPlayerTile(theme, l10n, room, p, isHost)),
        if (players.length < 2)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.waitingForPlayers,
                style: AppTypography.bodySmall(context, color: theme.border)),
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
                      kAvatarPresets[p.avatarIndex.clamp(0, kAvatarPresets.length - 1)],
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(p.displayName,
                        style: AppTypography.bodyMedium(context, color: theme.text))),
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

  Widget _buildButtonRow(AppTheme theme, AppLocalizations l10n,
      {required String actionLabel, required VoidCallback? onAction, Key? rowKey}) {
    return Row(key: rowKey, children: [
      Expanded(
        child: ElevatedButton(
          onPressed: _cancelAndGoIdle,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.border,
            foregroundColor: theme.background,
            minimumSize: const Size.fromHeight(48),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(l10n.cancel,
              style: AppTypography.labelLarge(context, fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: AppButton(label: actionLabel, onPressed: onAction)),
    ]);
  }

  Widget _chip(AppTheme theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border, width: 1),
      ),
      child: Text(label,
          style: AppTypography.captionSmall(context, color: color)),
    );
  }
}
