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

  const WaveRenderData({
    required this.screenCenter,
    required this.sigma,
    required this.opacity,
    required this.strokeWidth,
    required this.blocked,
    required this.angleToBoat,
  });
}

class ObstacleRenderData {
  final ObstacleType type;
  final Offset screenPos;
  final double visualSize;

  const ObstacleRenderData({
    required this.type,
    required this.screenPos,
    required this.visualSize,
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
  });
}

// ── Internal state ────────────────────────────────────────────

class _WaveSource {
  final int id;
  final double worldX; // world-space position
  final double worldY;
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

class PaperShipWorld {
  // ── Tunables ──────────────────────────────────────────────
  static const int _maxWaves = 8;
  static const double _waveSpeedPx = 120.0;   // px/s — ring expansion speed
  static const double _waveDampingRate = 1.4;  // amplitude halved ~every 0.5s
  static const double _waveMaxForce = 420.0;   // px/s² max acceleration impulse
  static const double _wavePulseWidth = 28.0;  // ring thickness parameter
  static const double _waveMaxRadius = 580.0;  // cull threshold
  static const double _boatMass = 1.0;
  static const double _boatDampingBase = 0.94; // per-frame at 60Hz
  static const double _maxBoatSpeed = 380.0;   // px/s
  static const double _stiffness = 1500.0;     // repulsion px/s² per px penetration
  static const double _shakeScale = 0.04;
  static const double _shakeDampingBase = 0.85;
  static const double _scrollSpeed = 45.0;     // px/s — world scrolls toward boat
  static const double _boatAnchorY = 0.68;     // boat rests at 68% from top
  static const double _boatRadius = 18.0;      // hitbox radius (px)

  // Sky palette: day → sunset → dusk
  static const _skyPalette = [
    Color(0xFF87CEEB), // light blue
    Color(0xFFFFB347), // orange sunset
    Color(0xFF9370DB), // purple dusk
    Color(0xFF2C3E70), // deep night
  ];
  static const double _skyPaletteStep = 1500.0; // px per palette segment

  // ── Canvas dimensions ────────────────────────────────────
  final double cw;
  final double ch;

  // ── Chunk manager ────────────────────────────────────────
  late final ChunkManager _chunks;

  // ── Boat state ───────────────────────────────────────────
  late Offset _boatPos;
  Offset _boatVelocity = Offset.zero;
  double _boatAngle = 0.0;          // visual only; low-pass filtered
  double _shakeAmount = 0.0;
  final List<Offset> _wakeTrail = [];
  static const int _wakeLength = 12;

  // ── Wave sources ─────────────────────────────────────────
  final List<_WaveSource> _waves = [];
  int _nextWaveId = 0;

  // ── Foam ─────────────────────────────────────────────────
  final List<_FoamParticle> _foam = [];

  // ── Scroll / distance ────────────────────────────────────
  double _scrollOffset = 0.0;  // world-Y of viewport top (grows over time)
  double _distanceTraveled = 0.0;

  final math.Random _rng;

  // ── Constructor ──────────────────────────────────────────

  PaperShipWorld({
    required this.cw,
    required this.ch,
    required int seed,
  }) : _rng = math.Random(seed) {
    _boatPos = Offset(cw * 0.5, ch * _boatAnchorY);
    _chunks = ChunkManager(canvasWidth: cw, canvasHeight: ch, seed: seed);
    // Pre-generate 3 chunks ahead
    _chunks.ensureAhead(_scrollOffset + ch * 3);
  }

  double get distanceTraveled => _distanceTraveled;

  // ── Wave spawning ────────────────────────────────────────

  void spawnWave(double screenX, double screenY, String ownerId) {
    // Convert screen coords to world coords
    final worldX = screenX;
    final worldY = screenY + _scrollOffset;

    if (_waves.length >= _maxWaves) {
      _waves.removeAt(0); // drop oldest
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
    _advanceWaves(dt);
    final totalForce = _computeBoatForce();
    _integrateBoat(dt, totalForce);
    _checkBoatObstacleCollision();
    _advanceFoam(dt);
    _advanceScroll(dt);
    _updateWakeTrail();
  }

  /// Client-side step: only advance foam and update boat angle visuals.
  /// Boat position is set by [applyHostSnapshot].
  void stepClient(double dt) {
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

  // ── Force computation ────────────────────────────────────

  Offset _computeBoatForce() {
    var total = Offset.zero;
    final visibleObstacles = _visibleObstacles();

    for (final w in _waves) {
      final sigma = _waveSpeedPx * w.age;
      final amplitude = _waveMaxForce * math.exp(-w.age * _waveDampingRate);
      if (amplitude < 0.5) continue;

      // Wave and boat in world coords
      final waveWorld = Offset(w.worldX, w.worldY);
      final boatWorld = Offset(_boatPos.dx, _boatPos.dy + _scrollOffset);
      final delta = boatWorld - waveWorld;
      final d = delta.distance;
      if (d < 0.1) continue;

      // Gaussian pulse: maximum when boat is on the ring
      final pulseArg = (d - sigma) / _wavePulseWidth;
      final F = amplitude * math.exp(-0.5 * pulseArg * pulseArg);
      if (F < 0.5) continue;

      final dir = delta / d;

      // 3-ray multiplier
      final mult = _waveForceMultiplier(waveWorld, boatWorld, visibleObstacles);
      total = Offset(total.dx + dir.dx * F * mult, total.dy + dir.dy * F * mult);
    }

    return total;
  }

  // 3-ray raycasting: returns 0.0..1.0 (fraction of unblocked rays)
  double _waveForceMultiplier(
      Offset from, Offset to, List<ShipObstacle> obstacles) {
    final dir = to - from;
    final dist = dir.distance;
    if (dist < 0.1) return 1.0;
    final perp = Offset(-dir.dy, dir.dx) / dist * _boatRadius;
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
      final f = from - Offset(o.worldX, o.worldY);
      final a = d.dx * d.dx + d.dy * d.dy;
      if (a < 0.0001) continue;
      final b = 2 * (f.dx * d.dx + f.dy * d.dy);
      final c = f.dx * f.dx + f.dy * f.dy - o.radius * o.radius;
      final discriminant = b * b - 4 * a * c;
      if (discriminant >= 0) {
        // Check that intersection is within segment (t in 0..1)
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
    final accel = Offset(force.dx / _boatMass, force.dy / _boatMass);
    _boatVelocity = _boatVelocity + accel * dt;

    final damping = math.pow(_boatDampingBase, dt * 60).toDouble();
    _boatVelocity = _boatVelocity * damping;

    final speed = _boatVelocity.distance;
    if (speed > _maxBoatSpeed) {
      _boatVelocity = _boatVelocity / speed * _maxBoatSpeed;
    }

    _boatPos = _boatPos + _boatVelocity * dt;

    // Soft side-boundary: prevent boat from leaving visible area
    const padX = 30.0;
    const padBottom = 40.0;
    if (_boatPos.dx < padX) {
      _boatVelocity = Offset((_boatVelocity.dx + 800 * dt).clamp(0, double.infinity), _boatVelocity.dy);
      _boatPos = Offset(_boatPos.dx.clamp(padX, cw - padX), _boatPos.dy);
    } else if (_boatPos.dx > cw - padX) {
      _boatVelocity = Offset((_boatVelocity.dx - 800 * dt).clamp(double.negativeInfinity, 0), _boatVelocity.dy);
      _boatPos = Offset(_boatPos.dx.clamp(padX, cw - padX), _boatPos.dy);
    }
    if (_boatPos.dy > ch - padBottom) {
      _boatVelocity = Offset(_boatVelocity.dx, (_boatVelocity.dy - 600 * dt).clamp(double.negativeInfinity, 0));
      _boatPos = Offset(_boatPos.dx, _boatPos.dy.clamp(0, ch - padBottom));
    }
    if (_boatPos.dy < 0) {
      _boatVelocity = Offset(_boatVelocity.dx, (_boatVelocity.dy + 600 * dt).clamp(0, double.infinity));
      _boatPos = Offset(_boatPos.dx, _boatPos.dy.clamp(0, ch - padBottom));
    }

    _updateBoatAngleSmooth(dt);
  }

  void _updateBoatAngleSmooth(double dt) {
    final speed = _boatVelocity.distance;
    if (speed > 5.0) {
      final targetAngle = math.atan2(_boatVelocity.dy, _boatVelocity.dx);
      // Low-pass filter: lerp toward target
      double diff = targetAngle - _boatAngle;
      // Wrap to [-π, π]
      while (diff > math.pi) { diff -= 2 * math.pi; }
      while (diff < -math.pi) { diff += 2 * math.pi; }
      _boatAngle += diff * (1 - math.pow(0.92, dt * 60));
    }
    _shakeAmount = (_shakeAmount * math.pow(_shakeDampingBase, dt * 60)).toDouble();
  }

  // ── Collision / repulsion ────────────────────────────────

  void _checkBoatObstacleCollision() {
    final boatWorld = Offset(_boatPos.dx, _boatPos.dy + _scrollOffset);
    for (final o in _visibleObstacles()) {
      final obs = Offset(o.worldX, o.worldY);
      final delta = boatWorld - obs;
      final dist = delta.distance;
      final minDist = o.radius + _boatRadius;
      if (dist < minDist && dist > 0.1) {
        final penetration = minDist - dist;
        final normal = delta / dist;

        // Impulse-like repulsion applied directly to velocity
        final repulsion = _stiffness * penetration;
        _boatVelocity = Offset(
          _boatVelocity.dx + normal.dx * repulsion * (1 / 60.0),
          _boatVelocity.dy + normal.dy * repulsion * (1 / 60.0),
        );

        // Push out of overlap
        _boatPos = Offset(
          _boatPos.dx + normal.dx * penetration * 0.5,
          _boatPos.dy + normal.dy * penetration * 0.5,
        );

        _shakeAmount = (_shakeAmount + penetration * _shakeScale).clamp(0.0, 6.0);

        // Spawn foam particles at contact point
        _spawnFoam(boatWorld - normal * _boatRadius);
      }
    }
  }

  void _spawnFoam(Offset worldPos) {
    // Convert world → screen
    final screen = Offset(worldPos.dx, worldPos.dy - _scrollOffset);
    final count = 3 + _rng.nextInt(3);
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 30.0 + _rng.nextDouble() * 60.0;
      _foam.add(_FoamParticle(
        position: screen,
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        lifetime: 0.5 + _rng.nextDouble() * 0.4,
      ));
    }
    // Cap foam count
    if (_foam.length > 60) _foam.removeRange(0, _foam.length - 60);
  }

  // ── Foam advancement ─────────────────────────────────────

  void _advanceFoam(double dt) {
    for (final p in _foam) {
      p.age += dt;
      p.velocity = p.velocity * 0.92; // damping
      p.position = p.position + p.velocity * dt;
    }
    _foam.removeWhere((p) => p.isDead);
  }

  // ── Scroll advancement ───────────────────────────────────

  void _advanceScroll(double dt) {
    // Scroll speed increases slightly with distance for difficulty progression
    final speedMultiplier = 1.0 + (_distanceTraveled / 5000.0).clamp(0.0, 2.0);
    final delta = _scrollSpeed * speedMultiplier * dt;
    _scrollOffset += delta;
    _distanceTraveled += delta;
    _chunks.ensureAhead(_scrollOffset + ch * 2);
    _chunks.cullBehind(_scrollOffset);
  }

  // ── Wake trail ───────────────────────────────────────────

  void _updateWakeTrail() {
    _wakeTrail.insert(0, _boatPos);
    if (_wakeTrail.length > _wakeLength) {
      _wakeTrail.removeRange(_wakeLength, _wakeTrail.length);
    }
  }

  // ── Visible obstacles ────────────────────────────────────

  List<ShipObstacle> _visibleObstacles() {
    return _chunks.obstaclesInRange(
      _scrollOffset - ch * 0.1,
      _scrollOffset + ch * 1.1,
    );
  }

  // ── Render snapshot ──────────────────────────────────────

  PaperShipRenderSnapshot buildRenderData() {
    final visibleObs = _visibleObstacles();
    final boatWorld = Offset(_boatPos.dx, _boatPos.dy + _scrollOffset);

    final waves = <WaveRenderData>[];
    for (final w in _waves) {
      final sigma = _waveSpeedPx * w.age;
      final amplitude = _waveMaxForce * math.exp(-w.age * _waveDampingRate);
      if (amplitude < 0.5) continue;

      // Wave center screen position
      final screenX = w.worldX;
      final screenY = w.worldY - _scrollOffset;

      final opacity = (amplitude / _waveMaxForce).clamp(0.0, 1.0);
      final strokeWidth = _wavePulseWidth *
          math.exp(-0.5 * math.pow(w.age * _waveDampingRate / 2.0, 2));

      final waveOrigin = Offset(w.worldX, w.worldY);
      final mult = _waveForceMultiplier(waveOrigin, boatWorld, visibleObs);
      final blocked = mult < 0.5;
      final angleToBoat = math.atan2(
        boatWorld.dy - w.worldY,
        boatWorld.dx - w.worldX,
      );

      waves.add(WaveRenderData(
        screenCenter: Offset(screenX, screenY),
        sigma: sigma,
        opacity: opacity,
        strokeWidth: strokeWidth.clamp(2.0, 14.0),
        blocked: blocked,
        angleToBoat: angleToBoat,
      ));
    }

    final obstacles = visibleObs.map((o) => ObstacleRenderData(
          type: o.type,
          screenPos: Offset(o.worldX, o.worldY - _scrollOffset),
          visualSize: o.visualSize,
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
      'scroll': _scrollOffset,
      'dist': _distanceTraveled,
      'waves': _waves.map((w) => {
            'id': w.id,
            'ox': w.worldX / cw,
            'oy': w.worldY / ch,  // relative to canvas height (approx)
            'age': w.age,
            'ownerId': w.ownerId,
          }).toList(),
    };
  }

  void applyHostSnapshot(Map<String, dynamic> data) {
    final nx = (data['bx'] as num).toDouble();
    final ny = (data['by'] as num).toDouble();
    final targetPos = Offset(nx * cw, ny * ch);

    // Lerp boat to host position
    _boatPos = Offset.lerp(_boatPos, targetPos, 0.25)!;

    final nvx = (data['bvx'] as num? ?? 0).toDouble();
    final nvy = (data['bvy'] as num? ?? 0).toDouble();
    _boatVelocity = Offset(nvx * _maxBoatSpeed, nvy * _maxBoatSpeed);

    _scrollOffset = (data['scroll'] as num).toDouble();
    _distanceTraveled = (data['dist'] as num).toDouble();

    // Rebuild wave sources from host data
    _waves.clear();
    final waveList = data['waves'] as List<dynamic>? ?? [];
    for (final w in waveList) {
      final wave = _WaveSource(
        id: (w['id'] as num).toInt(),
        worldX: (w['ox'] as num).toDouble() * cw,
        worldY: (w['oy'] as num).toDouble() * ch,
        ownerId: w['ownerId'] as String? ?? '',
      );
      wave.age = (w['age'] as num).toDouble();
      _waves.add(wave);
    }

    _chunks.ensureAhead(_scrollOffset + ch * 2);
    _chunks.cullBehind(_scrollOffset);
  }
}
