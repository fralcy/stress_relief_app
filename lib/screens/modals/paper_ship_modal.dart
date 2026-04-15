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
import '../../core/utils/data_manager.dart';
import '../../core/utils/lan/lan_service.dart';
import '../../core/utils/lan/lan_message.dart';
import '../../core/utils/lan/game_message.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/paper_ship_world.dart';
import '../../core/utils/paper_ship_chunk.dart';
import '../../core/widgets/app_modal.dart';

// ──────────────────────────────────────────────────────────────
// PaperShipModal
// ──────────────────────────────────────────────────────────────

class PaperShipModal extends StatefulWidget {
  final int seed;
  final int localSlot;          // 1-based player slot
  final List<String> playerOrder; // uid list in slot order; empty = solo

  const PaperShipModal({
    super.key,
    required this.seed,
    this.localSlot = 1,
    this.playerOrder = const [],
  });

  @override
  State<PaperShipModal> createState() => _PaperShipModalState();

  static Future<void> show(
    BuildContext context, {
    required int seed,
    int localSlot = 1,
    List<String> playerOrder = const [],
  }) {
    final h = MediaQuery.of(context).size.height * 0.95;
    final l10n = AppLocalizations.of(context);
    final modalKey = GlobalKey<_PaperShipModalState>();
    return AppModal.show(
      context: context,
      title: l10n.paperShip,
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
      content: PaperShipModal(
        key: modalKey,
        seed: seed,
        localSlot: localSlot,
        playerOrder: playerOrder,
      ),
    );
  }
}

class _PaperShipModalState extends State<PaperShipModal>
    with TickerProviderStateMixin {

  // ── Tutorial keys ─────────────────────────────────────────
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _infoBarKey = GlobalKey();

  void _showTutorial() {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    TutorialOverlay(
      context: context,
      steps: [
        TutorialStep(
          targetKey: _canvasKey,
          title: l10n.tutorialPaperShipGameCanvasTitle,
          description: _isSolo
              ? l10n.tutorialPaperShipGameCanvasSoloDesc
              : l10n.tutorialPaperShipGameCanvasDesc,
          tag: 'paper_ship_canvas',
        ),
        TutorialStep(
          targetKey: _infoBarKey,
          title: l10n.tutorialPaperShipGameInfoTitle,
          description: l10n.tutorialPaperShipGameInfoDesc,
          tag: 'paper_ship_info',
        ),
      ],
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
  late PaperShipWorld _world;

  // ── Ticker ───────────────────────────────────────────────
  late Ticker _ticker;
  DateTime? _lastTick;
  double _accumulator = 0.0;

  // ── Canvas ───────────────────────────────────────────────
  double _canvasWidth = 0;
  double _canvasHeight = 0;

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

  // ─────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _setupLan();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _syncTimer?.cancel();
    _lanSub?.cancel();
    super.dispose();
  }

  void _initWorld() {
    _world = PaperShipWorld(
      cw: _canvasWidth,
      ch: _canvasHeight,
      seed: widget.seed,
      playerCount: widget.playerOrder.isEmpty ? 1 : widget.playerOrder.length,
    );
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
        (_) { if (_worldReady) _sendShipSync(); },
      );
    }

    _lanSub = LanService().incomingEvents.listen((event) {
      final gm = GameMessage.tryExtract(event.message);
      if (gm == null) return;

      if (gm.event == GameEvent.playerAction) {
        if (_isHost) {
          _applyPeerMessage(gm.data, event.message.senderId);
          LanService().broadcastMessage(
            GameMessage.gameState(_localId, gm.data),
          );
        }
      } else if (gm.event == GameEvent.gameState && !_isHost) {
        final fromId = gm.data['fromId'] as String? ?? '';
        _applyPeerMessage(gm.data, fromId);
      } else if (gm.event == GameEvent.fullSnapshot) {
        if (!_isHost && _worldReady) {
          setState(() => _world.applyHostSnapshot(gm.data));
        }
      } else if (gm.event == GameEvent.snapshotRequest) {
        if (_isHost && _worldReady) {
          final socketId = event.message.senderId;
          LanService().sendMessage(GameMessage.snapshotAck(_localId, socketId));
          LanService().sendMessage(GameMessage.fullSnapshot(
            _localId, socketId, _world.buildSyncPayload(),
          ));
        }
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
      case 'tapWave':
        if (_isHost) {
          final nx = (data['nx'] as num).toDouble();
          final ny = (data['ny'] as num).toDouble();
          _world.spawnWave(nx * _canvasWidth, ny * _canvasHeight, fromId);
        }
      case 'shipSync':
        if (!_isHost) {
          setState(() => _world.applyHostSnapshot(data));
        }
      case 'playerLeft':
      case 'bye':
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

  void _sendShipSync() {
    final payload = _world.buildSyncPayload();
    _sendAction({'type': 'shipSync', ...payload});
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

    _accumulator += elapsed;
    while (_accumulator >= _fixedDt) {
      if (_isHost || _isSolo) {
        _world.step(_fixedDt);
      } else {
        _world.stepClient(_fixedDt);
      }
      _accumulator -= _fixedDt;
    }

    setState(() {});
  }

  // ─────────────────────────────────────────────────────────
  // Input
  // ─────────────────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent event) {
    if (!_worldReady) return;
    _spawnLocalWave(event.localPosition.dx, event.localPosition.dy);
  }

  void _spawnLocalWave(double x, double y) {
    if (_isSolo || _isHost) {
      _world.spawnWave(x, y, _localId);
      SfxService().buttonClick();
    } else {
      // Client: send to host
      _sendAction({
        'type': 'tapWave',
        'nx': x / _canvasWidth,
        'ny': y / _canvasHeight,
      });
      SfxService().buttonClick();
    }
    HapticFeedback.lightImpact();
  }

  // ─────────────────────────────────────────────────────────
  // Game end
  // ─────────────────────────────────────────────────────────

  void _onGameEnd(Map<String, dynamic> data) {
    if (_gameEnded || !mounted) return;
    setState(() => _gameEnded = true);
    final dist = (data['dist'] as num?)?.toDouble()
        ?? (_worldReady && _canvasHeight > 0
            ? (_world.buildRenderData().distanceTraveled / _canvasHeight * 100)
            : 0.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final theme = context.theme;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: theme.background,
          title: Text(l10n.paperShip,
              style: AppTypography.bodyLarge(context,
                  color: theme.text, fontWeight: FontWeight.bold)),
          content: Text(
            '${dist.toStringAsFixed(1)} cm',
            style: AppTypography.bodyMedium(context, color: theme.text),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: Text(l10n.ok, style: TextStyle(color: theme.primary)),
            ),
            if (_isSolo)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  setState(() {
                    _gameEnded = false;
                    _worldReady = false;
                    _canvasWidth = 0;
                    _canvasHeight = 0;
                    _lastTick = null;
                    _accumulator = 0.0;
                  });
                },
                child: Text(l10n.tapToReplay,
                    style: TextStyle(color: theme.primary)),
              ),
          ],
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final snap = _worldReady ? _world.buildRenderData() : null;

    return Column(
      children: [
        // ── Info bar ─────────────────────────────────────
        Padding(
          key: _infoBarKey,
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: MediaQuery.of(context).size.height < 700 ? 2 : 6,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  snap != null
                      ? '${(_canvasHeight > 0 ? snap.distanceTraveled / _canvasHeight * 100 : 0.0).toStringAsFixed(1)} cm'
                      : '0.0 cm',
                  style: AppTypography.bodySmall(context,
                      color: theme.primary, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // End game
              if ((_isSolo || _isHost) && !_gameEnded)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    final dist = _canvasHeight > 0
                        ? (snap?.distanceTraveled ?? 0) / _canvasHeight * 100
                        : 0.0;
                    if (!_isSolo) {
                      context.read<GameRoomProvider>().endGame({'dist': dist});
                    }
                    _onGameEnd({'dist': dist});
                  },
                  child: Text(l10n.endGame,
                      style: TextStyle(color: theme.primary)),
                ),
            ],
          ),
        ),

        // ── Canvas — fixed 9:16 play area ────────────────
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 9.0 / 16.0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_canvasWidth == 0 && constraints.maxWidth > 0) {
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

                  return Listener(
                    key: _canvasKey,
                    onPointerDown: _onPointerDown,
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _PaperShipPainter(snapshot: snap),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

}

// ──────────────────────────────────────────────────────────────
// CustomPainter — 8 layers
// ──────────────────────────────────────────────────────────────

class _PaperShipPainter extends CustomPainter {
  final PaperShipRenderSnapshot? snapshot;

  static const Color _waterColor = Color(0xFF5BC8E8);
  static const Color _boatBody = Color(0xFFF5F0E8);
  static const Color _boatStroke = Color(0xFF8D6E63);
  static const Color _wakeColor = Color(0xCCFFFFFF);

  _PaperShipPainter({required this.snapshot});

  @override
  void paint(Canvas canvas, Size size) {
    // Hard clip — nothing drawn outside the 9:16 canvas bounds
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final snap = snapshot;

    // ── Layer 1: Background water ─────────────────────────
    final skyColor = snap?.skyColor ?? _waterColor;
    final waterColor = Color.lerp(_waterColor, skyColor, 0.3)!;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = waterColor,
    );

    if (snap == null) return;

    // ── Layer 2: Parallax riverbanks ─────────────────────
    _drawBanks(canvas, size, snap);

    // ── Layer 3: Wave rings ───────────────────────────────
    _drawWaves(canvas, snap);

    // ── Layer 4: Foam particles ───────────────────────────
    _drawFoam(canvas, snap);

    // ── Layer 5: Obstacles (drawn on top of waves) ────────
    _drawObstacles(canvas, snap);

    // ── Layer 6: Wake trail ───────────────────────────────
    _drawWake(canvas, snap);

    // ── Layer 7: Boat ────────────────────────────────────
    _drawBoat(canvas, snap);

    // ── Layer 8: HUD distance label ───────────────────────
    // (Rendered in Flutter widget layer — nothing needed here)
  }

  // ── Layer 2: Banks ───────────────────────────────────────

  void _drawBanks(Canvas canvas, Size size, PaperShipRenderSnapshot snap) {
    final bankColor = const Color(0xFF4CAF50).withValues(alpha: 0.35);
    final parallax = (snap.distanceTraveled * 0.3) % size.height;

    final paint = Paint()..color = bankColor;
    // Left bank
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.05, size.height), paint);
    // Right bank
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.95, 0, size.width * 0.05, size.height), paint);

    // Subtle grass tufts that scroll
    final tuffPaint = Paint()..color = const Color(0xFF388E3C).withValues(alpha: 0.5);
    for (int i = 0; i < 5; i++) {
      final y = ((i * size.height / 4) + parallax) % size.height;
      canvas.drawCircle(Offset(size.width * 0.025, y), 5, tuffPaint);
      canvas.drawCircle(Offset(size.width * 0.975, y + size.height * 0.1), 5, tuffPaint);
    }
  }

  // ── Layer 3: Waves ────────────────────────────────────────

  void _drawWaves(Canvas canvas, PaperShipRenderSnapshot snap) {
    for (final w in snap.waves) {
      if (w.opacity < 0.02) continue;

      final paint = Paint()
        ..color = w.waveColor.withValues(alpha: w.opacity * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w.strokeWidth
        ..strokeCap = StrokeCap.round;

      if (!w.blocked) {
        canvas.drawCircle(w.screenCenter, w.sigma, paint);
      } else {
        // Half-arc facing the boat
        final rect = Rect.fromCircle(center: w.screenCenter, radius: w.sigma);
        canvas.drawArc(rect, w.angleToBoat - math.pi / 2, math.pi, false, paint);
      }
    }
  }

  // ── Layer 4: Foam ─────────────────────────────────────────

  void _drawFoam(Canvas canvas, PaperShipRenderSnapshot snap) {
    final paint = Paint()..color = Colors.white;
    for (final p in snap.foam) {
      paint.color = Colors.white.withValues(alpha: p.opacity);
      canvas.drawCircle(p.screenPos, p.radius, paint);
    }
  }

  // ── Layer 5: Obstacles ────────────────────────────────────

  void _drawObstacles(Canvas canvas, PaperShipRenderSnapshot snap) {
    for (final o in snap.obstacles) {
      switch (o.type) {
        case ObstacleType.rock:
          _drawRock(canvas, o.screenPos, o.visualSize);
        case ObstacleType.lotus:
          _drawLotus(canvas, o.screenPos, o.visualSize);
        case ObstacleType.seaweed:
          _drawSeaweed(canvas, o.screenPos, o.visualSize);
        case ObstacleType.log:
          _drawLog(canvas, o.screenPos, o.visualSize, o.angle, o.halfLength);
        case ObstacleType.lilyPad:
          _drawLilyPad(canvas, o.screenPos, o.visualSize);
        case ObstacleType.whirlpool:
          _drawWhirlpool(canvas, o.screenPos, o.visualSize, o.phase);
      }
    }
  }

  void _drawRock(Canvas canvas, Offset pos, double size) {
    final path = Path();
    // Approximate rounded rock shape
    const pts = 6;
    for (int i = 0; i < pts; i++) {
      final angle = (i / pts) * 2 * math.pi - math.pi / 2;
      final r = size * (0.8 + 0.2 * ((i * 37) % 10) / 10.0);
      final p = Offset(pos.dx + math.cos(angle) * r, pos.dy + math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF78909C));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF455A64)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    // Highlight
    canvas.drawCircle(
      pos + const Offset(-2, -3),
      size * 0.2,
      Paint()..color = const Color(0xFF90A4AE).withValues(alpha: 0.6),
    );
  }

  void _drawLotus(Canvas canvas, Offset pos, double size) {
    const petalCount = 5;
    final petalPaint = Paint()..color = const Color(0xFFF48FB1);
    final petalStroke = Paint()
      ..color = const Color(0xFFAD1457)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final leafPaint = Paint()..color = const Color(0xFF66BB6A);

    // Leaf (ellipse)
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: size * 2.2, height: size * 1.6),
      leafPaint,
    );

    // Petals
    for (int i = 0; i < petalCount; i++) {
      final angle = (i / petalCount) * 2 * math.pi;
      final petalCenter = Offset(
        pos.dx + math.cos(angle) * size * 0.55,
        pos.dy + math.sin(angle) * size * 0.55,
      );
      final petalRect =
          Rect.fromCenter(center: petalCenter, width: size * 0.8, height: size * 1.1);
      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle + math.pi / 2);
      canvas.translate(-petalCenter.dx, -petalCenter.dy);
      canvas.drawOval(petalRect, petalPaint);
      canvas.drawOval(petalRect, petalStroke);
      canvas.restore();
    }

    // Centre dot
    canvas.drawCircle(pos, size * 0.25, Paint()..color = const Color(0xFFFFEE58));
  }

  void _drawSeaweed(Canvas canvas, Offset pos, double size) {
    final path = Path();
    path.moveTo(pos.dx, pos.dy + size);
    // Wavy bezier
    path.cubicTo(
      pos.dx + size * 0.8, pos.dy + size * 0.5,
      pos.dx - size * 0.8, pos.dy - size * 0.2,
      pos.dx, pos.dy - size,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF43A047)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.4
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── New obstacle renderers ────────────────────────────────

  void _drawLog(Canvas canvas, Offset pos, double size, double angle, double halfLen) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: halfLen * 2, height: size * 2),
      Radius.circular(size),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF8B5E3C));
    canvas.drawRRect(rrect, Paint()
      ..color = const Color(0xFF5C3317)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0);

    // Wood grain lines
    final grain = Paint()
      ..color = const Color(0xFF6B4226).withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (final dy in [-size * 0.45, 0.0, size * 0.45]) {
      canvas.drawLine(
        Offset(-halfLen + size, dy),
        Offset( halfLen - size, dy),
        grain,
      );
    }
    canvas.restore();
  }

  void _drawLilyPad(Canvas canvas, Offset pos, double size) {
    // Pac-Man-shaped leaf: circle with a ~60° notch at top
    const notchHalf = math.pi / 6; // 30° each side
    const startAngle = -math.pi / 2 + notchHalf; // after notch
    const sweep = 2 * math.pi - 2 * notchHalf;   // 300°

    final path = Path()..moveTo(pos.dx, pos.dy);
    path.arcTo(Rect.fromCircle(center: pos, radius: size),
        startAngle, sweep, false);
    path.close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF4CAF50));
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);

    // Vein lines from center
    final vein = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.45)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (final da in [-0.18, 0.0, 0.18]) {
      final a = -math.pi / 2 + math.pi + da; // fan toward base
      canvas.drawLine(pos,
          Offset(pos.dx + math.cos(a) * size * 0.8,
                 pos.dy + math.sin(a) * size * 0.8),
          vein);
    }
  }

  void _drawWhirlpool(Canvas canvas, Offset pos, double size, double phase) {
    // Three concentric arcs rotating at different speeds
    for (int ring = 0; ring < 3; ring++) {
      final r       = size * (0.30 + ring * 0.25);
      final rot     = phase * (1.5 - ring * 0.3);
      final opacity = (0.70 - ring * 0.15).clamp(0.1, 0.7);
      canvas.drawArc(
        Rect.fromCircle(center: pos, radius: r),
        rot,
        math.pi * 1.5, // 270° arc
        false,
        Paint()
          ..color = const Color(0xFF1565C0).withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (3.0 - ring * 0.6).clamp(1.0, 3.0)
          ..strokeCap = StrokeCap.round,
      );
    }
    // Dark center dot
    canvas.drawCircle(pos, size * 0.12,
        Paint()..color = const Color(0xFF0D47A1).withValues(alpha: 0.75));
  }

  // ── Layer 6: Wake trail ───────────────────────────────────

  void _drawWake(Canvas canvas, PaperShipRenderSnapshot snap) {
    final trail = snap.wakeTrail;
    if (trail.length < 2) return;

    for (int i = 0; i < trail.length - 1; i++) {
      final t = i / trail.length;
      final opacity = (1 - t) * 0.55;
      final strokeWidth = (1 - t) * 4.0 + 0.5;
      canvas.drawLine(
        trail[i],
        trail[i + 1],
        Paint()
          ..color = _wakeColor.withValues(alpha: opacity)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ── Layer 7: Boat ────────────────────────────────────────

  void _drawBoat(Canvas canvas, PaperShipRenderSnapshot snap) {
    canvas.save();
    canvas.translate(snap.boatPos.dx, snap.boatPos.dy);
    canvas.rotate(snap.boatAngle);

    // Shake offset
    if (snap.shakeAmount > 0.1) {
      final shakeX = (math.Random().nextDouble() - 0.5) * snap.shakeAmount * 2;
      final shakeY = (math.Random().nextDouble() - 0.5) * snap.shakeAmount * 1;
      canvas.translate(shakeX, shakeY);
    }

    _drawBoatShape(canvas);
    canvas.restore();
  }

  void _drawBoatShape(Canvas canvas) {
    // Paper boat: top-down view — elongated diamond with a small sail
    const hw = 10.0; // half-width
    const hl = 16.0; // half-length

    final hullPath = Path()
      ..moveTo(0, -hl)
      ..lineTo(hw, 0)
      ..lineTo(0, hl)
      ..lineTo(-hw, 0)
      ..close();

    canvas.drawPath(hullPath, Paint()..color = _boatBody);
    canvas.drawPath(
      hullPath,
      Paint()
        ..color = _boatStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Sail: triangle pointing up (forward)
    final sailPath = Path()
      ..moveTo(0, -hl + 2)
      ..lineTo(6, -hl * 0.3)
      ..lineTo(0, -hl * 0.3)
      ..close();

    canvas.drawPath(sailPath, Paint()..color = const Color(0xFFEF9A9A));
    canvas.drawPath(
      sailPath,
      Paint()
        ..color = _boatStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_PaperShipPainter old) => true;
}
