import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';
import 'package:flutter_tutorial_overlay/flutter_tutorial_overlay.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/game_room_provider.dart';
import '../../core/utils/asset_loader.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/lan/lan_service.dart';
import '../../core/utils/lan/lan_message.dart';
import '../../core/utils/lan/game_message.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/firefly_world.dart';
import '../../core/widgets/app_modal.dart';

// ──────────────────────────────────────────────────────────────
// FireflyModal
// ──────────────────────────────────────────────────────────────

class FireflyModal extends StatefulWidget {
  final int maxOnScreen;
  final int fireflySeed;
  final FireflyRole role;          // local player's initial role
  final int localToolId;           // 1-based slot (solo: 1 = lamp finger, LAN: player slot)
  final List<String> playerOrder;  // uid list in slot order; empty for solo
  final Map<int, FireflyRole> allRoles; // toolId → initial role; empty = solo
  final int scoreTarget;           // 0 = endless

  const FireflyModal({
    super.key,
    required this.maxOnScreen,
    required this.fireflySeed,
    required this.role,
    this.localToolId = 1,
    this.playerOrder = const [],
    this.allRoles = const {},
    this.scoreTarget = 0,
  });

  @override
  State<FireflyModal> createState() => _FireflyModalState();

  static Future<void> show(
    BuildContext context, {
    required int maxOnScreen,
    required int fireflySeed,
    required FireflyRole role,
    int localToolId = 1,
    List<String> playerOrder = const [],
    Map<int, FireflyRole> allRoles = const {},
    int scoreTarget = 0,
  }) {
    final size = MediaQuery.of(context).size;
    if (size.width >= 720 && size.width > size.height && size.height >= 600) {
      return _showLandscape(
        context,
        maxOnScreen: maxOnScreen,
        fireflySeed: fireflySeed,
        role: role,
        localToolId: localToolId,
        playerOrder: playerOrder,
        allRoles: allRoles,
        scoreTarget: scoreTarget,
      );
    }
    final modalKey = GlobalKey<_FireflyModalState>();
    final h = size.height * 0.95;
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.fireflyCatching,
      maxHeight: h,
      minHeight: h,
      scrollable: false,
      enableDrag: false,
      onHelpPressed: () => modalKey.currentState?._showTutorial(),
      onClose: () {
        showDialog(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: Text(l10n.endGame),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dCtx).pop(),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dCtx).pop();
                  Navigator.of(context).pop();
                },
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      },
      content: FireflyModal(
        key: modalKey,
        maxOnScreen: maxOnScreen,
        fireflySeed: fireflySeed,
        role: role,
        localToolId: localToolId,
        playerOrder: playerOrder,
        allRoles: allRoles,
        scoreTarget: scoreTarget,
      ),
    );
  }

  static Future<void> _showLandscape(
    BuildContext context, {
    required int maxOnScreen,
    required int fireflySeed,
    required FireflyRole role,
    int localToolId = 1,
    List<String> playerOrder = const [],
    Map<int, FireflyRole> allRoles = const {},
    int scoreTarget = 0,
  }) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width.clamp(0.0, 640.0);
    final dialogHeight = size.height * 0.92;
    final modalKey = GlobalKey<_FireflyModalState>();
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
            scrollable: false,
            title: l10n.fireflyCatching,
            onHelpPressed: () => modalKey.currentState?._showTutorial(),
            onClose: () {
              showDialog(
                context: context,
                builder: (dCtx) => AlertDialog(
                  title: Text(l10n.endGame),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dCtx).pop(),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dCtx).pop();
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.ok),
                    ),
                  ],
                ),
              );
            },
            content: FireflyModal(
              key: modalKey,
              maxOnScreen: maxOnScreen,
              fireflySeed: fireflySeed,
              role: role,
              localToolId: localToolId,
              playerOrder: playerOrder,
              allRoles: allRoles,
              scoreTarget: scoreTarget,
            ),
          ),
        ),
      ),
    );
  }
}

class _FireflyModalState extends State<FireflyModal>
    with TickerProviderStateMixin {
  // ── Tutorial keys ─────────────────────────────────────────
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _caughtKey = GlobalKey();
  final GlobalKey _brightnessKey = GlobalKey();
  final GlobalKey _toolSwitchKey = GlobalKey();

  void _showTutorial() {
    final l10n = AppLocalizations.of(context);
    final caughtDesc = widget.scoreTarget > 0
        ? l10n.tutorialFireflyGameCaughtTargetDesc
        : l10n.tutorialFireflyGameCaughtDesc;
    final List<TutorialStep> steps;
    if (_isSolo) {
      steps = [
        TutorialStep(
          targetKey: _canvasKey,
          title: l10n.tutorialFireflyGameCanvasTitle,
          description: l10n.tutorialFireflyGameCanvasSoloDesc,
          tag: 'firefly_canvas_solo',
        ),
        TutorialStep(
          targetKey: _brightnessKey,
          title: l10n.tutorialFireflyGameBrightnessTitle,
          description: l10n.tutorialFireflyGameBrightnessDesc,
          tag: 'firefly_brightness',
        ),
        TutorialStep(
          targetKey: _caughtKey,
          title: l10n.tutorialFireflyGameCaughtTitle,
          description: caughtDesc,
          tag: 'firefly_caught',
        ),
      ];
    } else if (_role == FireflyRole.lamp) {
      steps = [
        TutorialStep(
          targetKey: _canvasKey,
          title: l10n.tutorialFireflyGameCanvasTitle,
          description: l10n.tutorialFireflyGameCanvasDesc,
          tag: 'firefly_canvas_lan',
        ),
        TutorialStep(
          targetKey: _brightnessKey,
          title: l10n.tutorialFireflyGameBrightnessTitle,
          description: l10n.tutorialFireflyGameBrightnessDesc,
          tag: 'firefly_brightness',
        ),
        TutorialStep(
          targetKey: _toolSwitchKey,
          title: l10n.tutorialFireflyGameSwitchTitle,
          description: l10n.tutorialFireflyGameSwitchDesc,
          tag: 'firefly_switch',
        ),
        TutorialStep(
          targetKey: _caughtKey,
          title: l10n.tutorialFireflyGameCaughtTitle,
          description: caughtDesc,
          tag: 'firefly_caught',
        ),
      ];
    } else {
      steps = [
        TutorialStep(
          targetKey: _canvasKey,
          title: l10n.tutorialFireflyGameCanvasTitle,
          description: l10n.tutorialFireflyGameCanvasDesc,
          tag: 'firefly_canvas_lan',
        ),
        TutorialStep(
          targetKey: _toolSwitchKey,
          title: l10n.tutorialFireflyGameSwitchTitle,
          description: l10n.tutorialFireflyGameSwitchDesc,
          tag: 'firefly_switch',
        ),
        TutorialStep(
          targetKey: _caughtKey,
          title: l10n.tutorialFireflyGameCaughtTitle,
          description: caughtDesc,
          tag: 'firefly_caught',
        ),
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
      skipButtonStyle: TextButton.styleFrom(
        foregroundColor: theme.text,
      ),
      finishButtonStyle: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
    ).show();
  }

  // ── Physics ───────────────────────────────────────────────
  static const double _fixedDt = 1.0 / 60.0;
  bool _worldReady = false;
  late FireflyWorld _world;

  // ── Ticker ───────────────────────────────────────────────
  late Ticker _ticker;
  DateTime? _lastTick;
  double _accumulator = 0.0;

  // ── Canvas ───────────────────────────────────────────────
  double _canvasWidth = 0;
  double _canvasHeight = 0;

  // ── Input — solo (drag & drop) ───────────────────────────
  final Map<int, int> _pointerToTool = {};  // pointerId → toolId
  FireflyWorldRenderSnapshot? _lastSnap;

  // ── Role & brightness (mutable mid-game) ─────────────────
  late FireflyRole _role;
  double _lampBrightness = 0.0;   // 0 = attract/dim, 1 = repel/bright

  // ── LAN ──────────────────────────────────────────────────
  StreamSubscription<LanIncomingEvent>? _lanSub;
  Timer? _syncTimer;
  String get _localId {
    try { return DataManager().userProfile.id; } catch (_) { return 'local'; }
  }
  bool get _isSolo => !LanService().isActive;
  bool get _isHost => _isSolo || LanService().role == LanRole.host;


  // ── Game end ─────────────────────────────────────────────
  bool _gameEnded = false;
  double _elapsedSeconds = 0.0;

  // ─────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _role = widget.role;
    _ticker = createTicker(_onTick)..start();
    _setupLan();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _syncTimer?.cancel();
    _lanSub?.cancel();
    if (_worldReady) _world.onFireflyCaught = null;
    super.dispose();
  }

  void _initWorld() {
    _world = FireflyWorld(
      canvasWidth: _canvasWidth,
      canvasHeight: _canvasHeight,
      maxOnScreen: widget.maxOnScreen,
      seed: widget.fireflySeed,
    );
    _world.onFireflyCaught = _onFireflyCaught;

    if (_isSolo) {
      // Solo: 2 tools — finger 1 = lamp, finger 2 = jar
      _world.addTool(1, FireflyRole.lamp, Offset(_canvasWidth * 0.35, _canvasHeight * 0.5));
      _world.addTool(2, FireflyRole.jar, Offset(_canvasWidth * 0.65, _canvasHeight * 0.5));
    } else {
      // LAN: one tool per player, evenly spread
      final n = widget.playerOrder.length.clamp(1, 4);
      for (int i = 0; i < n; i++) {
        final toolId = i + 1;
        final tx = _canvasWidth * (i + 1) / (n + 1);
        final initRole = widget.allRoles[toolId]
            ?? (toolId == widget.localToolId ? widget.role : FireflyRole.lamp);
        _world.addTool(toolId, initRole, Offset(tx, _canvasHeight * 0.5));
      }
    }

    _worldReady = true;
  }

  // ─────────────────────────────────────────────────────────
  // LAN
  // ─────────────────────────────────────────────────────────

  void _setupLan() {
    if (_isSolo) return;

    if (_isHost) {
      _syncTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) { if (_worldReady) _sendFireflySync(); },
      );
    }

    _lanSub = LanService().incomingEvents.listen((event) {
      final gm = GameMessage.tryExtract(event.message);
      if (gm == null) return;

      if (gm.event == GameEvent.playerAction) {
        if (_isHost) {
          LanService().broadcastMessage(
            GameMessage.gameState(_localId, gm.data),
          );
        }
        _applyPeerMessage(gm.data, event.message.senderId);
      } else if (gm.event == GameEvent.gameState && !_isHost) {
        final fromId = gm.data['fromId'] as String? ?? '';
        _applyPeerMessage(gm.data, fromId);
      } else if (gm.event == GameEvent.gameEnd) {
        _onGameEnd(gm.data);
      }
    });
  }

  void _applyPeerMessage(Map<String, dynamic> data, String fromId) {
    if (fromId == _localId) return;
    if (!mounted || !_worldReady) return;

    final type = data['type'] as String?;
    switch (type) {
      case 'moveTool':
        final toolId = (data['toolId'] as num).toInt();
        final nx = (data['nx'] as num).toDouble();
        final ny = (data['ny'] as num).toDouble();
        final brightness = (data['brightness'] as num? ?? 0).toDouble();
        final roleStr = data['role'] as String? ?? '';
        final role = FireflyRole.values.firstWhere(
          (r) => r.name == roleStr, orElse: () => FireflyRole.lamp);
        if (_isHost) {
          _world.updateToolPos(toolId, Offset(nx * _canvasWidth, ny * _canvasHeight));
          _world.switchToolType(toolId, role);
          _world.setToolBrightness(toolId, brightness);
        }

      case 'switchTool':
        final toolId = (data['toolId'] as num).toInt();
        final roleStr = data['role'] as String? ?? '';
        final role = FireflyRole.values.firstWhere(
          (r) => r.name == roleStr, orElse: () => FireflyRole.lamp);
        setState(() => _world.switchToolType(toolId, role));

      case 'catchRequest':
        if (!_isHost) return;
        final id = (data['fireflyId'] as num).toInt();
        _world.catchFireflyById(id);
        _sendCatchEvent(id, fromId);
        _onFireflyCaught();

      case 'catchEvent':
        final id = (data['fireflyId'] as num).toInt();
        setState(() => _world.catchFireflyById(id));
        SfxService().taskComplete();
        HapticFeedback.lightImpact();

      case 'fireflySync':
        if (_isHost) return;
        final list = data['fireflies'] as List<dynamic>? ?? [];
        for (final rs in list) {
          final id = (rs['id'] as num).toInt();
          final nx = (rs['nx'] as num).toDouble();
          final ny = (rs['ny'] as num).toDouble();
          final phase = (rs['phase'] as num).toDouble();
          _world.setLerpTarget(
            id,
            Offset(nx * _canvasWidth, ny * _canvasHeight),
            phase,
          );
        }
        // Apply other players' tool positions (skip own tool to avoid jitter)
        final tools = data['tools'] as List<dynamic>? ?? [];
        for (final t in tools) {
          final toolId = (t['id'] as num).toInt();
          if (toolId == widget.localToolId) continue;
          final nx = (t['nx'] as num).toDouble();
          final ny = (t['ny'] as num).toDouble();
          final brightness = (t['brightness'] as num? ?? 0).toDouble();
          final roleStr = t['role'] as String? ?? '';
          final role = FireflyRole.values.firstWhere(
            (r) => r.name == roleStr, orElse: () => FireflyRole.lamp);
          _world.updateToolPos(toolId, Offset(nx * _canvasWidth, ny * _canvasHeight));
          _world.switchToolType(toolId, role);
          _world.setToolBrightness(toolId, brightness);
        }

      case 'playerLeft':
        final toolId = data['toolId'] as int?;
        if (toolId != null && _worldReady) {
          setState(() => _world.removeTool(toolId));
        }
        if (!_gameEnded && mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.playerLeft)),
          );
        }
    }
  }

  void _sendAction(Map<String, dynamic> data) {
    if (_isSolo) return;
    final payload = {...data, 'fromId': _localId};
    if (_isHost) {
      LanService().broadcastMessage(GameMessage.gameState(_localId, payload));
    } else {
      LanService().sendMessage(GameMessage.playerAction(_localId, payload));
    }
  }

  void _sendFireflySync() {
    final payload = _world.buildSyncPayload();
    _sendAction({'type': 'fireflySync', ...payload});
  }

  void _sendCatchEvent(int fireflyId, String caughtBy) {
    _sendAction({'type': 'catchEvent', 'fireflyId': fireflyId, 'caughtBy': caughtBy});
  }

  void _sendToolMove(Offset pos) {
    _sendAction({
      'type': 'moveTool',
      'toolId': widget.localToolId,
      'nx': pos.dx / _canvasWidth,
      'ny': pos.dy / _canvasHeight,
      'role': _role.name,
      'brightness': _role == FireflyRole.lamp ? _lampBrightness : 0.0,
    });
  }

  // ─────────────────────────────────────────────────────────
  // Ticker
  // ─────────────────────────────────────────────────────────

  void _onTick(Duration _) {
    if (!mounted || !_worldReady) return;

    final now = DateTime.now();
    if (_lastTick == null) { _lastTick = now; return; }
    final elapsed =
        (now.difference(_lastTick!).inMicroseconds / 1e6).clamp(0.0, 0.25);
    _lastTick = now;

    if (!_gameEnded) _elapsedSeconds += elapsed;

    _accumulator += elapsed;
    bool dirty = false;
    while (_accumulator >= _fixedDt) {
      if (_isHost || _isSolo) {
        dirty = _world.step(_fixedDt) || dirty;
      } else {
        dirty = _world.stepClient(_fixedDt) || dirty;
      }
      _accumulator -= _fixedDt;
    }

    // Check catches (solo or host)
    if (_isHost || _isSolo) {
      final newly = _world.checkCatch();
      if (newly.isNotEmpty && !_isSolo) {
        for (final id in newly) {
          _sendCatchEvent(id, _localId);
        }
      }
      // Auto-end when score target reached
      if (!_gameEnded && widget.scoreTarget > 0 &&
          _worldReady && _world.buildRenderData().totalCaught >= widget.scoreTarget) {
        _triggerAutoEnd();
      }
    }

    if (dirty) setState(() {});
  }

  // ─────────────────────────────────────────────────────────
  // SFX / haptics
  // ─────────────────────────────────────────────────────────

  void _onFireflyCaught() {
    if (!mounted) return;
    SfxService().taskComplete();
    HapticFeedback.lightImpact();
    setState(() {});
  }

  // ─────────────────────────────────────────────────────────
  // Game end
  // ─────────────────────────────────────────────────────────

  void _triggerAutoEnd() {
    if (_gameEnded) return;
    final caught = _worldReady ? _world.buildRenderData().totalCaught : 0;
    if (!_isSolo) {
      context.read<GameRoomProvider>().endGame({
        'caughtCount': caught,
        'elapsedSeconds': _elapsedSeconds,
      });
    }
    _onGameEnd({'caughtCount': caught, 'elapsedSeconds': _elapsedSeconds});
  }

  String _formatTime(double s) {
    final sec = s.toInt();
    final m = sec ~/ 60;
    final r = sec % 60;
    return m > 0 ? '$m:${r.toString().padLeft(2, '0')}' : '${r}s';
  }

  void _onGameEnd(Map<String, dynamic> data) {
    if (_gameEnded || !mounted) return;
    setState(() => _gameEnded = true);
    final caughtCount = (data['caughtCount'] as num?)?.toInt()
        ?? (_worldReady ? _world.buildRenderData().totalCaught : 0);
    final elapsed = (data['elapsedSeconds'] as double?) ?? _elapsedSeconds;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final theme = context.theme;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: theme.background,
          title: Text(l10n.fireflyCatching,
              style: AppTypography.bodyLarge(context,
                  color: theme.text, fontWeight: FontWeight.bold)),
          content: Text(
            widget.scoreTarget > 0
                ? '${l10n.caught}: $caughtCount\n${l10n.time}: ${_formatTime(elapsed)}'
                : '${l10n.caught}: $caughtCount',
            style: AppTypography.bodyMedium(context, color: theme.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context)
                ..pop()
                ..pop(),
              child: Text(l10n.ok, style: TextStyle(color: theme.primary)),
            ),
            if (_isSolo)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _gameEnded = false;
                    _elapsedSeconds = 0.0;
                    _worldReady = false;
                    _canvasWidth = 0;
                    _canvasHeight = 0;
                    _lastTick = null;
                    _accumulator = 0.0;
                  });
                },
                child: Text(l10n.tapToReplay, style: TextStyle(color: theme.primary)),
              ),
          ],
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────
  // Input — solo: Listener for 2 independent pointers
  // ─────────────────────────────────────────────────────────

  int? _hitTest(Offset pos) {
    final snap = _lastSnap;
    if (snap == null) return null;
    int? bestTool;
    double bestDist = double.infinity;
    for (final tool in snap.tools) {
      final r = tool.type == FireflyRole.lamp ? snap.lampRadius : snap.jarCatchRadius;
      final touchR = math.max(r, _canvasWidth * 0.12);
      final dist = (pos - tool.position).distance;
      if (dist <= touchR && dist < bestDist) {
        bestDist = dist;
        bestTool = tool.id;
      }
    }
    return bestTool;
  }

  void _onPointerDown(PointerDownEvent e) {
    if (!_worldReady) return;
    final toolId = _hitTest(e.localPosition);
    if (toolId != null) {
      _pointerToTool[e.pointer] = toolId;
      _moveTool(toolId, e.localPosition);
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_worldReady) return;
    final toolId = _pointerToTool[e.pointer];
    if (toolId != null) _moveTool(toolId, e.localPosition);
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointerToTool.remove(e.pointer);
  }

  // ─────────────────────────────────────────────────────────
  // Input — LAN: single GestureDetector for local tool
  // ─────────────────────────────────────────────────────────

  void _onLanPanUpdate(DragUpdateDetails d) {
    if (!_worldReady) return;
    final pos = _clamp(d.localPosition);
    _moveTool(widget.localToolId, pos);
    _sendToolMove(pos);
  }

  // ─────────────────────────────────────────────────────────
  // Tool control
  // ─────────────────────────────────────────────────────────

  void _moveTool(int toolId, Offset pos) {
    final clamped = _clamp(pos);
    setState(() => _world.updateToolPos(toolId, clamped));
  }

  void _switchTool() {
    setState(() {
      _role = _role == FireflyRole.lamp ? FireflyRole.jar : FireflyRole.lamp;
      _world.switchToolType(widget.localToolId, _role);
    });
    _sendAction({
      'type': 'switchTool',
      'toolId': widget.localToolId,
      'role': _role.name,
    });
  }

  void _toggleBrightness() {
    setState(() {
      _lampBrightness = _lampBrightness < 0.5 ? 1.0 : 0.0;
      if (_worldReady) _world.setToolBrightness(widget.localToolId, _lampBrightness);
    });
    // Send updated position+brightness so host knows about brightness change
    if (!_isSolo && _worldReady) {
      // Notify via moveTool with current position (dummy pan)
    }
  }

  Offset _clamp(Offset p) => Offset(
        p.dx.clamp(0, _canvasWidth),
        p.dy.clamp(0, _canvasHeight),
      );

  // ─────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final snap = _worldReady ? _world.buildRenderData() : null;
    _lastSnap = snap;

    return Column(
      children: [
        // ── Info bar ─────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: MediaQuery.of(context).size.height < 700 ? 2 : 6,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  key: _caughtKey,
                  widget.scoreTarget > 0
                      ? '${l10n.caught}: ${snap?.totalCaught ?? 0}/${widget.scoreTarget}  |  ${l10n.time}: ${_formatTime(_elapsedSeconds)}'
                      : '${l10n.caught}: ${snap?.totalCaught ?? 0}',
                  style: AppTypography.bodySmall(context,
                      color: theme.primary, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Brightness toggle (only when current role is lamp, or solo)
              if (_isSolo || _role == FireflyRole.lamp)
                GestureDetector(
                  key: _brightnessKey,
                  onTap: _toggleBrightness,
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _lampBrightness < 0.5 ? l10n.attractShort : l10n.repelShort,
                      style: AppTypography.bodySmall(context, color: theme.primary),
                    ),
                  ),
                ),
              // Switch tool (LAN only)
              if (!_isSolo)
                GestureDetector(
                  key: _toolSwitchKey,
                  onTap: _switchTool,
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _role == FireflyRole.lamp ? l10n.lamp : l10n.jar,
                      style: AppTypography.bodySmall(context, color: theme.primary),
                    ),
                  ),
                ),
              // End game (host LAN or solo)
              if ((_isSolo || _isHost) && !_gameEnded)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _triggerAutoEnd,
                  child: Text(l10n.endGame,
                      style: TextStyle(color: theme.primary)),
                ),
            ],
          ),
        ),

        // ── Canvas ───────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_canvasWidth == 0) {
                _canvasWidth = constraints.maxWidth;
                _canvasHeight = constraints.maxHeight;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_worldReady) setState(_initWorld);
                });
              }

              if (!_worldReady) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: theme.primary),
                      const SizedBox(height: 12),
                      Text(l10n.gameLoading,
                          style: AppTypography.bodySmall(context,
                              color: theme.border)),
                    ],
                  ),
                );
              }

              Widget canvas = Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      AssetLoader.getFireflyBgAsset(
                        DataManager().userSettings.currentScenes[0].sceneSet,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => ColoredBox(color: theme.background),
                    ),
                  ),
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _FireflyPainter(
                      snapshot: snap,
                      primaryColor: theme.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              );

              if (_isSolo) {
                return Listener(
                  key: _canvasKey,
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  child: canvas,
                );
              }

              return GestureDetector(
                key: _canvasKey,
                onPanUpdate: _onLanPanUpdate,
                child: canvas,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CustomPainter
// ──────────────────────────────────────────────────────────────

class _FireflyPainter extends CustomPainter {
  final FireflyWorldRenderSnapshot? snapshot;
  final Color primaryColor;
  final Color backgroundColor;

  static const Color _fireflyColor = Color(0xFFCCFF66); // warm yellow-green
  static const Color _litFireflyColor = Color(0xFFFFFF99); // brighter when lit

  _FireflyPainter({
    required this.snapshot,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Background ──────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    if (snapshot == null) return;
    final snap = snapshot!;

    // ── Tools ────────────────────────────────────────────
    for (final tool in snap.tools) {
      if (tool.type == FireflyRole.lamp) {
        _drawLamp(canvas, tool, snap.lampRadius);
      } else {
        _drawJar(canvas, tool, snap.jarCatchRadius);
      }
    }

    // ── Fireflies ────────────────────────────────────────
    for (final f in snap.fireflies) {
      final s = math.sin(f.glowPhase);
      final haloRadius = 3.5 + 2.0 * s;
      final sigma = 4.0 + 2.5 * s;
      final haloOpacity = (0.15 + 0.35 * ((s + 1) / 2));  // 0.15..0.5
      final baseColor = f.isLit ? _litFireflyColor : _fireflyColor;

      // Glow halo (pulsing, can go dim but never fully gone)
      canvas.drawCircle(
        f.position,
        haloRadius + sigma * 1.5,
        Paint()
          ..color = baseColor.withValues(alpha: haloOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
      // Core dot — always 2.5px, always visible
      canvas.drawCircle(
        f.position,
        2.5,
        Paint()..color = baseColor.withValues(alpha: 0.85),
      );
    }

  }

  void _drawLamp(Canvas canvas, ToolRenderData tool, double glowRadius) {
    final lampAlpha = 0.10 + tool.brightness * 0.22;
    final lampPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          tool.lampColor.withValues(alpha: lampAlpha),
          tool.lampColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: tool.position,
        radius: glowRadius,
      ));
    canvas.drawCircle(tool.position, glowRadius, lampPaint);
    canvas.drawCircle(
      tool.position,
      10,
      Paint()..color = tool.lampColor.withValues(alpha: 0.9),
    );
  }

  void _drawJar(Canvas canvas, ToolRenderData tool, double jarRadius) {
    canvas.drawCircle(
      tool.position,
      jarRadius,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      tool.position,
      jarRadius,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(_FireflyPainter old) => true;
}
