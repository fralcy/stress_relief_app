import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_typography.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/game_room_provider.dart';
import '../../core/utils/lan/lan_service.dart';
import '../../core/utils/lan/game_room.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/data_manager.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_modal.dart';
import 'rock_balancing_modal.dart';

/// Lobby trước khi bắt đầu trò Xếp Đá.
///
/// Host: chỉnh số viên đá (4–10) + chờ client ready → Start.
/// Client: bấm Ready + chờ host start.
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
  int _rockCount = 4;
  bool _gameStarted = false;

  bool get _isHost => LanService().role == LanRole.host;

  String get _localUid => DataManager().userProfile.id;

  String get _localName => DataManager().userProfile.name;

  @override
  void initState() {
    super.initState();
    final room = context.read<GameRoomProvider>();
    if (_isHost) {
      room.init(_localUid, _localName);
      room.createRoom(GameType.rockBalancing);
    } else {
      room.init(_localUid, _localName);
      room.joinRoom();
    }
  }

  void _onStartGame(BuildContext context) {
    if (_gameStarted) return;
    _gameStarted = true;
    final seed = DateTime.now().millisecondsSinceEpoch;
    context.read<GameRoomProvider>().startGame({
      'rockCount': _rockCount,
      'rockSeed': seed,
    });
    SfxService().buttonClick();
    Navigator.of(context).pop();
    RockBalancingModal.show(context, rockCount: _rockCount, rockSeed: seed);
  }

  void _onClientGameStart(BuildContext context, Map<String, dynamic> gs) {
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

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final room = context.watch<GameRoomProvider>();
    final currentRoom = room.currentRoom;

    // Client: chuyển sang game khi host bắt đầu
    if (!_isHost && currentRoom?.status == GameRoomStatus.playing) {
      _onClientGameStart(context, room.gameState);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPlayerList(theme, l10n, room),
        const SizedBox(height: 20),
        if (_isHost) _buildRockCountConfig(theme, l10n),
        const SizedBox(height: 24),
        _buildActionButton(context, theme, l10n, room),
      ],
    );
  }

  Widget _buildPlayerList(
    AppTheme theme,
    AppLocalizations l10n,
    GameRoomProvider room,
  ) {
    final players = room.currentRoom?.players ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.players,
          style: AppTypography.bodyLarge(context,
              color: theme.text, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...players.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      p.displayName.isNotEmpty
                          ? p.displayName[0].toUpperCase()
                          : '?',
                      style: AppTypography.bodyLarge(context,
                          color: theme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(p.displayName,
                        style: AppTypography.bodyMedium(context,
                            color: theme.text)),
                  ),
                  if (p.isHost)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(l10n.lobbyHost,
                          style: AppTypography.captionSmall(context,
                              color: theme.primary)),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    p.isReady
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: p.isReady ? Colors.green : theme.border,
                    size: 20,
                  ),
                ],
              ),
            )),
        if (players.length < 2)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.waitingForPlayers,
              style: AppTypography.bodySmall(context,
                  color: theme.text.withValues(alpha: 0.5)),
            ),
          ),
      ],
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
    BuildContext context,
    AppTheme theme,
    AppLocalizations l10n,
    GameRoomProvider room,
  ) {
    if (_isHost) {
      final canStart = room.currentRoom?.allReady ?? false;
      return AppButton(
        label: l10n.startGame,
        onPressed: canStart ? () => _onStartGame(context) : null,
      );
    } else {
      final isReady = room.localPlayer?.isReady ?? false;
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
