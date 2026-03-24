import 'dart:math' as math;
import 'package:flutter/material.dart' show Color, Offset;

// ── Render data passed to CustomPainter ──────────────────────────────────

class FireflyRenderData {
  final int id;
  final Offset position;
  final double glowPhase; // 0..2π — drives size, opacity, colour pulsing

  const FireflyRenderData({
    required this.id,
    required this.position,
    required this.glowPhase,
  });
}

class FireflyWorldRenderSnapshot {
  final List<FireflyRenderData> fireflies; // only active (visible) fireflies
  final Offset lampPos;
  final double lampBrightness;  // 0..1 (0 = attract/dim, 1 = repel/bright)
  final Color lampColor;        // lerped between attract/repel colours
  final Offset jarPos;
  final int totalCaught;        // cumulative score (increases forever)

  const FireflyWorldRenderSnapshot({
    required this.fireflies,
    required this.lampPos,
    required this.lampBrightness,
    required this.lampColor,
    required this.jarPos,
    required this.totalCaught,
  });
}

// ── Internal per-firefly state ────────────────────────────────────────────

class _FireflyData {
  final int id;
  Offset position;
  Offset velocity;
  double wanderAngle;   // current heading angle (radians)
  double glowPhase;     // 0..2π, unique per firefly

  bool caught = false;
  double respawnTimer = 0.0; // counts down after catch; 0 = active

  _FireflyData({
    required this.id,
    required this.position,
    required this.velocity,
    required this.wanderAngle,
    required this.glowPhase,
  });
}

// ── FireflyWorld ──────────────────────────────────────────────────────────

class FireflyWorld {
  // ── Tunables ────────────────────────────────────────────────────────────
  static const double _maxSpeed = 160.0;         // px/s
  static const double _maxTurnRate = 1.8;        // rad/s (wander)
  static const double _dampingBase = 0.96;       // per-frame factor at 60Hz
  static const double _lampRadius = 220.0;       // px — influence zone
  static const double _lampStrength = 18000.0;   // force magnitude
  static const double _epsilon = 200.0;          // softened gravity ε
  static const double _jarCatchRadius = 44.0;    // px — catch hitbox
  static const double _boundaryMargin = 40.0;    // px — soft boundary zone
  static const double _boundaryForce = 280.0;    // px/s² — push back to centre
  static const double _glowSpeed = 1.3;          // rad/s — pulse rate
  static const double _respawnDelay = 2.0;       // seconds before respawn

  // Lamp colour constants
  static const Color _attractColor = Color(0xFF5BA3FF); // cool blue — dim/attract
  static const Color _repelColor  = Color(0xFFFFE680);  // warm yellow — bright/repel

  // ── Canvas dimensions ───────────────────────────────────────────────────
  final double _cw;
  final double _ch;

  // ── Mutable state ───────────────────────────────────────────────────────
  final List<_FireflyData> _fireflies = [];
  final math.Random _rng;

  Offset _lampPos;
  double _lampBrightness = 0.0;   // 0 = attract, 1 = repel
  double _lampColorT = 0.0;       // animated lerp value for colour transition
  static const double _colorTransitionSpeed = 2.0; // seconds to full transition

  Offset _jarPos;
  int _totalCaught = 0;           // cumulative score

  void Function()? onFireflyCaught;

  int get totalCaught => _totalCaught;

  // ── Constructor ─────────────────────────────────────────────────────────

  FireflyWorld({
    required double canvasWidth,
    required double canvasHeight,
    required int maxOnScreen,
    required int seed,
  })  : _cw = canvasWidth,
        _ch = canvasHeight,
        _rng = math.Random(seed),
        _lampPos = Offset(canvasWidth * 0.35, canvasHeight * 0.5),
        _jarPos  = Offset(canvasWidth * 0.65, canvasHeight * 0.5) {
    _spawnFireflies(maxOnScreen, seed);
  }

  void _spawnFireflies(int count, int seed) {
    final rng = math.Random(seed);
    for (int i = 0; i < count; i++) {
      _fireflies.add(_makeFirefly(i, rng));
    }
  }

  _FireflyData _makeFirefly(int id, math.Random rng) {
    final x = _boundaryMargin + rng.nextDouble() * (_cw - _boundaryMargin * 2);
    final y = _boundaryMargin + rng.nextDouble() * (_ch - _boundaryMargin * 2);
    final angle = rng.nextDouble() * 2 * math.pi;
    final speed = 20.0 + rng.nextDouble() * 40.0;
    return _FireflyData(
      id: id,
      position: Offset(x, y),
      velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
      wanderAngle: angle,
      glowPhase: rng.nextDouble() * 2 * math.pi,
    );
  }

  void _respawnFirefly(_FireflyData f) {
    final x = _boundaryMargin + _rng.nextDouble() * (_cw - _boundaryMargin * 2);
    final y = _boundaryMargin + _rng.nextDouble() * (_ch - _boundaryMargin * 2);
    final angle = _rng.nextDouble() * 2 * math.pi;
    final speed = 20.0 + _rng.nextDouble() * 40.0;
    f.position = Offset(x, y);
    f.velocity = Offset(math.cos(angle) * speed, math.sin(angle) * speed);
    f.wanderAngle = angle;
    f.glowPhase = _rng.nextDouble() * 2 * math.pi;
    f.caught = false;
    f.respawnTimer = 0.0;
  }

  // ── Public controls ──────────────────────────────────────────────────────

  void setLampPos(Offset screenPos) => _lampPos = screenPos;

  /// [brightness] 0.0 = dim/attract, 1.0 = bright/repel.
  void setLampBrightness(double brightness) =>
      _lampBrightness = brightness.clamp(0.0, 1.0);

  void setJarPos(Offset screenPos) => _jarPos = screenPos;

  // ── Simulation step ──────────────────────────────────────────────────────

  /// Advance simulation by [dt] seconds. Returns true if any firefly moved.
  bool step(double dt) {
    // Animate lamp colour transition
    final targetT = _lampBrightness;
    if ((_lampColorT - targetT).abs() > 0.005) {
      final step = _colorTransitionSpeed * dt;
      _lampColorT = (_lampColorT + (targetT - _lampColorT).sign * step)
          .clamp(0.0, 1.0);
    } else {
      _lampColorT = targetT;
    }

    bool moved = false;
    final damping = math.pow(_dampingBase, dt * 60).toDouble();

    for (final f in _fireflies) {
      // Respawn countdown
      if (f.caught) {
        f.respawnTimer -= dt;
        if (f.respawnTimer <= 0) _respawnFirefly(f);
        moved = true;
        continue;
      }

      // 1. Wander — gentle random steering
      f.wanderAngle += (_rng.nextDouble() - 0.5) * 2 * _maxTurnRate * dt;
      final wanderForce = Offset(
        math.cos(f.wanderAngle) * 60.0,
        math.sin(f.wanderAngle) * 60.0,
      );
      f.velocity = Offset(
        f.velocity.dx + wanderForce.dx * dt,
        f.velocity.dy + wanderForce.dy * dt,
      );

      // 2. Lamp influence (softened gravity, avoids singularity)
      final toFirefly = f.position - _lampPos;
      final dist = toFirefly.distance;
      if (dist < _lampRadius) {
        final force = _lampStrength / (dist * dist + _epsilon);
        final dir = dist > 0.01
            ? Offset(toFirefly.dx / dist, toFirefly.dy / dist)
            : Offset.zero;
        // Dim (attract): pull toward lamp. Bright (repel): push away.
        final sign = _lampBrightness >= 0.5 ? 1.0 : -1.0;
        f.velocity = Offset(
          f.velocity.dx + dir.dx * force * sign * dt,
          f.velocity.dy + dir.dy * force * sign * dt,
        );
      }

      // 3. Soft boundary — push toward centre when near edge
      final cx = _cw / 2, cy = _ch / 2;
      if (f.position.dx < _boundaryMargin) {
        f.velocity = Offset(f.velocity.dx + _boundaryForce * dt, f.velocity.dy);
      } else if (f.position.dx > _cw - _boundaryMargin) {
        f.velocity = Offset(f.velocity.dx - _boundaryForce * dt, f.velocity.dy);
      }
      if (f.position.dy < _boundaryMargin) {
        f.velocity = Offset(f.velocity.dx, f.velocity.dy + _boundaryForce * dt);
      } else if (f.position.dy > _ch - _boundaryMargin) {
        f.velocity = Offset(f.velocity.dx, f.velocity.dy - _boundaryForce * dt);
      }
      // Gentle nudge toward centre (prevents corner clumping)
      f.velocity = Offset(
        f.velocity.dx + (cx - f.position.dx) * 0.02 * dt,
        f.velocity.dy + (cy - f.position.dy) * 0.02 * dt,
      );

      // 4. Damping
      f.velocity = f.velocity * damping;

      // 5. Speed clamp
      final speed = f.velocity.distance;
      if (speed > _maxSpeed) {
        f.velocity = f.velocity / speed * _maxSpeed;
      }

      // 6. Integrate position
      f.position = Offset(
        (f.position.dx + f.velocity.dx * dt).clamp(0, _cw),
        (f.position.dy + f.velocity.dy * dt).clamp(0, _ch),
      );

      // 7. Glow phase
      f.glowPhase = (f.glowPhase + _glowSpeed * dt) % (2 * math.pi);

      moved = true;
    }

    return moved;
  }

  // ── Catch check ──────────────────────────────────────────────────────────

  /// Check if jar overlaps any active firefly. Returns ids of newly caught.
  List<int> checkCatch() {
    final caught = <int>[];
    for (final f in _fireflies) {
      if (f.caught) continue;
      if ((f.position - _jarPos).distance < _jarCatchRadius) {
        _markCaught(f);
        caught.add(f.id);
      }
    }
    return caught;
  }

  /// Mark a specific firefly as caught (used by LAN catchEvent from host).
  void catchFireflyById(int id) {
    final f = _fireflies.firstWhere((x) => x.id == id, orElse: () => _fireflies.first);
    if (!f.caught) _markCaught(f);
  }

  void _markCaught(_FireflyData f) {
    f.caught = true;
    f.respawnTimer = _respawnDelay;
    _totalCaught++;
    onFireflyCaught?.call();
  }

  // ── Render snapshot ──────────────────────────────────────────────────────

  FireflyWorldRenderSnapshot buildRenderData() {
    final lampColor = Color.lerp(_attractColor, _repelColor, _lampColorT)!;
    return FireflyWorldRenderSnapshot(
      fireflies: _fireflies
          .where((f) => !f.caught)
          .map((f) => FireflyRenderData(
                id: f.id,
                position: f.position,
                glowPhase: f.glowPhase,
              ))
          .toList(),
      lampPos: _lampPos,
      lampBrightness: _lampBrightness,
      lampColor: lampColor,
      jarPos: _jarPos,
      totalCaught: _totalCaught,
    );
  }

  // ── LAN sync helpers ─────────────────────────────────────────────────────

  /// Build a compact list for the 20Hz host→client sync packet.
  /// Only includes active (visible) fireflies; caught ones are hidden.
  List<Map<String, dynamic>> buildSyncPayload() {
    return _fireflies
        .where((f) => !f.caught)
        .map((f) => {
              'id': f.id,
              'nx': f.position.dx / _cw,
              'ny': f.position.dy / _ch,
              'phase': f.glowPhase,
            })
        .toList();
  }

  /// Apply a sync payload received from host.
  List<Map<String, dynamic>> parseSyncPayload(List<dynamic> raw) =>
      raw.cast<Map<String, dynamic>>();
}
