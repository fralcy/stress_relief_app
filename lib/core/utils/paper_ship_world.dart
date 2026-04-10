import 'dart:math' as math;
import 'package:flutter/material.dart' show Color, Offset;
import 'paper_ship_chunk.dart';

// ── Render data ───────────────────────────────────────────────

class WaveRenderData {
  final Offset screenCenter; // wave source in screen coords
  final double sigma;        // current spread radius (px)
  final double opacity;      // 0..1
  final double strokeWidth;  // ring thickness
  final bool blocked;        // true → draw half-arc only
  final double angleToBoat;  // radians — used when blocked
  final Color waveColor;     // per-player color coding

  const WaveRenderData({
    required this.screenCenter,
    required this.sigma,
    required this.opacity,
    required this.strokeWidth,
    required this.blocked,
    required this.angleToBoat,
    required this.waveColor,
  });
}

class ObstacleRenderData {
  final ObstacleType type;
  final Offset screenPos;
  final double visualSize;
  final double angle;      // rotation — log direction, whirlpool orientation
  final double halfLength; // px — log capsule visual half-length; 0 for others
  final double phase;      // animation phase — whirlpool spin (seconds elapsed)

  const ObstacleRenderData({
    required this.type,
    required this.screenPos,
    required this.visualSize,
    this.angle = 0.0,
    this.halfLength = 0.0,
    this.phase = 0.0,
  });
}

class FoamParticleRenderData {
  final Offset screenPos;
  final double radius;
  final double opacity;

  const FoamParticleRenderData({
    required this.screenPos,
    required this.radius,
    required this.opacity,
  });
}

class PaperShipRenderSnapshot {
  final Offset boatPos;
  final double boatAngle;          // radians
  final double shakeAmount;
  final List<Offset> wakeTrail;    // screen coords, 0 = newest
  final List<WaveRenderData> waves;
  final List<ObstacleRenderData> obstacles;
  final List<FoamParticleRenderData> foam;
  final double distanceTraveled;
  final Color skyColor;
  final Biome currentBiome;

  const PaperShipRenderSnapshot({
    required this.boatPos,
    required this.boatAngle,
    required this.shakeAmount,
    required this.wakeTrail,
    required this.waves,
    required this.obstacles,
    required this.foam,
    required this.distanceTraveled,
    required this.skyColor,
    required this.currentBiome,
  });
}

// ── Internal state ────────────────────────────────────────────

class _WaveSource {
  final int id;
  final double worldX; // world-space position
  final double worldY; // world-space; larger = further upstream (higher on screen)
  double age;          // seconds since spawn
  final String ownerId;

  _WaveSource({
    required this.id,
    required this.worldX,
    required this.worldY,
    required this.ownerId,
  }) : age = 0.0;
}

class _FoamParticle {
  Offset position;   // screen coords
  Offset velocity;   // px/s
  double lifetime;   // total lifetime seconds
  double age;        // current age seconds

  _FoamParticle({
    required this.position,
    required this.velocity,
    required this.lifetime,
  }) : age = 0.0;

  double get ageRatio => (age / lifetime).clamp(0.0, 1.0);
  bool get isDead => age >= lifetime;
}

// ── PaperShipWorld ────────────────────────────────────────────
//
// Coordinate convention:
//   worldY: increases upstream (higher on screen).
//   screenY = _scrollOffset - worldY  →  larger worldY = smaller screenY = higher up.
//   _scrollOffset = worldY of the viewport's TOP edge; grows as boat goes upstream.
//
// Game flow:
//   River current: constant downward force on boat (+screenY direction).
//   Players tap → wave rings → push boat upstream (−screenY).
//   When boat passes top threshold, camera scrolls (scrollOffset increases).
//   Obstacles enter from top of screen and flow downward. ✓

class PaperShipWorld {
  // ── Tunables ──────────────────────────────────────────────
  static const int _maxWaves = 8;
  static const double _waveSpeedPx = 120.0;    // px/s — ring expansion speed
  static const double _waveDampingRate = 0.6;  // amplitude half-life ~1.15s (was 1.4)
  static const double _waveMaxForce = 500.0;   // px/s² peak force (was 250)
  static const double _wavePulseWidth = 28.0;
  static const double _waveMaxRadius = 580.0;
  static const double _boatMass = 1.0;
  static const double _boatDampingBase = 0.98;    // was 0.95 — more glide/inertia
  static const double _maxBoatSpeed = 700.0;      // was 400 — faster, more exciting
  static const double _stiffness = 200.0;         // repulsion px/s²
  // River current scales with distance: 100 px/s² at start, +20 per 1000px, cap 300
  static const double _riverCurrentBase  = 100.0;
  static const double _riverCurrentScale =  20.0; // px/s² per 1000px scrolled
  static const double _riverCurrentMax   = 300.0;
  static const double _shakeScale = 0.04;
  static const double _shakeDampingBase = 0.85;
  static const double _boatAnchorY = 0.68;        // initial screen Y fraction
  static const double _boatRadius = 18.0;

  // Buffer zone & scroll threshold
  static const double _kBufferX         = 0.10;
  static const double _kBufferYBottom   = 0.80;   // bottom spring boundary
  static const double _kScrollThreshold = 0.40;   // soft ceiling (40% from top)
  static const double _kCushionX        = 1800.0;
  static const double _kCushionY        = 1800.0;
  static const double _kMaxCombinedForce = 1500.0;
  // Computed from playerCount: floor(8 / playerCount), min 1
  late final int _maxWavesPerPlayer;

  // Wave color palette (per-player slot 0–3)
  static const _waveColors = [
    Color(0xFFADD8E6), // slot 0: light blue
    Color(0xFFFFF8E7), // slot 1: milk white
    Color(0xFF90EE90), // slot 2: light green
    Color(0xFFFFFFAA), // slot 3: light yellow
  ];

  // Sky palette: day → sunset → dusk → night
  static const _skyPalette = [
    Color(0xFF87CEEB),
    Color(0xFFFFB347),
    Color(0xFF9370DB),
    Color(0xFF2C3E70),
  ];
  static const double _skyPaletteStep = 1500.0;

  // ── Canvas dimensions ────────────────────────────────────
  final double cw;
  final double ch;

  // ── Chunk manager ────────────────────────────────────────
  late final ChunkManager _chunks;

  // ── Boat state (screen coords) ───────────────────────────
  late Offset _boatPos;
  Offset _boatVelocity = Offset.zero;
  double _boatAngle = 0.0;
  double _shakeAmount = 0.0;
  final List<Offset> _wakeTrail = [];
  static const int _wakeLength = 12;

  // ── Wave sources ─────────────────────────────────────────
  final List<_WaveSource> _waves = [];
  int _nextWaveId = 0;

  // ── Foam ─────────────────────────────────────────────────
  final List<_FoamParticle> _foam = [];

  // ── Scroll / distance ────────────────────────────────────
  // _scrollOffset = worldY of viewport top.
  // Visible range: worldY ∈ [_scrollOffset − ch, _scrollOffset].
  // screenY = _scrollOffset − worldY.
  double _scrollOffset = 0.0;
  double _distanceTraveled = 0.0;
  // Camera momentum: upward boat velocity is transferred here instead of
  // being discarded, so obstacles continue flying downward after a big wave.
  double _cameraVelocity = 0.0; // px/s, positive = camera scrolling upstream
  double _elapsedSeconds = 0.0; // total time — used for whirlpool animation phase

  final math.Random _rng;

  // ── Constructor ──────────────────────────────────────────

  PaperShipWorld({
    required this.cw,
    required this.ch,
    required int seed,
    int playerCount = 1,
  }) : _rng = math.Random(seed) {
    _maxWavesPerPlayer = (8 / playerCount.clamp(1, 8)).floor().clamp(1, 8);
    _boatPos = Offset(cw * 0.5, ch * _boatAnchorY);
    // Init scrollOffset = ch so initial chunks (worldY ∈ [0, ch]) map to
    // screenY ∈ [0, ch] (visible). Obstacles enter from top as scroll grows.
    _scrollOffset = ch;
    _chunks = ChunkManager(canvasWidth: cw, canvasHeight: ch, seed: seed);
    _chunks.ensureAhead(_scrollOffset + ch * 2);
  }

  double get distanceTraveled => _distanceTraveled;

  // ── Wave spawning ────────────────────────────────────────

  void spawnWave(double screenX, double screenY, String ownerId) {
    final worldX = screenX;
    final worldY = _scrollOffset - screenY; // screen → world

    // Per-player cooldown: max _maxWavesPerPlayer active waves per player
    final playerWaves = _waves.where((w) => w.ownerId == ownerId).toList();
    if (playerWaves.length >= _maxWavesPerPlayer) {
      _waves.remove(playerWaves.first);
    }

    if (_waves.length >= _maxWaves) {
      _waves.removeAt(0);
    }

    _waves.add(_WaveSource(
      id: _nextWaveId++,
      worldX: worldX,
      worldY: worldY,
      ownerId: ownerId,
    ));
  }

  // ── Main step ────────────────────────────────────────────

  void step(double dt) {
    _elapsedSeconds += dt;
    _advanceWaves(dt);
    final totalForce = _computeBoatForce();
    _integrateBoat(dt, totalForce);
    _checkBoatObstacleCollision();
    _advanceFoam(dt);
    _advanceScroll(dt);
    _updateWakeTrail();
  }

  void stepClient(double dt) {
    _elapsedSeconds += dt;
    _advanceFoam(dt);
    _updateBoatAngleSmooth(dt);
    _shakeAmount = (_shakeAmount * math.pow(_shakeDampingBase, dt * 60)).toDouble();
  }

  // ── Wave advancement ─────────────────────────────────────

  void _advanceWaves(double dt) {
    for (final w in _waves) {
      w.age += dt;
    }
    _waves.removeWhere((w) {
      final sigma = _waveSpeedPx * w.age;
      final amplitude = _waveMaxForce * math.exp(-w.age * _waveDampingRate);
      return sigma > _waveMaxRadius || amplitude < 0.5;
    });
  }

  // ── Force computation (screen-space) ─────────────────────

  // Solid obstacles: excludes whirlpool (force-field only, not a blocker)
  List<ShipObstacle> _solidObstacles() =>
      _visibleObstacles().where((o) => o.type != ObstacleType.whirlpool).toList();

  Offset _computeBoatForce() {
    var total = Offset.zero;
    final solid = _solidObstacles();

    for (final w in _waves) {
      final sigma = _waveSpeedPx * w.age;
      final amplitude = _waveMaxForce * math.exp(-w.age * _waveDampingRate);
      if (amplitude < 0.5) continue;

      final waveScreen = Offset(w.worldX, _scrollOffset - w.worldY);
      final delta = _boatPos - waveScreen;
      final d = delta.distance;
      if (d < 0.1) continue;

      final pulseArg = (d - sigma) / _wavePulseWidth;
      final F = amplitude * math.exp(-0.5 * pulseArg * pulseArg);
      if (F < 0.5) continue;

      final dir = delta / d;
      final mult = _waveForceMultiplier(waveScreen, _boatPos, solid);
      // Upstream bias: ×1.5 when pushing up, ×0.5 when pushing down
      final upBias = 1.0 + (-dir.dy) * 0.5;
      total = Offset(
        total.dx + dir.dx * F * mult * upBias,
        total.dy + dir.dy * F * mult * upBias,
      );
    }

    // Whirlpool force: tangential spin + slight inward pull
    for (final o in _visibleObstacles().where(
        (o) => o.type == ObstacleType.whirlpool)) {
      final obsScreen = Offset(o.worldX, _scrollOffset - o.worldY);
      final toBoat = _boatPos - obsScreen;
      final dist = toBoat.distance;
      if (dist >= o.radius || dist < 1.0) continue;
      final strength = (1.0 - dist / o.radius).clamp(0.0, 1.0);
      // Counterclockwise tangent
      final tangent = Offset(-toBoat.dy / dist, toBoat.dx / dist);
      final spin = tangent * (200.0 * strength);
      final pull = (-toBoat / dist) * (80.0 * strength);
      total = Offset(total.dx + spin.dx + pull.dx, total.dy + spin.dy + pull.dy);
    }

    // Clamp total force to avoid velocity spike
    final totalMag = total.distance;
    if (totalMag > _kMaxCombinedForce) {
      total = total / totalMag * _kMaxCombinedForce;
    }

    return total; // screen-space force
  }

  // 3-ray raycasting (screen-space)
  double _waveForceMultiplier(
      Offset from, Offset to, List<ShipObstacle> obstacles) {
    final dir = to - from;
    final dist = dir.distance;
    if (dist < 0.1) return 1.0;
    final unitDir = Offset(dir.dx / dist, dir.dy / dist);
    final perp = Offset(-unitDir.dy, unitDir.dx) * _boatRadius;
    int clear = 0;
    for (final target in [to, to + perp, to - perp]) {
      if (!_segmentHitsCircle(from, target, obstacles)) clear++;
    }
    return clear / 3.0;
  }

  bool _segmentHitsCircle(
      Offset from, Offset to, List<ShipObstacle> obstacles) {
    final d = to - from;
    for (final o in obstacles) {
      // Convert obstacle world → screen for consistent space
      final obsScreen = Offset(o.worldX, _scrollOffset - o.worldY);
      final f = from - obsScreen;
      final a = d.dx * d.dx + d.dy * d.dy;
      if (a < 0.0001) continue;
      final b = 2 * (f.dx * d.dx + f.dy * d.dy);
      final c = f.dx * f.dx + f.dy * f.dy - o.radius * o.radius;
      final discriminant = b * b - 4 * a * c;
      if (discriminant >= 0) {
        final sqrtD = math.sqrt(discriminant);
        final t1 = (-b - sqrtD) / (2 * a);
        final t2 = (-b + sqrtD) / (2 * a);
        if (t1 <= 1.0 && t2 >= 0.0) return true;
      }
    }
    return false;
  }

  // ── Boat integration ─────────────────────────────────────

  void _integrateBoat(double dt, Offset force) {
    // Progressive river current: stronger the further upstream we've gone.
    final riverCurrent = (_riverCurrentBase +
            (_scrollOffset / 1000.0) * _riverCurrentScale)
        .clamp(_riverCurrentBase, _riverCurrentMax);

    // force is screen-space. River current adds +Y (downward) accel.
    final accel = Offset(
      force.dx / _boatMass,
      (force.dy + riverCurrent) / _boatMass,
    );
    _boatVelocity = _boatVelocity + accel * dt;

    final damping = math.pow(_boatDampingBase, dt * 60).toDouble();
    _boatVelocity = _boatVelocity * damping;

    final speed = _boatVelocity.distance;
    if (speed > _maxBoatSpeed) {
      _boatVelocity = _boatVelocity / speed * _maxBoatSpeed;
    }

    _boatPos = _boatPos + _boatVelocity * dt;

    // Buffer zone: spring cushion (all screen coords)
    final leftBound   = cw * _kBufferX;
    final rightBound  = cw * (1.0 - _kBufferX);
    final bottomBound = ch * _kBufferYBottom;

    if (_boatPos.dx < leftBound) {
      _boatVelocity = Offset(
        _boatVelocity.dx + _kCushionX * (leftBound - _boatPos.dx) * dt,
        _boatVelocity.dy,
      );
    }
    if (_boatPos.dx > rightBound) {
      _boatVelocity = Offset(
        _boatVelocity.dx - _kCushionX * (_boatPos.dx - rightBound) * dt,
        _boatVelocity.dy,
      );
    }
    if (_boatPos.dy > bottomBound) {
      _boatVelocity = Offset(
        _boatVelocity.dx,
        _boatVelocity.dy - _kCushionY * (_boatPos.dy - bottomBound) * dt,
      );
    }
    // Top boundary: handled by scroll threshold in _advanceScroll()

    _updateBoatAngleSmooth(dt);
  }

  void _updateBoatAngleSmooth(double dt) {
    final speed = _boatVelocity.distance;
    if (speed > 5.0) {
      final targetAngle = math.atan2(_boatVelocity.dy, _boatVelocity.dx);
      double diff = targetAngle - _boatAngle;
      while (diff > math.pi)  { diff -= 2 * math.pi; }
      while (diff < -math.pi) { diff += 2 * math.pi; }
      _boatAngle += diff * (1 - math.pow(0.92, dt * 60));
    }
    _shakeAmount = (_shakeAmount * math.pow(_shakeDampingBase, dt * 60)).toDouble();
  }

  // ── Collision / repulsion (screen coords) ────────────────

  // Closest point on a capsule axis (for log collision)
  Offset _capsuleClosest(Offset boat, Offset center, double angle, double halfLen) {
    final axis = Offset(math.cos(angle), math.sin(angle));
    final toBoat = boat - center;
    final proj = (toBoat.dx * axis.dx + toBoat.dy * axis.dy)
        .clamp(-halfLen, halfLen);
    return center + Offset(axis.dx * proj, axis.dy * proj);
  }

  void _checkBoatObstacleCollision() {
    for (final o in _visibleObstacles()) {
      final obsScreen = Offset(o.worldX, _scrollOffset - o.worldY);

      // Whirlpool: force-only, no hard collision — just add shake
      if (o.type == ObstacleType.whirlpool) {
        final dist = (_boatPos - obsScreen).distance;
        if (dist < o.radius) {
          final proximity = (1.0 - dist / o.radius).clamp(0.0, 1.0);
          _shakeAmount = (_shakeAmount + proximity * 0.05).clamp(0.0, 6.0);
        }
        continue;
      }

      // Log: capsule hitbox; all others: circle hitbox
      final closest = (o.type == ObstacleType.log && o.halfLength > 0)
          ? _capsuleClosest(_boatPos, obsScreen, o.angle, o.halfLength)
          : obsScreen;

      final delta = _boatPos - closest;
      final dist  = delta.distance;
      final minDist = o.radius + _boatRadius;
      if (dist < minDist && dist > 0.1) {
        final penetration = minDist - dist;
        final normal = delta / dist;
        final repulsion = _stiffness * penetration;
        _boatVelocity = Offset(
          _boatVelocity.dx + normal.dx * repulsion * (1 / 60.0),
          _boatVelocity.dy + normal.dy * repulsion * (1 / 60.0),
        );
        _boatPos = Offset(
          _boatPos.dx + normal.dx * penetration * 0.5,
          _boatPos.dy + normal.dy * penetration * 0.5,
        );
        _shakeAmount = (_shakeAmount + penetration * _shakeScale).clamp(0.0, 6.0);
        _spawnFoam(_boatPos - normal * _boatRadius);
      }
    }
  }

  void _spawnFoam(Offset screenPos) {
    final count = 3 + _rng.nextInt(3);
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 30.0 + _rng.nextDouble() * 60.0;
      _foam.add(_FoamParticle(
        position: screenPos,
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        lifetime: 0.5 + _rng.nextDouble() * 0.4,
      ));
    }
    if (_foam.length > 60) _foam.removeRange(0, _foam.length - 60);
  }

  // ── Foam advancement ─────────────────────────────────────

  void _advanceFoam(double dt) {
    for (final p in _foam) {
      p.age += dt;
      p.velocity = p.velocity * 0.92;
      p.position = p.position + p.velocity * dt;
    }
    _foam.removeWhere((p) => p.isDead);
  }

  // ── Scroll advancement ───────────────────────────────────
  // Camera only scrolls upstream when boat surpasses the soft ceiling.
  // River current is already modeled as a force in _integrateBoat.

  void _advanceScroll(double dt) {
    // Dynamic threshold: faster upward boat → camera triggers earlier (higher on screen).
    // upwardFraction ∈ [0,1] based on current upward speed vs max speed.
    final upwardFraction =
        (-_boatVelocity.dy).clamp(0.0, _maxBoatSpeed) / _maxBoatSpeed;
    final dynamicThreshold =
        (_kScrollThreshold + upwardFraction * 0.15).clamp(_kScrollThreshold, 0.55);
    final thresholdY = ch * dynamicThreshold;

    if (_boatPos.dy < thresholdY) {
      // Boat broke through ceiling: shift camera upstream
      final overshoot = thresholdY - _boatPos.dy;
      _scrollOffset += overshoot;
      _distanceTraveled += overshoot;
      _boatPos = Offset(_boatPos.dx, thresholdY); // pin to threshold
      // Transfer upward velocity to camera so obstacles keep flying downward
      if (_boatVelocity.dy < 0) {
        _cameraVelocity += -_boatVelocity.dy;
        _boatVelocity = Offset(_boatVelocity.dx, 0);
      }
    }

    // Carry camera momentum forward with smooth trailing decay (was 0.85 → 0.94)
    if (_cameraVelocity > 1.0) {
      final delta = _cameraVelocity * dt;
      _scrollOffset += delta;
      _distanceTraveled += delta;
      _cameraVelocity *= math.pow(0.94, dt * 60).toDouble();
      if (_cameraVelocity < 5.0) _cameraVelocity = 0.0;
    }

    _chunks.ensureAhead(_scrollOffset + ch * 2);
    _chunks.cullBehind(_scrollOffset - ch);
  }

  // ── Wake trail ───────────────────────────────────────────

  void _updateWakeTrail() {
    _wakeTrail.insert(0, _boatPos);
    if (_wakeTrail.length > _wakeLength) {
      _wakeTrail.removeRange(_wakeLength, _wakeTrail.length);
    }
  }

  // ── Visible obstacles ────────────────────────────────────
  // Visible worldY ∈ [_scrollOffset − ch, _scrollOffset].
  // Add ±10% buffers for smoother entry/exit.

  List<ShipObstacle> _visibleObstacles() {
    return _chunks.obstaclesInRange(
      _scrollOffset - ch * 1.05, // slightly below screen bottom for smooth exit
      _scrollOffset,             // exact top edge — never above canvas
    );
  }

  // ── Render snapshot ──────────────────────────────────────

  PaperShipRenderSnapshot buildRenderData() {
    final visibleObs = _visibleObstacles();

    // ownerId → color slot (first-seen order)
    final ownerColorIndex = <String, int>{};
    for (final w in _waves) {
      if (!ownerColorIndex.containsKey(w.ownerId)) {
        ownerColorIndex[w.ownerId] = ownerColorIndex.length % _waveColors.length;
      }
    }

    final waves = <WaveRenderData>[];
    for (final w in _waves) {
      final sigma = _waveSpeedPx * w.age;
      final amplitude = _waveMaxForce * math.exp(-w.age * _waveDampingRate);
      if (amplitude < 0.5) continue;

      final waveScreen = Offset(w.worldX, _scrollOffset - w.worldY);

      final opacity = (amplitude / _waveMaxForce).clamp(0.0, 1.0);
      final strokeWidth = _wavePulseWidth *
          math.exp(-0.5 * math.pow(w.age * _waveDampingRate / 2.0, 2));

      final mult = _waveForceMultiplier(waveScreen, _boatPos, visibleObs);
      final blocked = mult < 0.5;
      final angleToBoat = math.atan2(
        _boatPos.dy - waveScreen.dy,
        _boatPos.dx - waveScreen.dx,
      );

      final colorIdx = ownerColorIndex[w.ownerId] ?? 0;
      waves.add(WaveRenderData(
        screenCenter: waveScreen,
        sigma: sigma,
        opacity: opacity,
        strokeWidth: strokeWidth.clamp(2.0, 14.0),
        blocked: blocked,
        angleToBoat: angleToBoat,
        waveColor: _waveColors[colorIdx],
      ));
    }
    // z-order: oldest → newest in list → painter draws oldest first → newest on top

    final obstacles = visibleObs.map((o) => ObstacleRenderData(
          type: o.type,
          screenPos: Offset(o.worldX, _scrollOffset - o.worldY),
          visualSize: o.visualSize,
          angle:      o.angle,
          halfLength: o.halfLength,
          phase:      o.type == ObstacleType.whirlpool ? _elapsedSeconds : 0.0,
        )).toList();

    final foam = _foam.map((p) => FoamParticleRenderData(
          screenPos: p.position,
          radius: 4.0 * (1 - p.ageRatio) + 1.0,
          opacity: (1 - p.ageRatio) * 0.85,
        )).toList();

    final skyColor = _computeSkyColor();

    return PaperShipRenderSnapshot(
      boatPos: _boatPos,
      boatAngle: _boatAngle,
      shakeAmount: _shakeAmount,
      wakeTrail: List.unmodifiable(_wakeTrail),
      waves: waves,
      obstacles: obstacles,
      foam: foam,
      distanceTraveled: _distanceTraveled,
      skyColor: skyColor,
      currentBiome: _chunks.currentBiome,
    );
  }

  Color _computeSkyColor() {
    final t = (_distanceTraveled / _skyPaletteStep) % _skyPalette.length;
    final idx = t.floor() % _skyPalette.length;
    final next = (idx + 1) % _skyPalette.length;
    return Color.lerp(_skyPalette[idx], _skyPalette[next], t - t.floor())!;
  }

  // ── LAN sync helpers ─────────────────────────────────────

  Map<String, dynamic> buildSyncPayload() {
    return {
      'bx': _boatPos.dx / cw,
      'by': _boatPos.dy / ch,
      'bvx': _boatVelocity.dx / _maxBoatSpeed,
      'bvy': _boatVelocity.dy / _maxBoatSpeed,
      'scrollN': _scrollOffset / ch,
      'distN': _distanceTraveled / ch,
      'camV': _cameraVelocity / _maxBoatSpeed,
      'waves': _waves.map((w) => {
            'id': w.id,
            'ox': w.worldX / cw,
            // Normalize worldY relative to scrollOffset so it maps to [−1, 0]
            // on the client regardless of screen size.
            'oy': (w.worldY - _scrollOffset) / ch,
            'age': w.age,
            'ownerId': w.ownerId,
          }).toList(),
    };
  }

  void applyHostSnapshot(Map<String, dynamic> data) {
    final nx = (data['bx'] as num).toDouble();
    final ny = (data['by'] as num).toDouble();
    final targetPos = Offset(nx * cw, ny * ch);

    _boatPos = Offset.lerp(_boatPos, targetPos, 0.25)!;

    final nvx = (data['bvx'] as num? ?? 0).toDouble();
    final nvy = (data['bvy'] as num? ?? 0).toDouble();
    _boatVelocity = Offset(nvx * _maxBoatSpeed, nvy * _maxBoatSpeed);

    _scrollOffset = (data['scrollN'] as num).toDouble() * ch;
    _distanceTraveled = (data['distN'] as num).toDouble() * ch;
    _cameraVelocity = ((data['camV'] as num? ?? 0).toDouble() * _maxBoatSpeed)
        .clamp(0.0, _maxBoatSpeed * 2.0);

    _waves.clear();
    final waveList = data['waves'] as List<dynamic>? ?? [];
    for (final w in waveList) {
      final wave = _WaveSource(
        id: (w['id'] as num).toInt(),
        worldX: (w['ox'] as num).toDouble() * cw,
        // Restore worldY from scroll-relative normalized value
        worldY: _scrollOffset + (w['oy'] as num).toDouble() * ch,
        ownerId: w['ownerId'] as String? ?? '',
      );
      wave.age = (w['age'] as num).toDouble();
      _waves.add(wave);
    }

    _chunks.ensureAhead(_scrollOffset + ch * 2);
    _chunks.cullBehind(_scrollOffset - ch);
  }
}
