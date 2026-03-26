import 'dart:math' as math;
import 'package:flutter/material.dart' show Color, Offset;

enum FireflyRole { lamp, jar }

// ── Render data passed to CustomPainter ──────────────────────────────────

class FireflyRenderData {
  final int id;
  final Offset position;
  final double glowPhase; // 0..2π — drives size, opacity, colour pulsing
  final bool isLit;       // true when inside a lamp radius → can be caught

  const FireflyRenderData({
    required this.id,
    required this.position,
    required this.glowPhase,
    required this.isLit,
  });
}

class ToolRenderData {
  final int id;
  final Offset position;
  final FireflyRole type;
  final double brightness;  // lamp only: 0 = attract/dim, 1 = repel/bright
  final Color lampColor;    // lerped; only meaningful for lamp

  const ToolRenderData({
    required this.id,
    required this.position,
    required this.type,
    required this.brightness,
    required this.lampColor,
  });
}

class FireflyWorldRenderSnapshot {
  final List<FireflyRenderData> fireflies; // only active (visible) fireflies
  final List<ToolRenderData> tools;
  final int totalCaught;                   // cumulative score
  final double lampRadius;                 // px — for painter glow zone
  final double jarCatchRadius;             // px — for painter jar outline

  const FireflyWorldRenderSnapshot({
    required this.fireflies,
    required this.tools,
    required this.totalCaught,
    required this.lampRadius,
    required this.jarCatchRadius,
  });
}

// ── Internal state ────────────────────────────────────────────────────────

class _FireflyData {
  final int id;
  Offset position;
  Offset velocity;
  double wanderAngle;        // current heading angle (radians)
  double wanderTargetAngle;  // target angle to rotate toward
  double wanderTimer;        // seconds until next direction pick
  double glowPhase;          // 0..2π, unique per firefly

  bool caught = false;
  double respawnTimer = 0.0; // counts down after catch; 0 = active

  _FireflyData({
    required this.id,
    required this.position,
    required this.velocity,
    required this.wanderAngle,
    required this.wanderTargetAngle,
    required this.wanderTimer,
    required this.glowPhase,
  });
}

class _ToolState {
  Offset position;
  FireflyRole type;
  double brightness = 0.0;  // lamp: 0 = attract/dim, 1 = repel/bright
  double colorT = 0.0;      // animated lerp value for colour transition

  _ToolState({required this.position, required this.type});
}

// ── FireflyWorld ──────────────────────────────────────────────────────────

class FireflyWorld {
  // ── Fixed tunables ──────────────────────────────────────────────────────
  static const double _maxSpeed = 160.0;         // px/s
  static const double _maxTurnRate = 1.8;        // rad/s (wander)
  static const double _dampingBase = 0.96;       // per-frame factor at 60Hz
  static const double _lampStrength = 300.0;     // px/s² at lamp centre (linear falloff)
  static const double _boundaryForce = 280.0;    // px/s² — push back to centre

  // ── Canvas-relative tunables (computed in constructor) ───────────────────
  late final double _lampRadius;      // _cw * 0.20 — influence zone
  late final double _jarCatchRadius;  // _cw * 0.07 — catch hitbox
  late final double _boundaryMargin;  // _cw * 0.09 — soft boundary zone
  static const double _glowSpeed = 1.3;          // rad/s — pulse rate
  static const double _respawnDelay = 2.0;       // seconds before respawn
  static const double _colorTransitionSpeed = 2.0; // s to full transition

  // Lamp colour constants
  static const Color _attractColor = Color(0xFF5BA3FF); // cool blue — dim/attract
  static const Color _repelColor  = Color(0xFFFFE680);  // warm yellow — bright/repel

  // ── Canvas dimensions ───────────────────────────────────────────────────
  final double _cw;
  final double _ch;

  // ── Mutable state ───────────────────────────────────────────────────────
  final List<_FireflyData> _fireflies = [];
  final Map<int, _ToolState> _tools = {};
  final math.Random _rng;
  int _totalCaught = 0;

  // Client-side lerp targets (set by setLerpTarget, applied in stepClient)
  final Map<int, Offset> _lerpTargets = {};

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
        _rng = math.Random(seed) {
    _lampRadius     = _cw * 0.20;
    _jarCatchRadius = _cw * 0.07;
    _boundaryMargin = _cw * 0.09;
    _spawnFireflies(maxOnScreen, seed);
  }

  double get lampRadius     => _lampRadius;
  double get jarCatchRadius => _jarCatchRadius;

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
    final targetAngle = rng.nextDouble() * 2 * math.pi;
    return _FireflyData(
      id: id,
      position: Offset(x, y),
      velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
      wanderAngle: angle,
      wanderTargetAngle: targetAngle,
      wanderTimer: 0.5 + rng.nextDouble() * 2.0,
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
    f.wanderTargetAngle = _rng.nextDouble() * 2 * math.pi;
    f.wanderTimer = 0.5 + _rng.nextDouble() * 2.0;
    f.glowPhase = _rng.nextDouble() * 2 * math.pi;
    f.caught = false;
    f.respawnTimer = 0.0;
  }

  // ── Tool management ──────────────────────────────────────────────────────

  /// Register a player's tool. Call once per player on game start.
  void addTool(int id, FireflyRole type, Offset pos) {
    _tools[id] = _ToolState(position: pos, type: type);
  }

  /// Remove a tool (e.g. player disconnected mid-game).
  void removeTool(int id) => _tools.remove(id);

  void updateToolPos(int id, Offset pos) { _tools[id]?.position = pos; }
  void switchToolType(int id, FireflyRole type) { _tools[id]?.type = type; }

  /// [brightness] 0.0 = dim/attract, 1.0 = bright/repel. Lamp only.
  void setToolBrightness(int id, double brightness) {
    final t = _tools[id];
    if (t != null) t.brightness = brightness.clamp(0.0, 1.0);
  }

  // ── Lit check ────────────────────────────────────────────────────────────

  bool _isLit(Offset pos) => _tools.values.any(
      (t) => t.type == FireflyRole.lamp && (pos - t.position).distance < _lampRadius);

  // ── Client-side lerp ─────────────────────────────────────────────────────

  /// Called by client when a fireflySync packet arrives.
  /// Also revives a firefly that was caught locally (host has respawned it).
  void setLerpTarget(int id, Offset pos, double phase) {
    _lerpTargets[id] = pos;
    final idx = _fireflies.indexWhere((f) => f.id == id);
    if (idx >= 0 && _fireflies[idx].caught) {
      _fireflies[idx].caught = false;
      _fireflies[idx].respawnTimer = 0;
      _fireflies[idx].glowPhase = phase;
      _fireflies[idx].position = pos;
    }
  }

  /// Client-only physics step: lerp firefly positions toward host targets
  /// and advance glow phases. Does NOT run wander/force physics.
  bool stepClient(double dt) {
    for (final t in _tools.values) {
      if (t.type != FireflyRole.lamp) continue;
      final target = t.brightness;
      if ((t.colorT - target).abs() > 0.005) {
        final s = _colorTransitionSpeed * dt;
        t.colorT = (t.colorT + (target - t.colorT).sign * s).clamp(0.0, 1.0);
      } else {
        t.colorT = target;
      }
    }
    for (final f in _fireflies) {
      if (f.caught) continue;
      final target = _lerpTargets[f.id];
      if (target != null) {
        f.position = Offset.lerp(f.position, target, 0.18)!;
      }
      f.glowPhase = (f.glowPhase + _glowSpeed * dt) % (2 * math.pi);
    }
    return true;
  }

  // ── Simulation step ──────────────────────────────────────────────────────

  bool step(double dt) {
    // Animate colour transition for each lamp tool
    for (final t in _tools.values) {
      if (t.type != FireflyRole.lamp) continue;
      final target = t.brightness;
      if ((t.colorT - target).abs() > 0.005) {
        final step = _colorTransitionSpeed * dt;
        t.colorT = (t.colorT + (target - t.colorT).sign * step).clamp(0.0, 1.0);
      } else {
        t.colorT = target;
      }
    }

    bool moved = false;
    final damping = math.pow(_dampingBase, dt * 60).toDouble();
    final cx = _cw / 2, cy = _ch / 2;

    for (final f in _fireflies) {
      // Respawn countdown
      if (f.caught) {
        f.respawnTimer -= dt;
        if (f.respawnTimer <= 0) _respawnFirefly(f);
        moved = true;
        continue;
      }

      // 1. Wander — timer-based random direction changes
      f.wanderTimer -= dt;
      if (f.wanderTimer <= 0) {
        f.wanderTargetAngle = _rng.nextDouble() * 2 * math.pi;
        f.wanderTimer = 0.5 + _rng.nextDouble() * 2.0;
      }
      double angleDiff = f.wanderTargetAngle - f.wanderAngle;
      if (angleDiff > math.pi) angleDiff -= 2 * math.pi;
      if (angleDiff < -math.pi) angleDiff += 2 * math.pi;
      f.wanderAngle += angleDiff.sign * math.min(angleDiff.abs(), _maxTurnRate * dt);
      f.velocity = Offset(
        f.velocity.dx + math.cos(f.wanderAngle) * 60.0 * dt,
        f.velocity.dy + math.sin(f.wanderAngle) * 60.0 * dt,
      );

      // 2. Lamp influence — linear falloff, much stronger than wander
      for (final tool in _tools.values) {
        if (tool.type != FireflyRole.lamp) continue;
        final toFirefly = f.position - tool.position;
        final dist = toFirefly.distance;
        if (dist < _lampRadius && dist > 0.01) {
          final t = 1.0 - (dist / _lampRadius); // 1 at centre, 0 at edge
          final force = _lampStrength * t;
          final dir = Offset(toFirefly.dx / dist, toFirefly.dy / dist);
          // Dim (attract): pull toward lamp. Bright (repel): push away.
          final sign = tool.brightness >= 0.5 ? 1.0 : -1.0;
          f.velocity = Offset(
            f.velocity.dx + dir.dx * force * sign * dt,
            f.velocity.dy + dir.dy * force * sign * dt,
          );
        }
      }

      // 3. Soft boundary — push toward centre when near edge
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
      f.velocity = Offset(
        f.velocity.dx + (cx - f.position.dx) * 0.02 * dt,
        f.velocity.dy + (cy - f.position.dy) * 0.02 * dt,
      );

      // 4. Damping
      f.velocity = f.velocity * damping;

      // 5. Speed clamp
      final speed = f.velocity.distance;
      if (speed > _maxSpeed) f.velocity = f.velocity / speed * _maxSpeed;

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

  /// Check if any jar overlaps an active, lit firefly. Returns caught ids.
  List<int> checkCatch() {
    final caught = <int>[];
    for (final f in _fireflies) {
      if (f.caught) continue;
      if (!_isLit(f.position)) continue; // must be illuminated to catch
      for (final tool in _tools.values) {
        if (tool.type != FireflyRole.jar) continue;
        if ((f.position - tool.position).distance < _jarCatchRadius) {
          _markCaught(f);
          caught.add(f.id);
          break;
        }
      }
    }
    return caught;
  }

  /// Mark a specific firefly as caught (used by LAN catchEvent from host).
  void catchFireflyById(int id) {
    final idx = _fireflies.indexWhere((x) => x.id == id);
    if (idx >= 0 && !_fireflies[idx].caught) _markCaught(_fireflies[idx]);
  }

  void _markCaught(_FireflyData f) {
    f.caught = true;
    f.respawnTimer = _respawnDelay;
    _totalCaught++;
    onFireflyCaught?.call();
  }

  // ── Render snapshot ──────────────────────────────────────────────────────

  FireflyWorldRenderSnapshot buildRenderData() {
    final toolRender = _tools.entries.map((e) {
      final t = e.value;
      final lampColor = Color.lerp(_attractColor, _repelColor, t.colorT)!;
      return ToolRenderData(
        id: e.key,
        position: t.position,
        type: t.type,
        brightness: t.brightness,
        lampColor: lampColor,
      );
    }).toList();

    final fireflies = _fireflies
        .where((f) => !f.caught)
        .map((f) => FireflyRenderData(
              id: f.id,
              position: f.position,
              glowPhase: f.glowPhase,
              isLit: _isLit(f.position),
            ))
        .toList();

    return FireflyWorldRenderSnapshot(
      fireflies: fireflies,
      tools: toolRender,
      totalCaught: _totalCaught,
      lampRadius: _lampRadius,
      jarCatchRadius: _jarCatchRadius,
    );
  }

  // ── LAN sync helpers ─────────────────────────────────────────────────────

  /// Build a compact payload for the 20Hz host→client sync packet.
  Map<String, dynamic> buildSyncPayload() {
    return {
      'fireflies': _fireflies
          .where((f) => !f.caught)
          .map((f) => {
                'id': f.id,
                'nx': f.position.dx / _cw,
                'ny': f.position.dy / _ch,
                'phase': f.glowPhase,
              })
          .toList(),
      'tools': _tools.entries
          .map((e) => {
                'id': e.key,
                'nx': e.value.position.dx / _cw,
                'ny': e.value.position.dy / _ch,
                'role': e.value.type.name,
                'brightness': e.value.brightness,
              })
          .toList(),
    };
  }
}
