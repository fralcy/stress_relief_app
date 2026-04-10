import 'dart:math' as math;
import 'package:flutter/material.dart' show Color, Offset;
import 'package:forge2d/forge2d.dart';

// ── Coordinate conversion ─────────────────────────────────────────────────
// Forge2D: Y-up, meters (MKS). Screen: Y-down, pixels.
// kPixelsPerMeter is the scale factor between the two spaces.

// kPixelsPerMeter is kept as a public constant for external callers that still
// reference it (e.g. velocity de-normalisation in the modal). Inside
// RockPhysicsWorld, the adaptive _ppm field is used instead so that all
// devices share the same canonical 9×16 m world regardless of screen size.
const double kPixelsPerMeter = 50.0;

Vector2 screenToWorld(double px, double py, double canvasHeight, double ppm) =>
    Vector2(px / ppm, (canvasHeight - py) / ppm);

Offset worldToScreen(Vector2 pos, double canvasHeight, double ppm) =>
    Offset(pos.x * ppm, canvasHeight - pos.y * ppm);

// Angles: screen uses CW-positive, Forge2D uses CCW-positive → negate.
double screenAngleToWorld(double a) => -a;
double worldAngleToScreen(double a) => -a;

// ── Render snapshot passed to CustomPainter ──────────────────────────────

class RockRenderData {
  final int id;
  final List<Offset> screenVerts; // absolute screen coords (pre-computed)
  final Offset screenPos;         // center in pixels (for peer emoji placement)
  final Color color;
  final bool isGrabbedByMe;       // grabbed by the local player
  final String? lockedBy;         // non-null = held by a peer

  const RockRenderData({
    required this.id,
    required this.screenVerts,
    required this.screenPos,
    required this.color,
    required this.isGrabbedByMe,
    required this.lockedBy,
  });
}

// ── Internal per-rock state ───────────────────────────────────────────────

class _RockData {
  final int id;
  final Body body;
  final List<Vector2> localVertsMeters; // shape verts in body-local coords (meters)
  final Color color;

  String? lockedBy;          // peer playerId holding this rock
  bool isGrabbedLocally = false; // grabbed by local player

  // Target position for the local drag — updated by moveRock each pan event.
  // _applyLerps re-derives velocity from this before every physics step so
  // multi-step frames don't overshoot and cause oscillation.
  Vector2? dragTarget;

  // Lerp targets used for smooth peer interpolation (dragUpdate / snapshot)
  Vector2? lerpTargetPos;
  double? lerpTargetAngle;

  _RockData({
    required this.id,
    required this.body,
    required this.localVertsMeters,
    required this.color,
  });
}

// ── Contact listener for SFX callbacks ───────────────────────────────────

class _RockContactListener extends ContactListener {
  final Set<Body> _staticBodies;
  final void Function() onRockRockContact;
  final void Function() onRockGroundContact;

  _RockContactListener(
    this._staticBodies, {
    required this.onRockRockContact,
    required this.onRockGroundContact,
  });

  @override
  void beginContact(Contact contact) {
    final a = contact.fixtureA.body;
    final b = contact.fixtureB.body;
    final hitsStatic = _staticBodies.contains(a) || _staticBodies.contains(b);
    if (hitsStatic) {
      onRockGroundContact();
    } else {
      onRockRockContact();
    }
  }

  @override
  void endContact(Contact contact) {}

  @override
  void preSolve(Contact contact, Manifold oldManifold) {}

  @override
  void postSolve(Contact contact, ContactImpulse impulse) {}
}

// ── RockPhysicsWorld ──────────────────────────────────────────────────────

class RockPhysicsWorld {
  static const double _fixedDt = 1.0 / 60.0;

  // Ground line as fraction of canvas height from the top (same on all devices).
  // Previously used a 20px constant which gave different world-space groundYM
  // on each screen size, causing rocks received from the host to embed into
  // the client's ground and trigger violent correction impulses.
  static const double groundFraction = 0.97; // ground at 97 % of canvas height (public for modal)

  final double _cw; // canvas width in pixels
  final double _ch; // canvas height in pixels
  late final double _ppm; // pixels per meter — adaptive so world is always 9×16 m

  late final World _world;
  final Map<int, _RockData> _rocks = {};
  final Set<Body> _staticBodies = {};

  // SFX callbacks — set by the modal after construction.
  void Function()? onRockHit;
  void Function()? onRockLand;

  double get groundYPixels => _ch * groundFraction;

  /// Expose adaptive PPM so the modal can use it for velocity de-normalisation.
  double get pixelsPerMeter => _ppm;

  RockPhysicsWorld({required double canvasWidth, required double canvasHeight})
      : _cw = canvasWidth,
        _ch = canvasHeight {
    // Adaptive scale: world is always 9×16 m regardless of screen size.
    // This makes physics body sizes identical on all devices.
    _ppm = _ch / 16.0;
    _world = World(Vector2(0, -9.8));
    _setupStaticBodies();
    _world.setContactListener(_RockContactListener(
      _staticBodies,
      onRockRockContact: () => onRockHit?.call(),
      onRockGroundContact: () => onRockLand?.call(),
    ));
  }

  // ── Static body setup (ground + walls) ─────────────────────────────────

  void _setupStaticBodies() {
    final canvasWM = _cw / _ppm;
    final canvasHM = _ch / _ppm;
    // Ground is at groundFraction of canvas height from top in screen coords.
    // In Forge2D Y-up: groundY_world = (1 - groundFraction) * 16m
    final groundYM = (1.0 - groundFraction) * 16.0;

    final bodyDef = BodyDef()..type = BodyType.static;
    final staticBody = _world.createBody(bodyDef);

    // Ground edge with high friction so rocks don't slide
    staticBody.createFixture(
      FixtureDef(EdgeShape()..set(Vector2(0, groundYM), Vector2(canvasWM, groundYM)))
        ..friction = 1.0,
    );
    // Left wall — extended 4× canvas height so fast rocks can't escape upward
    staticBody.createFixture(
      FixtureDef(EdgeShape()..set(Vector2(0, 0), Vector2(0, canvasHM * 4)))
        ..friction = 1.0,
    );
    // Right wall
    staticBody.createFixture(
      FixtureDef(EdgeShape()..set(Vector2(canvasWM, 0), Vector2(canvasWM, canvasHM * 4)))
        ..friction = 1.0,
    );

    _staticBodies.add(staticBody);
  }

  // ── Rock management ─────────────────────────────────────────────────────

  /// Add a rock to the world.
  /// [localVertsPixels]: convex polygon vertices centered at origin, in pixels.
  /// [spawnPosPixels]: spawn position in screen coords.
  /// [spawnAngle]: spawn rotation in screen convention (CW positive).
  void addRock({
    required int id,
    required List<Offset> localVertsPixels,
    required Color color,
    required Offset spawnPosPixels,
    required double spawnAngle,
  }) {
    final vertsMeters = _prepareVerts(localVertsPixels);
    final spawnPosWorld = screenToWorld(spawnPosPixels.dx, spawnPosPixels.dy, _ch, _ppm);
    final spawnAngleWorld = screenAngleToWorld(spawnAngle);

    final bodyDef = BodyDef()
      ..type = BodyType.dynamic
      ..position = spawnPosWorld
      ..angle = spawnAngleWorld
      ..allowSleep = true;

    final body = _world.createBody(bodyDef);
    body.linearDamping = 3.0;
    body.angularDamping = 3.0;

    final shape = PolygonShape()..set(vertsMeters);
    body.createFixture(FixtureDef(shape)
      ..density = 1.0
      ..friction = 0.8
      ..restitution = 0.05);

    _rocks[id] = _RockData(
      id: id,
      body: body,
      localVertsMeters: vertsMeters,
      color: color,
    );
  }

  /// Convert pixel vertices (centered at origin) to meter vertices with
  /// correct CCW winding for Forge2D's Y-up body frame.
  List<Vector2> _prepareVerts(List<Offset> pixelVerts) {
    var v = pixelVerts;
    // Forge2D PolygonShape supports max 8 vertices.
    if (v.length > 8) {
      v = List.generate(
        8,
        (i) => pixelVerts[(i * pixelVerts.length / 8).round() % pixelVerts.length],
      );
    }
    // Scale to meters. No Y-sign flip — local body frame matches world Y-up.
    // The input hull from randomConvexPolygon is CCW in screen-Y-down space,
    // which is CW in Y-up body frame → reverse the list for CCW.
    return v
        .map((o) => Vector2(o.dx / _ppm, o.dy / _ppm))
        .toList()
        .reversed
        .toList();
  }

  // ── Tick ──────────────────────────────────────────────────────────────

  /// Advance physics by [dtSeconds]. Returns true while any body is awake.
  bool step(double dtSeconds) {
    _applyLerps();
    _world.stepDt(dtSeconds);
    return _rocks.values.any((r) => r.body.isAwake);
  }

  void _applyLerps() {
    for (final rock in _rocks.values) {
      // Locally dragged rock: re-derive velocity each step so multi-step frames
      // don't overshoot (the previous velocity-in-moveRock approach set vel once
      // per pan event, causing overshoot + oscillation on frame drops).
      if (rock.isGrabbedLocally) {
        final target = rock.dragTarget ?? rock.body.position;
        rock.body.linearVelocity = (target - rock.body.position) * (1 / _fixedDt);
        rock.body.angularVelocity = 0;
        continue;
      }

      final tp = rock.lerpTargetPos;
      if (tp == null) continue;

      final cur = rock.body.position;
      final next = Vector2(
        cur.x + (tp.x - cur.x) * 0.2,
        cur.y + (tp.y - cur.y) * 0.2,
      );

      double nextAngle = rock.body.angle;
      final ta = rock.lerpTargetAngle;
      if (ta != null) {
        nextAngle = rock.body.angle + (ta - rock.body.angle) * 0.2;
        if ((nextAngle - ta).abs() < 0.005) {
          nextAngle = ta;
          if (rock.lockedBy == null) rock.lerpTargetAngle = null;
        }
      }

      final wasAwake = rock.body.isAwake;
      final dist = (next - tp).length;
      if (dist < 0.016) {
        // ~0.8 px — close enough, snap to target
        rock.body.setTransform(tp, nextAngle);
        if (rock.lockedBy == null) {
          rock.lerpTargetPos = null;
          rock.lerpTargetAngle = null;
        }
      } else {
        rock.body.setTransform(next, nextAngle);
      }
      // setTransform always wakes the body; restore sleep state to avoid
      // continuous jitter on already-settled rocks driven by periodic syncs.
      if (!wasAwake) rock.body.setAwake(false);
    }
  }

  // ── Local drag ────────────────────────────────────────────────────────

  /// Called when local player starts dragging a rock.
  void grabRock(int id) {
    final rock = _rocks[id];
    if (rock == null) return;
    rock.isGrabbedLocally = true;
    rock.dragTarget = rock.body.position.clone();
    rock.lerpTargetPos = null;
    rock.lerpTargetAngle = null;
    rock.body.setType(BodyType.kinematic);
    rock.body.linearVelocity = Vector2.zero();
    rock.body.angularVelocity = 0;
  }

  /// Update the drag target (called each pan update).
  /// Velocity is derived from this in _applyLerps before every physics step,
  /// so multi-step frames stay stable and stationary holds don't drift.
  void moveRock(int id, Offset screenPos) {
    final rock = _rocks[id];
    if (rock == null) return;
    rock.dragTarget = screenToWorld(screenPos.dx, screenPos.dy, _ch, _ppm);
  }

  /// Called when local player releases a rock.
  /// [releaseVelPixels]: release velocity in screen pixels/s.
  /// [screenOmega]: angular velocity in screen convention (CW positive).
  void releaseRock(int id, Offset releaseVelPixels, double screenOmega) {
    final rock = _rocks[id];
    if (rock == null) return;
    rock.isGrabbedLocally = false;
    rock.dragTarget = null;
    rock.body.setType(BodyType.dynamic);
    rock.body.setAwake(true); // setType alone does not wake the body
    // Flip Y for velocity (screen Y-down → world Y-up)
    rock.body.linearVelocity = Vector2(
      releaseVelPixels.dx / _ppm,
      -releaseVelPixels.dy / _ppm,
    );
    // Flip sign for angular velocity (screen CW → world CCW)
    rock.body.angularVelocity = (-screenOmega).clamp(-6.0, 6.0);
  }

  // ── Peer sync ────────────────────────────────────────────────────────

  /// Mark a rock as grabbed by a peer (switches to kinematic, clears lerp).
  void grabByPeer(int id) {
    final rock = _rocks[id];
    if (rock == null) return;
    rock.lerpTargetPos = null;
    rock.lerpTargetAngle = null;
    rock.body.setType(BodyType.kinematic);
    rock.body.linearVelocity = Vector2.zero();
    rock.body.angularVelocity = 0;
  }

  /// Set the player that currently holds this rock (null = nobody).
  void setRockLockedBy(int id, String? peerId) {
    final rock = _rocks[id];
    if (rock == null) return;
    rock.lockedBy = peerId;
  }

  /// Apply a gentle drift correction lerp for one settled rock.
  /// Only acts on sleeping dynamic bodies (not kinematic, not awake).
  /// This lets the host periodically nudge clients back into sync without
  /// fighting physics on rocks that are actively flying or being held.
  void applyDriftCorrection(int id, double normX, double normY, double worldAngle) {
    final rock = _rocks[id];
    if (rock == null) return;
    if (rock.isGrabbedLocally) return;             // local player holds it
    if (rock.body.bodyType == BodyType.kinematic) return; // peer holds it
    final targetPos = Vector2(
      normX * _cw / _ppm,
      (1.0 - normY) * _ch / _ppm,
    );
    // Skip correction if already within dead-zone — avoids waking sleeping bodies
    final posError = (rock.body.position - targetPos).length;
    final angleError = (rock.body.angle - worldAngle).abs();
    if (posError < 0.025 && angleError < 0.01) return;
    rock.lerpTargetPos = targetPos;
    rock.lerpTargetAngle = worldAngle;
  }

  /// Set a smooth lerp target from normalised canvas coords (0–1) and world angle.
  /// normX = screenX / canvasWidth, normY = screenY / canvasHeight (screen Y-down).
  void setLerpTarget(int id, double normX, double normY, double worldAngle) {
    final rock = _rocks[id];
    if (rock == null) return;
    rock.lerpTargetPos = Vector2(
      normX * _cw / _ppm,
      (1.0 - normY) * _ch / _ppm,
    );
    rock.lerpTargetAngle = worldAngle;
  }

  /// Teleport rock to normalised position and world angle (used for peer release and snapshot).
  /// Switches body to dynamic + sleeping so physics resumes correctly.
  void teleportRock(int id, double normX, double normY, double worldAngle) {
    final rock = _rocks[id];
    if (rock == null) return;
    final worldPos = Vector2(
      normX * _cw / _ppm,
      (1.0 - normY) * _ch / _ppm,
    );
    // Clear any stale lerp target so _applyLerps doesn't pull the rock back
    // to the old drag position after this teleport.
    rock.lerpTargetPos = null;
    rock.lerpTargetAngle = null;
    rock.body.setType(BodyType.dynamic);
    rock.body.setTransform(worldPos, worldAngle);
    rock.body.linearVelocity = Vector2.zero();
    rock.body.angularVelocity = 0;
    rock.body.setAwake(false);
  }

  /// Apply peer release velocity in world-space m/s (used after teleportRock for a peer throw).
  /// Does not touch isGrabbedLocally / dragTarget which are local-player-only fields.
  void releaseRockDirect(int id, double worldVx, double worldVy, double worldOmega) {
    final rock = _rocks[id];
    if (rock == null) return;
    rock.body.setType(BodyType.dynamic);
    rock.body.setAwake(true);
    rock.body.linearVelocity = Vector2(worldVx, worldVy);
    rock.body.angularVelocity = worldOmega.clamp(-6.0, 6.0);
  }

  // ── Read-only accessors ───────────────────────────────────────────────

  List<int> get rockIds => _rocks.keys.toList();

  Offset getRockScreenPos(int id) =>
      worldToScreen(_rocks[id]!.body.position, _ch, _ppm);

  double getRockScreenAngle(int id) =>
      worldAngleToScreen(_rocks[id]!.body.angle);

  /// Rock position as normalised canvas fractions (0–1), screen Y-down convention.
  Offset getRockNormPos(int id) {
    final s = getRockScreenPos(id);
    return Offset(s.dx / _cw, s.dy / _ch);
  }

  /// Rock angle in world space (CCW radians, Forge2D convention).
  double getRockWorldAngle(int id) => _rocks[id]!.body.angle;

  Color getRockColor(int id) => _rocks[id]!.color;

  String? getRockLockedBy(int id) => _rocks[id]?.lockedBy;

  bool isRockGrabbed(int id) => _rocks[id]?.isGrabbedLocally ?? false;
  bool isRockAwake(int id) => _rocks[id]?.body.isAwake ?? false;
  bool isRockKinematic(int id) => _rocks[id]?.body.bodyType == BodyType.kinematic;

  /// Returns the rock's vertices in absolute screen coordinates.
  List<Offset> getRockWorldVerts(int id) {
    final rock = _rocks[id]!;
    final pos = rock.body.position;
    final a = rock.body.angle;
    final cosA = math.cos(a), sinA = math.sin(a);
    return rock.localVertsMeters.map((v) {
      final wx = pos.x + v.x * cosA - v.y * sinA;
      final wy = pos.y + v.x * sinA + v.y * cosA;
      return worldToScreen(Vector2(wx, wy), _ch, _ppm);
    }).toList();
  }

  // ── Game logic helpers ────────────────────────────────────────────────

  /// True when all rocks are settled (sleeping or kinematic).
  bool get allSleeping =>
      _rocks.values.every((r) => r.body.bodyType == BodyType.kinematic || !r.body.isAwake);

  /// Height of the stack in pixels (distance from ground to highest settled rock vertex).
  double computeStackHeight() {
    double topScreenY = groundYPixels;
    for (final rock in _rocks.values) {
      // Only count sleeping (settled) rocks — exclude kinematic (held) rocks.
      if (rock.body.isAwake || rock.body.bodyType == BodyType.kinematic) continue;
      for (final v in getRockWorldVerts(rock.id)) {
        if (v.dy < topScreenY) topScreenY = v.dy;
      }
    }
    return groundYPixels - topScreenY;
  }

  /// Count rocks that are clearly above the ground (any vertex above groundY - margin).
  int countRocksAboveGround({double margin = 5}) {
    return _rocks.values.where((rock) {
      final verts = getRockWorldVerts(rock.id);
      if (verts.isEmpty) return false;
      final minY = verts.map((v) => v.dy).reduce(math.min);
      return minY < groundYPixels - margin;
    }).length;
  }

  /// Build render snapshots for the painter.
  List<RockRenderData> buildRenderData(int? draggedId) {
    return _rocks.values.map((rock) {
      return RockRenderData(
        id: rock.id,
        screenVerts: getRockWorldVerts(rock.id),
        screenPos: getRockScreenPos(rock.id),
        color: rock.color,
        isGrabbedByMe: rock.id == draggedId && rock.lockedBy == null,
        lockedBy: rock.lockedBy,
      );
    }).toList();
  }

  // ── Cleanup ───────────────────────────────────────────────────────────

  void dispose() {
    _rocks.clear();
  }
}
