import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/game_room_provider.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/lan/lan_service.dart';
import '../../core/utils/lan/lan_message.dart';
import '../../core/utils/lan/game_message.dart';
import '../../core/utils/physics_utils.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/floating_label_anim.dart';
import '../../core/widgets/sparkle_burst.dart';

// ──────────────────────────────────────────────────────────────
// Rock body — mutable physics state
// ──────────────────────────────────────────────────────────────

class _RockBody {
  final int id;
  final List<Offset> localVerts; // vertices centered at origin
  final double mass;
  final double inertia;
  final Color color;

  Offset pos;
  double angle;
  Offset vel = Offset.zero;
  double omega = 0; // angular velocity (rad/s)
  bool isKinematic = false; // true while dragged by local player
  bool isSleeping = false;
  double sleepTimer = 0;
  String? lockedBy; // playerId of peer currently holding this rock

  // Lerp targets for smooth peer position updates
  Offset? lerpPos;
  double? lerpAngle;

  _RockBody({
    required this.id,
    required this.localVerts,
    required this.pos,
    required this.mass,
    required this.inertia,
    required this.color,
    this.angle = 0,
  });

  List<Offset> get worldVerts {
    final c = math.cos(angle), s = math.sin(angle);
    return localVerts
        .map((v) => Offset(
              pos.dx + v.dx * c - v.dy * s,
              pos.dy + v.dx * s + v.dy * c,
            ))
        .toList();
  }
}

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
    return AppModal.show(
      context: context,
      title: AppLocalizations.of(context).rockBalancing,
      maxHeight: MediaQuery.of(context).size.height * 0.95,
      minHeight: MediaQuery.of(context).size.height * 0.95,
      content: RockBalancingModal(rockCount: rockCount, rockSeed: rockSeed),
    );
  }
}

class _RockBalancingModalState extends State<RockBalancingModal>
    with TickerProviderStateMixin {
  // ── Physics constants ────────────────────────────────────────
  static const double _gravity = 600;
  static const double _linearDamping = 0.92;
  static const double _angularDamping = 0.88;
  static const double _restitution = 0.25;
  static const double _groundFriction = 0.75;
  static const double _sleepVelThreshold = 8.0;
  static const double _sleepOmegaThreshold = 0.08;
  static const double _sleepDelay = 0.5;
  static const double _groundThickness = 20;

  // ── Physics state ────────────────────────────────────────────
  final List<_RockBody> _rocks = [];
  late Ticker _ticker;
  DateTime? _lastTick;

  // ── Canvas ───────────────────────────────────────────────────
  double _canvasWidth = 0;
  double _canvasHeight = 0;
  double get _groundY => _canvasHeight - _groundThickness;
  double get _rockRadius =>
      math.min(45.0, 260.0 / widget.rockCount).toDouble();

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
  String get _localId {
    try {
      return DataManager().userProfile.id;
    } catch (_) {
      return 'local_player';
    }
  }

  bool get _isHost => LanService().role == LanRole.host;

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
    _borderFlashTimer?.cancel();
    for (final c in _celebs) {
      c.sparkleCtrl.dispose();
      c.labelCtrl.dispose();
      c.cleanup?.cancel();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Rock generation (called after canvas size is known)
  // ─────────────────────────────────────────────────────────────

  void _generateRocks() {
    final rng = math.Random(widget.rockSeed);
    final r = _rockRadius;
    final spacing = _canvasWidth / (widget.rockCount + 1);

    for (int i = 0; i < widget.rockCount; i++) {
      final verts =
          randomConvexPolygon(seed: widget.rockSeed, index: i, radius: r);
      final area = polygonArea(verts);
      final mass = (area / 1000).clamp(0.5, 5.0);
      final inertia = momentOfInertia(verts, mass);
      final x = spacing * (i + 1) +
          (rng.nextDouble() - 0.5) * spacing * 0.3;
      final y = _groundY - r - 2;

      _rocks.add(_RockBody(
        id: i,
        localVerts: verts,
        pos: Offset(x.clamp(r, _canvasWidth - r), y),
        mass: mass,
        inertia: inertia,
        color: _rockColors[i % _rockColors.length],
        angle: (rng.nextDouble() - 0.5) * 0.4,
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LAN
  // ─────────────────────────────────────────────────────────────

  void _setupLan() {
    _lanSub = LanService().incomingEvents.listen((event) {
      final gm = GameMessage.tryExtract(event.message);
      if (gm == null) return;

      if (gm.event == GameEvent.playerAction) {
        // Host receives action from client → relay to all, then apply locally
        if (_isHost) {
          LanService().broadcastMessage(
            GameMessage.gameState(_localId, gm.data),
          );
        }
        _applyPeerMessage(gm.data, event.message.senderId);
      } else if (gm.event == GameEvent.gameState && !_isHost) {
        // Client receives relayed action from host
        final fromId = gm.data['fromId'] as String? ?? '';
        _applyPeerMessage(gm.data, fromId);
      } else if (gm.event == GameEvent.gameEnd) {
        _onGameEnd(gm.data);
      }
    });
  }

  void _applyPeerMessage(Map<String, dynamic> data, String fromId) {
    // Skip our own echoed messages
    if (fromId == _localId) return;
    if (!mounted || _rocks.isEmpty) return;

    final type = data['type'] as String?;
    switch (type) {
      case 'lockRock':
        final rock = _rockById(data['rockId'] as int? ?? -1);
        if (rock == null) return;
        setState(() {
          rock.lockedBy = fromId;
          rock.isKinematic = true;
          rock.isSleeping = false;
        });

      case 'dragUpdate':
        final rock = _rockById(data['rockId'] as int? ?? -1);
        if (rock == null || rock.id == _draggedId) return;
        // Lerp targets — smooth interpolation happens in _onTick
        rock.lerpPos = Offset(
          (data['x'] as num).toDouble(),
          (data['y'] as num).toDouble(),
        );
        rock.lerpAngle = (data['angle'] as num? ?? 0).toDouble();

      case 'releaseRock':
        final rock = _rockById(data['rockId'] as int? ?? -1);
        if (rock == null) return;
        setState(() {
          rock.pos = Offset(
            (data['x'] as num).toDouble(),
            (data['y'] as num).toDouble(),
          );
          rock.vel = Offset(
            (data['vx'] as num? ?? 0).toDouble(),
            (data['vy'] as num? ?? 0).toDouble(),
          );
          rock.omega = (data['omega'] as num? ?? 0).toDouble();
          rock.isKinematic = false;
          rock.lockedBy = null;
          rock.isSleeping = false;
          rock.sleepTimer = 0;
          rock.lerpPos = null;
          rock.lerpAngle = null;
        });

      case 'snapshot':
        final list = data['rocks'] as List<dynamic>? ?? [];
        for (final rs in list) {
          final rock = _rockById(rs['id'] as int? ?? -1);
          if (rock == null) continue;
          rock.lerpPos = Offset(
            (rs['x'] as num).toDouble(),
            (rs['y'] as num).toDouble(),
          );
          rock.lerpAngle = (rs['angle'] as num? ?? 0).toDouble();
        }

      case 'newRecord':
        final bh = (data['bestHeight'] as num? ?? 0).toDouble();
        if (bh > _bestHeight) {
          setState(() => _bestHeight = bh);
          _triggerCelebration();
        }
    }
  }

  _RockBody? _rockById(int id) {
    for (final r in _rocks) {
      if (r.id == id) return r;
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // Send helpers
  // ─────────────────────────────────────────────────────────────

  void _sendAction(Map<String, dynamic> data) {
    final payload = {...data, 'fromId': _localId};
    if (_isHost) {
      // Host: broadcast directly as gameState (client listens for gameState)
      LanService()
          .broadcastMessage(GameMessage.gameState(_localId, payload));
    } else {
      // Client: send to host as playerAction (host relays as gameState)
      LanService()
          .sendMessage(GameMessage.playerAction(_localId, payload));
    }
  }

  void _sendLockRock(int id) =>
      _sendAction({'type': 'lockRock', 'rockId': id});

  void _sendDragUpdate(int id, Offset pos, double angle) => _sendAction({
        'type': 'dragUpdate',
        'rockId': id,
        'x': pos.dx,
        'y': pos.dy,
        'angle': angle,
      });

  void _sendReleaseRock(int id, Offset pos, Offset vel, double omega) =>
      _sendAction({
        'type': 'releaseRock',
        'rockId': id,
        'x': pos.dx,
        'y': pos.dy,
        'vx': vel.dx,
        'vy': vel.dy,
        'omega': omega,
      });

  void _sendSnapshot() => _sendAction({
        'type': 'snapshot',
        'rocks': _rocks
            .map((r) => {'id': r.id, 'x': r.pos.dx, 'y': r.pos.dy, 'angle': r.angle})
            .toList(),
      });

  void _sendNewRecord(double height) =>
      _sendAction({'type': 'newRecord', 'bestHeight': height});

  // ─────────────────────────────────────────────────────────────
  // Physics tick
  // ─────────────────────────────────────────────────────────────

  void _onTick(Duration _) {
    if (!mounted || _rocks.isEmpty) return;

    final now = DateTime.now();
    if (_lastTick == null) {
      _lastTick = now;
      return;
    }
    final dt =
        (now.difference(_lastTick!).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = now;

    bool dirty = false;

    for (final rock in _rocks) {
      // ── Lerp peer rocks ────────────────────────────────────
      if (rock.lerpPos != null) {
        rock.pos = Offset(
          lerpDouble(rock.pos.dx, rock.lerpPos!.dx, 0.2),
          lerpDouble(rock.pos.dy, rock.lerpPos!.dy, 0.2),
        );
        if ((rock.pos - rock.lerpPos!).distance < 0.8) {
          rock.pos = rock.lerpPos!;
          if (rock.lockedBy == null) rock.lerpPos = null;
        }
        dirty = true;
      }
      if (rock.lerpAngle != null) {
        rock.angle = lerpDouble(rock.angle, rock.lerpAngle!, 0.2);
        if ((rock.angle - rock.lerpAngle!).abs() < 0.005) {
          rock.angle = rock.lerpAngle!;
          if (rock.lockedBy == null) rock.lerpAngle = null;
        }
        dirty = true;
      }

      // Skip non-simulated rocks
      if (rock.isKinematic || rock.isSleeping) continue;

      // ── Gravity + integration ──────────────────────────────
      rock.vel = Offset(rock.vel.dx, rock.vel.dy + _gravity * dt);
      rock.pos = Offset(
        rock.pos.dx + rock.vel.dx * dt,
        rock.pos.dy + rock.vel.dy * dt,
      );
      rock.angle += rock.omega * dt;

      // ── Damping ────────────────────────────────────────────
      final ld = math.pow(_linearDamping, dt * 60).toDouble();
      final ad = math.pow(_angularDamping, dt * 60).toDouble();
      rock.vel = rock.vel * ld;
      rock.omega *= ad;

      // ── Wall bounds ────────────────────────────────────────
      double leftPen = 0, rightPen = 0;
      for (final v in rock.worldVerts) {
        if (-v.dx > leftPen) leftPen = -v.dx;
        if (v.dx - _canvasWidth > rightPen) rightPen = v.dx - _canvasWidth;
      }
      if (leftPen > 0) {
        rock.pos = Offset(rock.pos.dx + leftPen, rock.pos.dy);
        if (rock.vel.dx < 0) {
          rock.vel = Offset(-rock.vel.dx * _restitution, rock.vel.dy);
        }
      }
      if (rightPen > 0) {
        rock.pos = Offset(rock.pos.dx - rightPen, rock.pos.dy);
        if (rock.vel.dx > 0) {
          rock.vel = Offset(-rock.vel.dx * _restitution, rock.vel.dy);
        }
      }

      // ── Ground collision ───────────────────────────────────
      double maxPen = 0;
      for (final v in rock.worldVerts) {
        final pen = v.dy - _groundY;
        if (pen > maxPen) maxPen = pen;
      }
      if (maxPen > 0) {
        rock.pos = Offset(rock.pos.dx, rock.pos.dy - maxPen);
        if (rock.vel.dy > 80) {
          // Only bounce if actually falling with speed
          final now2 = DateTime.now();
          if (now2.difference(_lastRockLandSfx).inMilliseconds > 300) {
            _lastRockLandSfx = now2;
            SfxService().rockLand();
          }
        }
        rock.vel = Offset(
          rock.vel.dx * _groundFriction,
          -rock.vel.dy * _restitution,
        );
        rock.omega *= _groundFriction;
      }

      // ── Sleep check ────────────────────────────────────────
      if (rock.vel.distance < _sleepVelThreshold &&
          rock.omega.abs() < _sleepOmegaThreshold) {
        rock.sleepTimer += dt;
        if (rock.sleepTimer >= _sleepDelay) {
          rock.isSleeping = true;
          rock.vel = Offset.zero;
          rock.omega = 0;
        }
      } else {
        rock.sleepTimer = 0;
      }

      dirty = true;
    }

    // ── Rock–rock collisions ───────────────────────────────────
    for (int i = 0; i < _rocks.length; i++) {
      for (int j = i + 1; j < _rocks.length; j++) {
        if (_resolveRockCollision(_rocks[i], _rocks[j])) dirty = true;
      }
    }

    if (dirty) setState(() {});
  }

  bool _resolveRockCollision(_RockBody a, _RockBody b) {
    // Skip if both are static
    if ((a.isSleeping || a.isKinematic) &&
        (b.isSleeping || b.isKinematic)) {
      return false;
    }

    final contact = satContact(a.worldVerts, b.worldVerts);
    if (contact == null) return false;

    // Wake sleeping rocks on impact
    if (a.isSleeping) {
      a.isSleeping = false;
      a.sleepTimer = 0;
    }
    if (b.isSleeping) {
      b.isSleeping = false;
      b.sleepTimer = 0;
    }

    final normal = contact.normal;
    final depth = contact.depth;
    final totalMass = a.mass + b.mass;

    // Positional correction
    if (!a.isKinematic) {
      a.pos -= normal * depth * (b.mass / totalMass);
    }
    if (!b.isKinematic) {
      b.pos += normal * depth * (a.mass / totalMass);
    }

    // Impulse resolution
    final relVel = a.vel - b.vel;
    final relVelN = relVel.dx * normal.dx + relVel.dy * normal.dy;
    if (relVelN > 0) return true; // separating, but position was corrected

    final invA = a.isKinematic ? 0.0 : 1.0 / a.mass;
    final invB = b.isKinematic ? 0.0 : 1.0 / b.mass;
    final invSum = invA + invB;
    if (invSum == 0) return true;

    final j = -(1 + _restitution) * relVelN / invSum;
    final impulse = normal * j;

    if (!a.isKinematic) a.vel += impulse * invA;
    if (!b.isKinematic) b.vel -= impulse * invB;

    // Small random angular nudge for visual interest
    final rng = math.Random();
    if (!a.isKinematic) a.omega += j * 0.003 * (rng.nextDouble() - 0.5);
    if (!b.isKinematic) b.omega -= j * 0.003 * (rng.nextDouble() - 0.5);

    // SFX with debounce
    final now = DateTime.now();
    if (j.abs() > 30 &&
        now.difference(_lastRockHitSfx).inMilliseconds > 250) {
      _lastRockHitSfx = now;
      SfxService().rockHit();
    }
    return true;
  }

  // ─────────────────────────────────────────────────────────────
  // Drag input
  // ─────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (_gameEnded || _rocks.isEmpty) return;
    final touch = d.localPosition;

    for (final rock in _rocks) {
      if (rock.lockedBy != null) continue; // held by peer
      if ((touch - rock.pos).distance > _rockRadius * 1.3) continue;

      setState(() {
        _draggedId = rock.id;
        rock.isKinematic = true;
        rock.isSleeping = false;
        rock.vel = Offset.zero;
        rock.omega = 0;
        _dragTouchOffset = touch - rock.pos;
        _prevDragPos = rock.pos;
        _prevDragTime = DateTime.now();
        _dragVel = Offset.zero;
      });

      _sendLockRock(rock.id);

      _dragSyncTimer?.cancel();
      _dragSyncTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) {
          if (_draggedId == rock.id) {
            _sendDragUpdate(rock.id, rock.pos, rock.angle);
          }
        },
      );
      return;
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_draggedId == null) return;
    final rock = _rockById(_draggedId!);
    if (rock == null) return;

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

    setState(() => rock.pos = clamped);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_draggedId == null) return;
    final rock = _rockById(_draggedId!);
    if (rock == null) return;

    _dragSyncTimer?.cancel();

    // Cap release velocity to avoid rocks flying off screen
    final speed = _dragVel.distance;
    final releaseVel =
        speed > 1200 ? _dragVel / speed * 1200 : _dragVel;

    setState(() {
      rock.isKinematic = false;
      rock.vel = releaseVel;
      rock.omega = (releaseVel.dx * 0.04).clamp(-6.0, 6.0);
      rock.isSleeping = false;
      rock.sleepTimer = 0;
      _draggedId = null;
    });

    _sendReleaseRock(rock.id, rock.pos, releaseVel, rock.omega);

    // Schedule snapshot after physics settles
    _snapshotTimer?.cancel();
    _snapshotTimer =
        Timer(const Duration(milliseconds: 1500), _checkAndSnapshot);
  }

  void _checkAndSnapshot() {
    if (!mounted || _rocks.isEmpty) return;
    final allSleeping =
        _rocks.every((r) => r.isSleeping || r.isKinematic);
    if (!allSleeping) {
      _snapshotTimer =
          Timer(const Duration(milliseconds: 600), _checkAndSnapshot);
      return;
    }
    _sendSnapshot();
    _checkBestHeight();
  }

  // ─────────────────────────────────────────────────────────────
  // Best height / celebration
  // ─────────────────────────────────────────────────────────────

  void _checkBestHeight() {
    if (_rocks.isEmpty) return;
    double topY = _groundY;
    for (final rock in _rocks) {
      for (final v in rock.worldVerts) {
        if (v.dy < topY) topY = v.dy;
      }
    }
    final height = _groundY - topY;
    if (height > _bestHeight + 2) {
      setState(() => _bestHeight = height);
      _triggerCelebration();
      _sendNewRecord(height);
    }
  }

  void _triggerCelebration() {
    // Flash border
    setState(() => _borderFlash = true);
    _borderFlashTimer?.cancel();
    _borderFlashTimer = Timer(const Duration(milliseconds: 500),
        () { if (mounted) setState(() => _borderFlash = false); });

    // Find top of stack for sparkle origin
    double topY = _groundY;
    double topX = _canvasWidth / 2;
    for (final rock in _rocks) {
      for (final v in rock.worldVerts) {
        if (v.dy < topY) {
          topY = v.dy;
          topX = rock.pos.dx;
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
      label: '↑ ${(_bestHeight / 10).toStringAsFixed(1)} cm',
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
    final rocksAboveGround = _rocks.where((rock) {
      final minY = rock.worldVerts.map((v) => v.dy).reduce(math.min);
      return minY < _groundY - 5;
    }).length;

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
            '${l10n.maxHeightLabel}: ${(_bestHeight / 10).toStringAsFixed(1)} cm',
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
            ..pop() // close dialog
            ..pop(), // close game modal
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
    context.watch<GameRoomProvider>(); // rebuild on game end signal

    return Column(
      children: [
        // ── Info bar ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Text(
                '${l10n.record}: ${(_bestHeight / 10).toStringAsFixed(1)} cm',
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

        // ── Canvas ─────────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // One-time init after layout
              if (_canvasWidth == 0) {
                _canvasWidth = constraints.maxWidth;
                _canvasHeight = constraints.maxHeight;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _rocks.isEmpty) setState(_generateRocks);
                });
              }

              return GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Stack(
                  children: [
                    // Physics canvas
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _RockPainter(
                        rocks: _rocks,
                        groundY: _groundY,
                        groundThickness: _groundThickness,
                        bestHeight: _bestHeight,
                        borderFlash: _borderFlash,
                        draggedId: _draggedId,
                        primaryColor: theme.primary,
                        borderColor: theme.border,
                        recordLabel: l10n.record,
                      ),
                    ),

                    // Celebration animations
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
  final List<_RockBody> rocks;
  final double groundY;
  final double groundThickness;
  final double bestHeight;
  final bool borderFlash;
  final int? draggedId;
  final Color primaryColor;
  final Color borderColor;
  final String recordLabel;

  _RockPainter({
    required this.rocks,
    required this.groundY,
    required this.groundThickness,
    required this.bestHeight,
    required this.borderFlash,
    required this.draggedId,
    required this.primaryColor,
    required this.borderColor,
    required this.recordLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Ground ───────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, groundThickness),
      Paint()..color = borderColor.withValues(alpha: 0.4),
    );

    // ── Ghost line (best height record) ──────────────────────
    if (bestHeight > 10) {
      final lineY = groundY - bestHeight;
      final linePaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.4)
        ..strokeWidth = 1.5;

      // Dashed line
      double x = 0;
      const dashLen = 8.0;
      while (x < size.width) {
        canvas.drawLine(
            Offset(x, lineY), Offset(x + dashLen, lineY), linePaint);
        x += dashLen * 2;
      }

      // Record label
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
      final verts = rock.worldVerts;
      if (verts.isEmpty) continue;

      final path = Path()..moveTo(verts.first.dx, verts.first.dy);
      for (final v in verts.skip(1)) { path.lineTo(v.dx, v.dy); }
      path.close();

      // Fill
      canvas.drawPath(path, Paint()..color = rock.color);

      // Stroke
      final isDraggedByMe =
          rock.id == draggedId && rock.lockedBy == null;
      canvas.drawPath(
        path,
        Paint()
          ..color = isDraggedByMe
              ? primaryColor
              : Colors.black.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isDraggedByMe ? 2.5 : 1.0,
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
        // 🤝 emoji at rock center
        final tp = TextPainter(
          text: const TextSpan(
              text: '🤝', style: TextStyle(fontSize: 13)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas,
            rock.pos - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // ── Border flash (celebration) ────────────────────────────
    if (borderFlash) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
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
