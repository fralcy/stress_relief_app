import 'dart:math' as math;

// ── Obstacle types ────────────────────────────────────────────

enum ObstacleType { rock, lotus, seaweed }

// ── Data classes ──────────────────────────────────────────────

/// Obstacle definition relative to a chunk (relX/relY in 0..1).
class ObstacleDef {
  final ObstacleType type;
  final double relX; // 0..1 fraction of canvas width
  final double relY; // 0..1 fraction of chunk height

  const ObstacleDef(this.type, this.relX, this.relY);
}

/// A chunk of the map. Height is in canvas-height fractions.
class ChunkDef {
  final List<ObstacleDef> obstacles;
  final double heightFraction; // chunk height = heightFraction * canvasHeight

  const ChunkDef({required this.obstacles, this.heightFraction = 1.2});
}

// ── Preset chunk library ──────────────────────────────────────

class PaperShipChunkLibrary {
  PaperShipChunkLibrary._();

  static const List<ChunkDef> presets = [
    // 0: Open water — no obstacles (easy start)
    ChunkDef(obstacles: [], heightFraction: 0.8),

    // 1: Rock scatter — spread rocks, wide gaps
    ChunkDef(
      heightFraction: 1.2,
      obstacles: [
        ObstacleDef(ObstacleType.rock, 0.20, 0.25),
        ObstacleDef(ObstacleType.rock, 0.75, 0.45),
        ObstacleDef(ObstacleType.rock, 0.40, 0.70),
        ObstacleDef(ObstacleType.rock, 0.85, 0.15),
      ],
    ),

    // 2: Lotus pond — lotus in clusters
    ChunkDef(
      heightFraction: 1.3,
      obstacles: [
        ObstacleDef(ObstacleType.lotus, 0.15, 0.20),
        ObstacleDef(ObstacleType.lotus, 0.25, 0.35),
        ObstacleDef(ObstacleType.lotus, 0.70, 0.25),
        ObstacleDef(ObstacleType.lotus, 0.80, 0.40),
        ObstacleDef(ObstacleType.lotus, 0.50, 0.65),
        ObstacleDef(ObstacleType.lotus, 0.60, 0.80),
      ],
    ),

    // 3: Seaweed corridor — columns of seaweed, narrow path
    ChunkDef(
      heightFraction: 1.4,
      obstacles: [
        ObstacleDef(ObstacleType.seaweed, 0.12, 0.20),
        ObstacleDef(ObstacleType.seaweed, 0.18, 0.50),
        ObstacleDef(ObstacleType.seaweed, 0.14, 0.80),
        ObstacleDef(ObstacleType.seaweed, 0.82, 0.30),
        ObstacleDef(ObstacleType.seaweed, 0.88, 0.60),
        ObstacleDef(ObstacleType.seaweed, 0.84, 0.90),
      ],
    ),

    // 4: Rock maze — zigzag passage
    ChunkDef(
      heightFraction: 1.5,
      obstacles: [
        ObstacleDef(ObstacleType.rock, 0.10, 0.20),
        ObstacleDef(ObstacleType.rock, 0.20, 0.30),
        ObstacleDef(ObstacleType.rock, 0.65, 0.20),
        ObstacleDef(ObstacleType.rock, 0.75, 0.35),
        ObstacleDef(ObstacleType.rock, 0.85, 0.50),
        ObstacleDef(ObstacleType.rock, 0.20, 0.55),
        ObstacleDef(ObstacleType.rock, 0.30, 0.70),
        ObstacleDef(ObstacleType.rock, 0.70, 0.70),
        ObstacleDef(ObstacleType.rock, 0.60, 0.85),
      ],
    ),

    // 5: Mixed — rocks + lotus
    ChunkDef(
      heightFraction: 1.3,
      obstacles: [
        ObstacleDef(ObstacleType.rock, 0.15, 0.30),
        ObstacleDef(ObstacleType.rock, 0.80, 0.50),
        ObstacleDef(ObstacleType.lotus, 0.45, 0.20),
        ObstacleDef(ObstacleType.lotus, 0.55, 0.70),
        ObstacleDef(ObstacleType.seaweed, 0.25, 0.65),
        ObstacleDef(ObstacleType.seaweed, 0.75, 0.30),
      ],
    ),

    // 6: Dense rocks — tight slalom
    ChunkDef(
      heightFraction: 1.6,
      obstacles: [
        ObstacleDef(ObstacleType.rock, 0.20, 0.15),
        ObstacleDef(ObstacleType.rock, 0.60, 0.25),
        ObstacleDef(ObstacleType.rock, 0.30, 0.40),
        ObstacleDef(ObstacleType.rock, 0.70, 0.50),
        ObstacleDef(ObstacleType.rock, 0.15, 0.60),
        ObstacleDef(ObstacleType.rock, 0.55, 0.70),
        ObstacleDef(ObstacleType.rock, 0.85, 0.80),
        ObstacleDef(ObstacleType.rock, 0.35, 0.85),
      ],
    ),
  ];

  /// Procedural connector chunk — obstacles hugging left and right walls,
  /// guaranteed gap ≥ [minGapFraction] in the centre.
  static ChunkDef generateProcedural(int seed, int index) {
    final rng = math.Random(seed ^ (index * 2654435761));
    const minGapFraction = 0.35; // 35% of canvas width = centre passage

    final obstacles = <ObstacleDef>[];
    final leftCount = 2 + rng.nextInt(3);
    final rightCount = 2 + rng.nextInt(3);

    for (int i = 0; i < leftCount; i++) {
      final relX = 0.05 + rng.nextDouble() * (0.5 - minGapFraction / 2 - 0.05);
      final relY = (i + 1) / (leftCount + 1.0) + (rng.nextDouble() - 0.5) * 0.1;
      obstacles.add(ObstacleDef(
        ObstacleType.values[rng.nextInt(ObstacleType.values.length)],
        relX.clamp(0.05, 0.35),
        relY.clamp(0.1, 0.9),
      ));
    }

    for (int i = 0; i < rightCount; i++) {
      final relX = (0.5 + minGapFraction / 2) + rng.nextDouble() * (0.45 - minGapFraction / 2);
      final relY = (i + 1) / (rightCount + 1.0) + (rng.nextDouble() - 0.5) * 0.1;
      obstacles.add(ObstacleDef(
        ObstacleType.values[rng.nextInt(ObstacleType.values.length)],
        relX.clamp(0.65, 0.95),
        relY.clamp(0.1, 0.9),
      ));
    }

    return ChunkDef(
      obstacles: obstacles,
      heightFraction: 1.0 + rng.nextDouble() * 0.6,
    );
  }
}

// ── Obstacle (runtime instance) ───────────────────────────────

class ShipObstacle {
  final ObstacleType type;
  final double worldX;     // absolute position in world-space
  final double worldY;
  final double radius;     // circular hitbox radius in px
  final double visualSize; // for painter (may differ from hitbox)

  const ShipObstacle({
    required this.type,
    required this.worldX,
    required this.worldY,
    required this.radius,
    required this.visualSize,
  });
}

// ── Chunk manager ─────────────────────────────────────────────

/// Manages the sequence of chunks and translates def → runtime obstacles.
class ChunkManager {
  final double canvasWidth;
  final double canvasHeight;
  final int seed;

  // World-space Y grows upward (boat scrolls up ≡ world scrolls down).
  // _worldFrontY is the Y coordinate of the "top" of the farthest generated chunk.
  double _worldFrontY = 0.0;

  final List<ShipObstacle> _obstacles = [];

  // Track which chunk indices have been generated
  int _presetIndex = 0;    // cycles through presets
  int _chunkIndex = 0;     // total chunks generated (for procedural seed)
  static const int _proceduralEvery = 3; // 1 procedural per N preset chunks

  ChunkManager({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.seed,
  });

  List<ShipObstacle> get allObstacles => _obstacles;

  /// Returns obstacles whose worldY is within [yMin, yMax].
  List<ShipObstacle> obstaclesInRange(double yMin, double yMax) {
    return _obstacles
        .where((o) => o.worldY >= yMin && o.worldY <= yMax)
        .toList();
  }

  /// Ensure chunks are generated ahead of [frontY] by at least one viewport.
  void ensureAhead(double frontY) {
    while (_worldFrontY < frontY + canvasHeight) {
      _generateNext();
    }
  }

  /// Remove obstacles that are behind [behindY] (already scrolled past).
  void cullBehind(double behindY) {
    _obstacles.removeWhere((o) => o.worldY < behindY - canvasHeight * 0.5);
  }

  void _generateNext() {
    final bool isProcedural = (_chunkIndex % _proceduralEvery == _proceduralEvery - 1);
    final ChunkDef def;

    if (isProcedural) {
      def = PaperShipChunkLibrary.generateProcedural(seed, _chunkIndex);
    } else {
      def = PaperShipChunkLibrary.presets[_presetIndex % PaperShipChunkLibrary.presets.length];
      _presetIndex++;
    }

    final chunkHeight = def.heightFraction * canvasHeight;
    _instantiateChunk(def, _worldFrontY, chunkHeight);
    _worldFrontY += chunkHeight;
    _chunkIndex++;
  }

  void _instantiateChunk(ChunkDef def, double startY, double chunkHeight) {
    for (final obs in def.obstacles) {
      final radius = _radiusFor(obs.type);
      _obstacles.add(ShipObstacle(
        type: obs.type,
        worldX: obs.relX * canvasWidth,
        worldY: startY + obs.relY * chunkHeight,
        radius: radius,
        visualSize: radius * 1.2,
      ));
    }
  }

  double _radiusFor(ObstacleType type) {
    switch (type) {
      case ObstacleType.rock:   return canvasWidth * 0.055;
      case ObstacleType.lotus:  return canvasWidth * 0.045;
      case ObstacleType.seaweed: return canvasWidth * 0.030;
    }
  }
}
