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
import '../../core/utils/lan/lan_host_info.dart';
import '../../core/utils/lan/game_room.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/constants/avatar_presets.dart';
import '../../core/utils/data_manager.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_modal.dart';
import 'rock_balancing_modal.dart';

enum _LobbyPhase {
  /// Chọn Host hoặc Join (chưa kết nối LAN)
  setup,

  /// Đang kết nối / đang scan
  connecting,

  /// LAN đã kết nối — hiện danh sách player + cấu hình
  ready,
}

/// Lobby trước khi bắt đầu trò Xếp Đá.
class RockBalancingLobbyModal extends StatefulWidget {
  const RockBalancingLobbyModal({super.key});

  @override
  State<RockBalancingLobbyModal> createState() =>
      _RockBalancingLobbyModalState();

  static Future<void> show(BuildContext context) {
    return AppModal.show(
      context: context,
      title: AppLocalizations.of(context).rockBalancing,
      content: const RockBalancingLobbyModal(),
    );
  }
}

class _RockBalancingLobbyModalState extends State<RockBalancingLobbyModal> {
  _LobbyPhase _phase = _LobbyPhase.setup;
  int _rockCount = 4;
  bool _gameStarted = false;
  List<LanHostInfo> _discoveredHosts = [];
  String? _errorMessage;

  StreamSubscription<LobbyErrorType>? _errorSub;

  bool get _isLanActive => LanService().isActive;
  bool get _isHost => LanService().role == LanRole.host;
  String get _localUid => DataManager().userProfile.id;
  String get _localName => DataManager().userProfile.name;
  int get _localAvatarIndex => DataManager().userProfile.resolvedAvatarIndex;

  @override
  void initState() {
    super.initState();
    if (_isLanActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _enterReadyPhase());
    }
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    super.dispose();
  }

  // ==================== LAN ACTIONS ====================

  Future<void> _startHosting() async {
    setState(() {
      _phase = _LobbyPhase.connecting;
      _errorMessage = null;
    });
    final lan = context.read<LanProvider>();
    await lan.startHosting(displayName: _localName);
    if (!mounted) return;
    if (lan.isActive) {
      _enterReadyPhase();
    } else {
      setState(() {
        _phase = _LobbyPhase.setup;
        _errorMessage = lan.errorMessage;
      });
    }
  }

  Future<void> _scanForHosts() async {
    setState(() {
      _phase = _LobbyPhase.connecting;
      _errorMessage = null;
      _discoveredHosts = [];
    });
    final lan = context.read<LanProvider>();
    await lan.scanForHosts();
    if (!mounted) return;
    setState(() {
      _discoveredHosts = lan.discoveredHosts;
      _phase = _LobbyPhase.setup;
      if (_discoveredHosts.isEmpty) {
        _errorMessage = AppLocalizations.of(context).lanNotConnected;
      }
    });
  }

  Future<void> _connectToHost(LanHostInfo host) async {
    setState(() {
      _phase = _LobbyPhase.connecting;
      _errorMessage = null;
    });
    final lan = context.read<LanProvider>();
    await lan.connect(host);
    if (!mounted) return;
    if (lan.isActive) {
      _enterReadyPhase();
    } else {
      setState(() {
        _phase = _LobbyPhase.setup;
        _errorMessage = lan.errorMessage;
      });
    }
  }

  void _enterReadyPhase() {
    final room = context.read<GameRoomProvider>();
    room.init(_localUid, _localName, _localAvatarIndex);
    if (_isHost) {
      room.createRoom(GameType.rockBalancing);
    } else {
      room.joinRoom();
      // Subscribe để biết khi bị từ chối / kick
      _errorSub = room.lobbyErrors.listen(_onLobbyError);
    }
    setState(() => _phase = _LobbyPhase.ready);
  }

  void _onLobbyError(LobbyErrorType type) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final msg = type == LobbyErrorType.kicked ? l10n.kickedByHost : l10n.deniedByHost;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              Navigator.of(context).pop(); // đóng lobby
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  // ==================== GAME START ====================

  void _onStartGame() {
    if (_gameStarted) return;
    _gameStarted = true;
    final seed = DateTime.now().millisecondsSinceEpoch;
    context.read<GameRoomProvider>().startGame({
      'rockCount': _rockCount,
      'rockSeed': seed,
    });
    SfxService().buttonClick();
    final rockCount = _rockCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      RockBalancingModal.show(context, rockCount: rockCount, rockSeed: seed);
    });
  }

  void _onClientGameStart(Map<String, dynamic> gs) {
    if (_gameStarted) return;
    _gameStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      RockBalancingModal.show(
        context,
        rockCount: gs['rockCount'] as int? ?? 4,
        rockSeed: gs['rockSeed'] as int? ?? 0,
      );
    });
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final room = context.watch<GameRoomProvider>();

    if (_phase == _LobbyPhase.ready &&
        !_isHost &&
        room.currentRoom?.status == GameRoomStatus.playing) {
      _onClientGameStart(room.gameState);
    }

    return switch (_phase) {
      _LobbyPhase.setup => _buildSetupPhase(theme, l10n),
      _LobbyPhase.connecting => _buildConnecting(theme, l10n),
      _LobbyPhase.ready => _buildReadyPhase(theme, l10n, room),
    };
  }

  // ==================== PHASE: SETUP ====================

  Widget _buildSetupPhase(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '🪨  ${l10n.rockBalancing}',
          style: AppTypography.bodyLarge(context,
              color: theme.text, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.waitingForPlayers,
          style: AppTypography.bodySmall(context,
              color: theme.text.withValues(alpha: 0.5)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppButton(label: '📡  ${l10n.lobbyHost}', onPressed: _startHosting),
        const SizedBox(height: 12),
        AppButton(label: '🔍  ${l10n.joinGame}', onPressed: _scanForHosts),
        if (_discoveredHosts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Hosts found:',
              style: AppTypography.bodySmall(context,
                  color: theme.text.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          ..._discoveredHosts.map(
            (host) => GestureDetector(
              onTap: () => _connectToHost(host),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi, color: theme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        host.displayName.isNotEmpty
                            ? host.displayName
                            : host.ip,
                        style: AppTypography.bodyMedium(context,
                            color: theme.text),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: theme.text.withValues(alpha: 0.4), size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!,
              style:
                  AppTypography.bodySmall(context, color: Colors.redAccent),
              textAlign: TextAlign.center),
        ],
      ],
    );
  }

  // ==================== PHASE: CONNECTING ====================

  Widget _buildConnecting(AppTheme theme, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        CircularProgressIndicator(color: theme.primary),
        const SizedBox(height: 20),
        Text(l10n.waitingForPlayers,
            style: AppTypography.bodyMedium(context,
                color: theme.text.withValues(alpha: 0.6))),
        const SizedBox(height: 16),
      ],
    );
  }

  // ==================== PHASE: READY ====================

  Widget _buildReadyPhase(
    AppTheme theme,
    AppLocalizations l10n,
    GameRoomProvider room,
  ) {
    final currentRoom = room.currentRoom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Host: toggle require approval
        if (_isHost && currentRoom != null) ...[
          _buildApprovalToggle(theme, l10n, room, currentRoom),
          const SizedBox(height: 16),
        ],

        // Player list (active)
        _buildPlayerList(theme, l10n, room),

        // Pending list (host only, khi requireApproval bật)
        if (_isHost && (currentRoom?.pendingPlayers.isNotEmpty ?? false)) ...[
          const SizedBox(height: 16),
          _buildPendingList(theme, l10n, room, currentRoom!),
        ],

        const SizedBox(height: 20),
        if (_isHost) _buildRockCountConfig(theme, l10n),
        const SizedBox(height: 24),
        _buildActionButton(theme, l10n, room),
      ],
    );
  }

  Widget _buildApprovalToggle(
    AppTheme theme,
    AppLocalizations l10n,
    GameRoomProvider room,
    GameRoom currentRoom,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.requireApproval,
            style: AppTypography.bodyMedium(context, color: theme.text),
          ),
        ),
        Switch(
          value: currentRoom.requireApproval,
          activeThumbColor: theme.primary,
          onChanged: (_) => room.setRequireApproval(!currentRoom.requireApproval),
        ),
      ],
    );
  }

  Widget _buildPlayerList(
    AppTheme theme,
    AppLocalizations l10n,
    GameRoomProvider room,
  ) {
    final players = room.currentRoom?.activePlayers ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.players,
              style: AppTypography.bodyLarge(context,
                  color: theme.text, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Text(
              '${players.length}/$kMaxRoomPlayers',
              style: AppTypography.bodySmall(context,
                  color: theme.text.withValues(alpha: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...players.map((p) => _buildPlayerTile(theme, l10n, room, p)),
        if (players.length < 2)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.waitingForPlayers,
              style: AppTypography.bodySmall(context,
                  color: theme.text.withValues(alpha: 0.5)),
            ),
          ),

        // Client: trạng thái pending của chính mình
        if (!_isHost && (room.localPlayer?.isPending ?? false))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.pendingApproval,
              style: AppTypography.bodySmall(context,
                  color: theme.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerTile(
    AppTheme theme,
    AppLocalizations l10n,
    GameRoomProvider room,
    GamePlayer p,
  ) {
    final isLocalHost = _isHost && !p.isHost;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          // Avatar
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
                style: AppTypography.bodyMedium(context, color: theme.text)),
          ),
          if (p.isHost)
            _chip(theme, l10n.lobbyHost, theme.primary),
          const SizedBox(width: 8),
          // Ready icon (always visible)
          Icon(
            p.isReady
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: p.isReady ? Colors.green : theme.border,
            size: 20,
          ),
          // Kick button (host only, not self)
          if (isLocalHost) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => room.kickPlayer(p.id),
              child: _chip(theme, l10n.kickLabel, Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingList(
    AppTheme theme,
    AppLocalizations l10n,
    GameRoomProvider room,
    GameRoom currentRoom,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⏳  ${l10n.pendingApproval}',
          style: AppTypography.bodyMedium(context,
              color: theme.text, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...currentRoom.pendingPlayers.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.border.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
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
                        style: AppTypography.bodyMedium(context,
                            color: theme.text.withValues(alpha: 0.7))),
                  ),
                  // Approve
                  GestureDetector(
                    onTap: () => room.approvePlayer(p.id),
                    child: _chip(theme, l10n.approveLabel, Colors.green),
                  ),
                  const SizedBox(width: 6),
                  // Deny
                  GestureDetector(
                    onTap: () => room.kickPlayer(p.id),
                    child: _chip(theme, l10n.kickLabel, Colors.red),
                  ),
                ],
              ),
            )),
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

  Widget _buildRockCountConfig(AppTheme theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.rockCount}: $_rockCount',
          style: AppTypography.bodyLarge(context,
              color: theme.text, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('4',
                style: AppTypography.bodySmall(context,
                    color: theme.text.withValues(alpha: 0.5))),
            Expanded(
              child: Slider(
                value: _rockCount.toDouble(),
                min: 4,
                max: 10,
                divisions: 6,
                activeColor: theme.primary,
                inactiveColor: theme.border,
                onChanged: (v) => setState(() => _rockCount = v.round()),
              ),
            ),
            Text('10',
                style: AppTypography.bodySmall(context,
                    color: theme.text.withValues(alpha: 0.5))),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    AppTheme theme,
    AppLocalizations l10n,
    GameRoomProvider room,
  ) {
    if (_isHost) {
      final canStart = room.currentRoom?.allReady ?? false;
      return AppButton(
        label: l10n.startGame,
        onPressed: canStart ? _onStartGame : null,
      );
    } else {
      final localPlayer = room.localPlayer;
      final isPending = localPlayer?.isPending ?? true;
      if (isPending) {
        // Đang chờ xác nhận — không cho bấm Ready
        return const SizedBox.shrink();
      }
      final isReady = localPlayer?.isReady ?? false;
      return AppButton(
        label: isReady ? l10n.notReadyLabel : l10n.readyLabel,
        onPressed: () {
          room.setReady(!isReady);
          SfxService().buttonClick();
        },
      );
    }
  }
}
