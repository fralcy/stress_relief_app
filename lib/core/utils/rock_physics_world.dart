import 'dart:math' as math;
import 'package:flutter/material.dart' show Color, Offset;
import 'package:forge2d/forge2d.dart';

// ── Coordinate conversion ─────────────────────────────────────────────────
// Forge2D: Y-up, meters (MKS). Screen: Y-down, pixels.
// kPixelsPerMeter is the scale factor between the two spaces.

const double kPixelsPerMeter = 50.0;

Vector2 screenToWorld(double px, double py, double canvasHeight) =>
    Vector2(px / kPixelsPerMeter, (canvasHeight - py) / kPixelsPerMeter);

Offset worldToScreen(Vector2 pos, double canvasHeight) =>
    Offset(pos.x * kPixelsPerMeter, canvasHeight - pos.y * kPixelsPerMeter);

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
  static const double _groundThickness = 20.0;

  final double _cw; // canvas width in pixels
  final double _ch; // canvas height in pixels

  late final World _world;
  final Map<int, _RockData> _rocks = {};
  final Set<Body> _staticBodies = {};

  // SFX callbacks — set by the modal after construction.
  void Function()? onRockHit;
  void Function()? onRockLand;

  double get groundYPixels => _ch - _groundThickness;

  RockPhysicsWorld({required double canvasWidth, required double canvasHeight})
      : _cw = canvasWidth,
        _ch = canvasHeight {
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
    final canvasWM = _cw / kPixelsPerMeter;
    final canvasHM = _ch / kPixelsPerMeter;
    // Ground is at _groundThickness pixels from the bottom in screen coords.
    // In Forge2D Y-up: groundY_world = groundThickness / kPPM
    final groundYM = _groundThickness / kPixelsPerMeter;

    final bodyDef = BodyDef()..type = BodyType.static;
    final staticBody = _world.createBody(bodyDef);

    // Ground edge with high friction so rocks don't slide
    staticBody.createFixture(
      FixtureDef(EdgeShape()..set(Vector2(0, groundYM), Vector2(canvasWM, groundYM)))
        ..friction = 1.0,
    );
    // Left wall
    staticBody.createFixture(
      FixtureDef(EdgeShape()..set(Vector2(0, 0), Vector2(0, canvasHM)))
        ..friction = 1.0,
    );
    // Right wall
    staticBody.createFixture(
      FixtureDef(EdgeShape()..set(Vector2(canvasWM, 0), Vector2(canvasWM, canvasHM)))
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
    final spawnPosWorld = screenToWorld(spawnPosPixels.dx, spawnPosPixels.dy, _ch);
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
        .map((o) => Vector2(o.dx / kPixelsPerMeter, o.dy / kPixelsPerMeter))
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
    }
  }

  // ── Local drag ────────────────────────────────────────────────────────

  /// Called when local player starts dragging a rock.
  void grabRock(int id) {
    final rock = _rocks[id];
    if (rock == null) return;
    rock.isGrabbedLocally = true;
    rock.lerpTargetPos = null;
    rock.lerpTargetAngle = null;
    rock.body.setType(BodyType.kinematic);
    rock.body.linearVelocity = Vector2.zero();
    rock.body.angularVelocity = 0;
  }

  /// Drive rock toward [screenPos] via kinematic velocity (called each pan update).
  void moveRock(int id, Offset screenPos) {
    final rock = _rocks[id];
    if (rock == null) return;
    final targetWorld = screenToWorld(screenPos.dx, screenPos.dy, _ch);
    // Velocity-driven: body reaches target in exactly one physics step.
    final vel = (targetWorld - rock.body.position) * (1 / _fixedDt);
    rock.body.linearVelocity = vel;
    rock.body.angularVelocity = 0;
  }

  /// Called when local player releases a rock.
  /// [releaseVelPixels]: release velocity in screen pixels/s.
  /// [screenOmega]: angular velocity in screen convention (CW positive).
  void releaseRock(int id, Offset releaseVelPixels, double screenOmega) {
    final rock = _rocks[id];
    if (rock == null) return;
    rock.isGrabbedLocally = false;
    rock.body.setType(BodyType.dynamic);
    rock.body.setAwake(true); // setType alone does not wake the body
    // Flip Y for velocity (screen Y-down → world Y-up)
    rock.body.linearVelocity = Vector2(
      releaseVelPixels.dx / kPixelsPerMeter,
      -releaseVelPixels.dy / kPixelsPerMeter,
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

  /// Set a smooth lerp target (used for dragUpdate and snapshot messages).
  void setLerpTarget(int id, Offset pixelPos, double screenAngle) {
    final rock = _rocks[id];
    if (rock == null) return;
    rock.lerpTargetPos = screenToWorld(pixelPos.dx, pixelPos.dy, _ch);
    rock.lerpTargetAngle = screenAngleToWorld(screenAngle);
  }

  /// Teleport rock to exact position (used for releaseRock peer message).
  void teleportRock(int id, Offset pixelPos, double screenAngle) {
    final rock = _rocks[id];
    if (rock == null) return;
    final worldPos = screenToWorld(pixelPos.dx, pixelPos.dy, _ch);
    final worldAngle = screenAngleToWorld(screenAngle);
    rock.body.setTransform(worldPos, worldAngle);
    rock.body.linearVelocity = Vector2.zero();
    rock.body.angularVelocity = 0;
    rock.body.setAwake(false);
  }

  // ── Read-only accessors ───────────────────────────────────────────────

  List<int> get rockIds => _rocks.keys.toList();

  Offset getRockScreenPos(int id) =>
      worldToScreen(_rocks[id]!.body.position, _ch);

  double getRockScreenAngle(int id) =>
      worldAngleToScreen(_rocks[id]!.body.angle);

  Color getRockColor(int id) => _rocks[id]!.color;

  String? getRockLockedBy(int id) => _rocks[id]?.lockedBy;

  bool isRockGrabbed(int id) => _rocks[id]?.isGrabbedLocally ?? false;

  /// Returns the rock's vertices in absolute screen coordinates.
  List<Offset> getRockWorldVerts(int id) {
    final rock = _rocks[id]!;
    final pos = rock.body.position;
    final a = rock.body.angle;
    final cosA = math.cos(a), sinA = math.sin(a);
    return rock.localVertsMeters.map((v) {
      final wx = pos.x + v.x * cosA - v.y * sinA;
      final wy = pos.y + v.x * sinA + v.y * cosA;
      return worldToScreen(Vector2(wx, wy), _ch);
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
