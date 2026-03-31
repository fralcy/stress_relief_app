import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
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
import '../../core/utils/physics_utils.dart';
import '../../core/utils/rock_physics_world.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/floating_label_anim.dart';
import '../../core/widgets/sparkle_burst.dart';

// ──────────────────────────────────────────────────────────────
// Celebration animation bundle
// ──────────────────────────────────────────────────────────────

class _CelebAnim {
  final AnimationController sparkleCtrl;
  final AnimationController labelCtrl;
  final Offset origin;
  final String label;
  Timer? cleanup;

  _CelebAnim({
    required this.sparkleCtrl,
    required this.labelCtrl,
    required this.origin,
    required this.label,
  });
}

// ──────────────────────────────────────────────────────────────
// RockBalancingModal
// ──────────────────────────────────────────────────────────────

class RockBalancingModal extends StatefulWidget {
  final int rockCount;
  final int rockSeed;

  const RockBalancingModal({
    super.key,
    required this.rockCount,
    required this.rockSeed,
  });

  @override
  State<RockBalancingModal> createState() => _RockBalancingModalState();

  static Future<void> show(
    BuildContext context, {
    required int rockCount,
    required int rockSeed,
  }) {
    final h = MediaQuery.of(context).size.height * 0.95;
    final l10n = AppLocalizations.of(context);
    final modalKey = GlobalKey<_RockBalancingModalState>();
    return AppModal.show(
      context: context,
      title: l10n.rockBalancing,
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
      content: RockBalancingModal(key: modalKey, rockCount: rockCount, rockSeed: rockSeed),
    );
  }
}

class _RockBalancingModalState extends State<RockBalancingModal>
    with TickerProviderStateMixin {
  // ── Tutorial keys ─────────────────────────────────────────────
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _infoBarKey = GlobalKey();

  void _showTutorial() {
    final l10n = AppLocalizations.of(context);
    TutorialOverlay(
      context: context,
      steps: [
        TutorialStep(
          targetKey: _canvasKey,
          title: l10n.tutorialRockGameCanvasTitle,
          description: _isSolo
              ? l10n.tutorialRockGameCanvasSoloDesc
              : l10n.tutorialRockGameCanvasDesc,
          tag: 'rock_game_canvas',
        ),
        TutorialStep(
          targetKey: _infoBarKey,
          title: l10n.tutorialRockGameInfoTitle,
          description: l10n.tutorialRockGameInfoDesc,
          tag: 'rock_game_info',
        ),
      ],
      nextText: l10n.tutorialNext,
      skipText: l10n.tutorialSkip,
      finshText: l10n.tutorialGotIt,
      onComplete: () => SfxService().buttonClick(),
    ).show();
  }

  // ── Physics constants ─────────────────────────────────────────
  static const double _groundThickness = 20.0;
  static const double _fixedDt = 1.0 / 60.0;

  // ── Physics world ─────────────────────────────────────────────
  bool _physicsReady = false;
  late RockPhysicsWorld _physicsWorld;

  // ── Ticker ───────────────────────────────────────────────────
  late Ticker _ticker;
  DateTime? _lastTick;
  double _accumulator = 0.0;

  // ── Canvas (9:16 aspect, fitted to modal content area) ───────
  double _canvasWidth = 0;
  double _canvasHeight = 0;
  double get _groundY => _canvasHeight - _groundThickness;
  // Area-coverage model: estimate pyramid layers = sqrt(n) × 1.5,
  // add 2 safety layers, then derive radius from canvas height.
  // Also cap at canvasW/6 so rocks never exceed 1/3 of canvas width.
  double get _rockRadius {
    if (_canvasHeight == 0) return 20.0;
    final layers = math.sqrt(widget.rockCount.toDouble()) * 1.5 + 2;
    final fromHeight = _canvasHeight / (layers * 2);
    final fromWidth = _canvasWidth / 6;
    return math.min(fromHeight, fromWidth);
  }

  // ── Drag ─────────────────────────────────────────────────────
  int? _draggedId;
  Offset _dragTouchOffset = Offset.zero;
  Offset _prevDragPos = Offset.zero;
  DateTime _prevDragTime = DateTime.now();
  Offset _dragVel = Offset.zero;
  Timer? _dragSyncTimer;

  // ── LAN ──────────────────────────────────────────────────────
  StreamSubscription<LanIncomingEvent>? _lanSub;
  Timer? _snapshotTimer;
  Timer? _periodicSyncTimer;
  String get _localId {
    try {
      return DataManager().userProfile.id;
    } catch (_) {
      return 'local_player';
    }
  }

  bool get _isSolo => !LanService().isActive;
  bool get _isHost => _isSolo || LanService().role == LanRole.host;

  // ── SFX debounce ─────────────────────────────────────────────
  DateTime _lastRockHitSfx = DateTime(0);
  DateTime _lastRockLandSfx = DateTime(0);

  // ── Ghost / record ───────────────────────────────────────────
  double _bestHeight = 0;
  bool _borderFlash = false;
  Timer? _borderFlashTimer;

  // ── Celebrations ─────────────────────────────────────────────
  final List<_CelebAnim> _celebs = [];

  // ── Game end ─────────────────────────────────────────────────
  bool _gameEnded = false;

  // ── Rock colors (earthy tones) ───────────────────────────────
  static const _rockColors = [
    Color(0xFF8D6E63),
    Color(0xFF78909C),
    Color(0xFF546E7A),
    Color(0xFFA1887F),
    Color(0xFF607D8B),
    Color(0xFF795548),
    Color(0xFF90A4AE),
    Color(0xFF6D4C41),
    Color(0xFF80CBC4),
    Color(0xFFB0BEC5),
  ];

  // ─────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _setupLan();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _lanSub?.cancel();
    _dragSyncTimer?.cancel();
    _snapshotTimer?.cancel();
    _periodicSyncTimer?.cancel();
    _borderFlashTimer?.cancel();
    for (final c in _celebs) {
      c.sparkleCtrl.dispose();
      c.labelCtrl.dispose();
      c.cleanup?.cancel();
    }
    if (_physicsReady) _physicsWorld.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Rock generation (called after canvas size is known)
  // ─────────────────────────────────────────────────────────────

  void _generateRocks() {
    _physicsWorld = RockPhysicsWorld(
      canvasWidth: _canvasWidth,
      canvasHeight: _canvasHeight,
    );
    _physicsWorld.onRockHit = () {
      final now = DateTime.now();
      if (now.difference(_lastRockHitSfx).inMilliseconds > 250) {
        _lastRockHitSfx = now;
        SfxService().rockHit();
      }
    };
    _physicsWorld.onRockLand = () {
      final now = DateTime.now();
      if (now.difference(_lastRockLandSfx).inMilliseconds > 300) {
        _lastRockLandSfx = now;
        SfxService().rockLand();
      }
    };

    final rng = math.Random(widget.rockSeed);
    final r = _rockRadius;
    final spacing = _canvasWidth / (widget.rockCount + 1);

    for (int i = 0; i < widget.rockCount; i++) {
      // Generate hull at a fixed canonical radius so the convex hull computation
      // is identical on all devices (floating-point rounding in _cross is
      // deterministic regardless of screen size). Scale to local pixel radius after.
      const canonicalRadius = 100.0;
      final unitVerts = randomConvexPolygon(seed: widget.rockSeed, index: i, radius: canonicalRadius);
      final scale = r / canonicalRadius;
      final verts = unitVerts.map((v) => v * scale).toList();
      final x = spacing * (i + 1) + (rng.nextDouble() - 0.5) * spacing * 0.3;
      final y = _groundY - r - 2;
      final spawnAngle = (rng.nextDouble() - 0.5) * 0.4;

      _physicsWorld.addRock(
        id: i,
        localVertsPixels: verts,
        color: _rockColors[i % _rockColors.length],
        spawnPosPixels: Offset(x.clamp(r, _canvasWidth - r), y),
        spawnAngle: spawnAngle,
      );
    }

    _physicsReady = true;
  }

  // ─────────────────────────────────────────────────────────────
  // LAN
  // ─────────────────────────────────────────────────────────────

  void _setupLan() {
    if (_isSolo) return;
    if (_isHost) {
      _periodicSyncTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) { if (_physicsReady) _sendPeriodicSync(); },
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
    if (!mounted || !_physicsReady) return;

    final type = data['type'] as String?;
    final id = data['rockId'] as int? ?? -1;

    switch (type) {
      case 'lockRock':
        if (!_physicsWorld.rockIds.contains(id)) return;
        final lockNormX = (data['x'] as num?)?.toDouble();
        final lockNormY = (data['y'] as num?)?.toDouble();
        final lockAngle = (data['angle'] as num? ?? 0).toDouble();
        setState(() {
          _physicsWorld.setRockLockedBy(id, fromId);
          _physicsWorld.grabByPeer(id);
          if (lockNormX != null && lockNormY != null) {
            _physicsWorld.setLerpTarget(id, lockNormX, lockNormY, lockAngle);
          }
        });

      case 'dragUpdate':
        if (!_physicsWorld.rockIds.contains(id)) return;
        if (id == _draggedId) return; // don't overwrite our own drag
        _physicsWorld.setLerpTarget(
          id,
          (data['x'] as num).toDouble(),   // normX
          (data['y'] as num).toDouble(),   // normY
          (data['angle'] as num? ?? 0).toDouble(), // world angle
        );

      case 'releaseRock':
        if (!_physicsWorld.rockIds.contains(id)) return;
        final normX = (data['x'] as num).toDouble();
        final normY = (data['y'] as num).toDouble();
        final worldAngle = (data['angle'] as num? ?? 0).toDouble();
        final normVx = (data['vx'] as num? ?? 0).toDouble();
        final normVy = (data['vy'] as num? ?? 0).toDouble();
        final worldOmega = (data['omega'] as num? ?? 0).toDouble();
        setState(() {
          _physicsWorld.teleportRock(id, normX, normY, worldAngle);
          // normVx * cw / ppm = normVx * cw / (ch/16) = normVx * 9.0 m/s (device-independent)
          _physicsWorld.releaseRockDirect(
            id,
            normVx * 9.0,
            -normVy * 16.0, // flip Y; normVy * ch / (ch/16) = normVy * 16.0
            worldOmega,
          );
          _physicsWorld.setRockLockedBy(id, null);
        });

      case 'snapshot':
        final list = data['rocks'] as List<dynamic>? ?? [];
        for (final rs in list) {
          final rid = rs['id'] as int? ?? -1;
          if (!_physicsWorld.rockIds.contains(rid)) continue;
          // Teleport directly — rocks are already settled, no lerp needed.
          _physicsWorld.teleportRock(
            rid,
            (rs['x'] as num).toDouble(),
            (rs['y'] as num).toDouble(),
            (rs['angle'] as num? ?? 0).toDouble(),
          );
        }

      case 'periodicSync':
        final syncList = data['rocks'] as List<dynamic>? ?? [];
        for (final rs in syncList) {
          final rid = rs['id'] as int? ?? -1;
          if (!_physicsWorld.rockIds.contains(rid)) continue;
          _physicsWorld.applyDriftCorrection(
            rid,
            (rs['x'] as num).toDouble(),
            (rs['y'] as num).toDouble(),
            (rs['angle'] as num? ?? 0).toDouble(),
          );
        }

      case 'newRecord':
        final bh = (data['bestHeight'] as num? ?? 0).toDouble() * _canvasHeight;
        if (bh > _bestHeight) {
          setState(() => _bestHeight = bh);
          _triggerCelebration();
        }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Send helpers
  // ─────────────────────────────────────────────────────────────

  void _sendAction(Map<String, dynamic> data) {
    if (_isSolo) return;
    final payload = {...data, 'fromId': _localId};
    if (_isHost) {
      LanService().broadcastMessage(GameMessage.gameState(_localId, payload));
    } else {
      LanService().sendMessage(GameMessage.playerAction(_localId, payload));
    }
  }

  void _sendLockRock(int id) {
    final norm = _physicsWorld.getRockNormPos(id);
    _sendAction({
      'type': 'lockRock',
      'rockId': id,
      'x': norm.dx,
      'y': norm.dy,
      'angle': _physicsWorld.getRockWorldAngle(id),
    });
  }

  // Positions sent as normalised canvas fractions (0–1) so they are
  // device-independent. Angles sent in world-space CCW radians.
  void _sendDragUpdate(int id) {
    final norm = _physicsWorld.getRockNormPos(id);
    _sendAction({
      'type': 'dragUpdate',
      'rockId': id,
      'x': norm.dx,
      'y': norm.dy,
      'angle': _physicsWorld.getRockWorldAngle(id),
    });
  }

  void _sendReleaseRock(int id, Offset vel, double screenOmega) {
    final norm = _physicsWorld.getRockNormPos(id);
    _sendAction({
      'type': 'releaseRock',
      'rockId': id,
      'x': norm.dx,
      'y': norm.dy,
      'angle': _physicsWorld.getRockWorldAngle(id), // góc tại thời điểm thả
      'vx': vel.dx / _canvasWidth,   // normalised
      'vy': vel.dy / _canvasHeight,  // normalised
      'omega': -screenOmega,         // screen CW → world CCW
    });
  }

  // Host-only: broadcast settled rock positions so clients can correct drift.
  // Skips rocks that are awake (flying) or kinematic (held) — those are
  // handled by releaseRock / dragUpdate respectively.
  // Host-only: broadcast all rock positions at 20Hz so clients correct drift.
  // Kinematic (held) rocks are excluded — their positions come via dragUpdate.
  void _sendPeriodicSync() {
    final rocks = _physicsWorld.rockIds
        .where((id) => !_physicsWorld.isRockKinematic(id))
        .map((id) {
          final norm = _physicsWorld.getRockNormPos(id);
          return {
            'id': id,
            'x': norm.dx,
            'y': norm.dy,
            'angle': _physicsWorld.getRockWorldAngle(id),
          };
        }).toList();
    if (rocks.isEmpty) return;
    _sendAction({'type': 'periodicSync', 'rocks': rocks});
  }

  void _sendSnapshot() {
    if (!_physicsReady) return;
    _sendAction({
      'type': 'snapshot',
      'rocks': _physicsWorld.rockIds.map((id) {
        final norm = _physicsWorld.getRockNormPos(id);
        return {
          'id': id,
          'x': norm.dx,
          'y': norm.dy,
          'angle': _physicsWorld.getRockWorldAngle(id),
        };
      }).toList(),
    });
  }

  void _sendNewRecord(double height) =>
      _sendAction({'type': 'newRecord', 'bestHeight': height / _canvasHeight});

  // ─────────────────────────────────────────────────────────────
  // Physics tick
  // ─────────────────────────────────────────────────────────────

  void _onTick(Duration _) {
    if (!mounted || !_physicsReady) return;

    final now = DateTime.now();
    if (_lastTick == null) {
      _lastTick = now;
      return;
    }
    final elapsed =
        (now.difference(_lastTick!).inMicroseconds / 1e6).clamp(0.0, 0.25);
    _lastTick = now;

    _accumulator += elapsed;
    bool dirty = false;
    while (_accumulator >= _fixedDt) {
      dirty = _physicsWorld.step(_fixedDt) || dirty;
      _accumulator -= _fixedDt;
    }

    if (dirty) setState(() {});
  }

  // ─────────────────────────────────────────────────────────────
  // Drag input
  // ─────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (_gameEnded || !_physicsReady) return;
    final touch = d.localPosition;

    for (final id in _physicsWorld.rockIds) {
      if (_physicsWorld.getRockLockedBy(id) != null) continue;
      final rockPos = _physicsWorld.getRockScreenPos(id);
      if ((touch - rockPos).distance > _rockRadius * 1.3) continue;

      setState(() {
        _draggedId = id;
        _dragTouchOffset = touch - rockPos;
        _prevDragPos = rockPos;
        _prevDragTime = DateTime.now();
        _dragVel = Offset.zero;
      });

      _physicsWorld.grabRock(id);
      _sendLockRock(id);

      _dragSyncTimer?.cancel();
      _dragSyncTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) {
          if (_draggedId == id && _physicsReady) {
            _sendDragUpdate(id);
          }
        },
      );
      return;
    }
    // Touch missed all rocks — do nothing (no viewport panning needed)
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_draggedId == null || !_physicsReady) return;

    final raw = d.localPosition - _dragTouchOffset;
    final clamped = Offset(
      raw.dx.clamp(_rockRadius, _canvasWidth - _rockRadius),
      raw.dy.clamp(_rockRadius, _groundY - _rockRadius * 0.5),
    );

    final now = DateTime.now();
    final dtMs = now.difference(_prevDragTime).inMilliseconds;
    if (dtMs > 0) {
      _dragVel = (clamped - _prevDragPos) / (dtMs / 1000.0);
    }
    _prevDragPos = clamped;
    _prevDragTime = now;

    _physicsWorld.moveRock(_draggedId!, clamped);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_draggedId == null || !_physicsReady) return;

    _dragSyncTimer?.cancel();

    final speed = _dragVel.distance;
    final releaseVel = speed > 1200 ? _dragVel / speed * 1200 : _dragVel;
    final screenOmega = (releaseVel.dx * 0.04).clamp(-6.0, 6.0);

    final id = _draggedId!;

    setState(() => _draggedId = null);

    _physicsWorld.releaseRock(id, releaseVel, screenOmega);
    _sendReleaseRock(id, releaseVel, screenOmega);

    _snapshotTimer?.cancel();
    _snapshotTimer =
        Timer(const Duration(milliseconds: 1500), _checkAndSnapshot);
  }

  void _checkAndSnapshot() {
    if (!mounted || !_physicsReady) return;
    if (!_physicsWorld.allSleeping) {
      _snapshotTimer =
          Timer(const Duration(milliseconds: 800), _checkAndSnapshot);
      return;
    }
    _sendSnapshot();
    _checkBestHeight();
  }

  // ─────────────────────────────────────────────────────────────
  // Best height / celebration
  // ─────────────────────────────────────────────────────────────

  void _checkBestHeight() {
    if (!_physicsReady) return;
    final height = _physicsWorld.computeStackHeight();
    if (height > _bestHeight + 2) {
      setState(() => _bestHeight = height);
      _triggerCelebration();
      _sendNewRecord(height);
    }
  }

  void _triggerCelebration() {
    setState(() => _borderFlash = true);
    _borderFlashTimer?.cancel();
    _borderFlashTimer = Timer(const Duration(milliseconds: 500),
        () { if (mounted) setState(() => _borderFlash = false); });

    // Find top of stack for sparkle origin
    double topY = _groundY;
    double topX = _canvasWidth / 2;
    if (_physicsReady) {
      for (final id in _physicsWorld.rockIds) {
        for (final v in _physicsWorld.getRockWorldVerts(id)) {
          if (v.dy < topY) {
            topY = v.dy;
            topX = _physicsWorld.getRockScreenPos(id).dx;
          }
        }
      }
    }

    final sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final labelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final celeb = _CelebAnim(
      sparkleCtrl: sparkleCtrl,
      labelCtrl: labelCtrl,
      origin: Offset(topX, topY),
      label: '↑ ${(_bestHeight / _canvasHeight * 100).toStringAsFixed(1)} cm',
    );

    setState(() => _celebs.add(celeb));
    sparkleCtrl.forward();
    labelCtrl.forward();
    SfxService().celebration();

    celeb.cleanup = Timer(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      setState(() => _celebs.remove(celeb));
      sparkleCtrl.dispose();
      labelCtrl.dispose();
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Game end
  // ─────────────────────────────────────────────────────────────

  void _onGameEnd(Map<String, dynamic> results) {
    if (_gameEnded || !mounted) return;
    setState(() => _gameEnded = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildResultDialog(),
    );
  }

  Widget _buildResultDialog() {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    final rocksAboveGround =
        _physicsReady ? _physicsWorld.countRocksAboveGround() : 0;

    return AlertDialog(
      backgroundColor: theme.background,
      title: Text(
        l10n.rockBalancing,
        style: AppTypography.bodyLarge(context,
            color: theme.text, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${l10n.maxHeightLabel}: ${(_bestHeight / _canvasHeight * 100).toStringAsFixed(1)} cm',
            style: AppTypography.bodyMedium(context, color: theme.text),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.rocksStacked}: $rocksAboveGround / ${widget.rockCount}',
            style: AppTypography.bodyMedium(context, color: theme.text),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context)
            ..pop()
            ..pop(),
          child: Text(l10n.ok, style: TextStyle(color: theme.primary)),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final renderData = _physicsReady
        ? _physicsWorld.buildRenderData(_draggedId)
        : const <RockRenderData>[];

    return Column(
      children: [
        // ── Info bar ───────────────────────────────────────────
        Padding(
          key: _infoBarKey,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Text(
                '${l10n.record}: ${(_bestHeight / _canvasHeight * 100).toStringAsFixed(1)} cm',
                style: AppTypography.bodySmall(context,
                    color: theme.primary, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_isHost && !_gameEnded)
                TextButton(
                  onPressed: () {
                    context.read<GameRoomProvider>().endGame(
                          {'bestHeight': _bestHeight},
                        );
                    _onGameEnd({'bestHeight': _bestHeight});
                  },
                  child: Text(l10n.endGame,
                      style: TextStyle(color: theme.primary)),
                ),
            ],
          ),
        ),

        // ── Canvas — 9:16, fitted and centred in modal content ──
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Fit a 9:16 canvas into available space, centred both axes
              final fitW = math.min(
                  constraints.maxWidth, constraints.maxHeight * 9 / 16);
              final fitH = fitW * 16 / 9;

              if (_canvasWidth == 0) {
                _canvasWidth = fitW;
                _canvasHeight = fitH;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_physicsReady) setState(_generateRocks);
                });
              }

              return Center(
                child: SizedBox(
                  width: fitW,
                  height: fitH,
                  child: GestureDetector(
                    key: _canvasKey,
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            AssetLoader.getRockBgAsset(
                              DataManager().userSettings.currentScenes[0].sceneSet,
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => const SizedBox.shrink(),
                          ),
                        ),
                        CustomPaint(
                          size: Size(fitW, fitH),
                          painter: _RockPainter(
                            rocks: renderData,
                            groundY: _groundY,
                            groundThickness: _groundThickness,
                            bestHeight: _bestHeight,
                            borderFlash: _borderFlash,
                            primaryColor: theme.primary,
                            borderColor: theme.border,
                            recordLabel: l10n.record,
                            canvasWidth: fitW,
                          ),
                        ),
                        for (final c in _celebs) ...[
                          SparkleBurst(
                            origin: c.origin,
                            controller: c.sparkleCtrl,
                            color: theme.primary,
                            radius: 50,
                          ),
                          FloatingLabelAnim(
                            x: c.origin.dx,
                            y: c.origin.dy,
                            label: c.label,
                            controller: c.labelCtrl,
                            backgroundColor: theme.primary,
                            floatDistance: 60,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
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

class _RockPainter extends CustomPainter {
  final List<RockRenderData> rocks;
  final double groundY;
  final double groundThickness;
  final double bestHeight;
  final bool borderFlash;
  final Color primaryColor;
  final Color borderColor;
  final String recordLabel;
  final double canvasWidth;

  _RockPainter({
    required this.rocks,
    required this.groundY,
    required this.groundThickness,
    required this.bestHeight,
    required this.borderFlash,
    required this.primaryColor,
    required this.borderColor,
    required this.recordLabel,
    required this.canvasWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Ground ───────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, canvasWidth, groundThickness),
      Paint()..color = borderColor.withValues(alpha: 0.4),
    );

    // ── Ghost line (best height record) ──────────────────────
    if (bestHeight > 10) {
      final lineY = groundY - bestHeight;
      final linePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..strokeWidth = 2.5;

      double x = 0;
      const dashLen = 8.0;
      while (x < canvasWidth) {
        canvas.drawLine(
            Offset(x, lineY), Offset(x + dashLen, lineY), linePaint);
        x += dashLen * 2;
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '↑ $recordLabel',
          style: TextStyle(
            color: primaryColor.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(6, lineY - tp.height - 2));
    }

    // ── Rocks ────────────────────────────────────────────────
    for (final rock in rocks) {
      final verts = rock.screenVerts;
      if (verts.isEmpty) continue;

      final path = Path()..moveTo(verts.first.dx, verts.first.dy);
      for (final v in verts.skip(1)) { path.lineTo(v.dx, v.dy); }
      path.close();

      // Fill
      canvas.drawPath(path, Paint()..color = rock.color);

      // Stroke
      canvas.drawPath(
        path,
        Paint()
          ..color = rock.isGrabbedByMe
              ? primaryColor
              : Colors.black.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = rock.isGrabbedByMe ? 2.5 : 1.0,
      );

      // Peer lock overlay
      if (rock.lockedBy != null) {
        canvas.drawPath(
          path,
          Paint()..color = Colors.blue.withValues(alpha: 0.18),
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.blue.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
        final tp = TextPainter(
          text: const TextSpan(
              text: '🤝', style: TextStyle(fontSize: 13)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas,
            rock.screenPos - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // ── Border flash (celebration) ────────────────────────────
    if (borderFlash) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasWidth, size.height),
        Paint()
          ..color = primaryColor.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }
  }

  @override
  bool shouldRepaint(_RockPainter old) => true;
}
