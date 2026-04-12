import 'dart:math' as math;

// ── Obstacle types ────────────────────────────────────────────

enum ObstacleType { rock, lotus, seaweed, log, lilyPad, whirlpool }

enum Biome { marsh, lotusGarden, rapids }

// ── Data classes ──────────────────────────────────────────────

class ObstacleDef {
  final ObstacleType type;
  final double relX;       // 0..1 fraction of canvas width
  final double relY;       // 0..1 fraction of chunk height
  final double angle;      // radians — rotation for log (0 = horizontal)
  final double relHalfLen; // half-length as fraction of canvasWidth (log only)

  const ObstacleDef(this.type, this.relX, this.relY,
      [this.angle = 0.0, this.relHalfLen = 0.12]);
}

class ChunkDef {
  final Biome biome;
  final List<ObstacleDef> obstacles;
  final double heightFraction;

  const ChunkDef({
    required this.biome,
    required this.obstacles,
    this.heightFraction = 1.2,
  });
}

// ── Preset chunk library — 30 presets, 10 per biome ──────────

class PaperShipChunkLibrary {
  PaperShipChunkLibrary._();

  static const List<ChunkDef> presets = [
    // ══ MARSH BIOME (0–9): logs + seaweed, claustrophobic ════

    // 0: Gentle entry — two short logs near banks
    ChunkDef(biome: Biome.marsh, heightFraction: 1.1, obstacles: [
      ObstacleDef(ObstacleType.log, 0.22, 0.40, 0.0, 0.12),
      ObstacleDef(ObstacleType.log, 0.78, 0.65, 0.0, 0.12),
    ]),

    // 1: Wide center log + seaweed flanks
    ChunkDef(biome: Biome.marsh, heightFraction: 1.2, obstacles: [
      ObstacleDef(ObstacleType.log,     0.50, 0.38, 0.0, 0.20),
      ObstacleDef(ObstacleType.seaweed, 0.12, 0.65),
      ObstacleDef(ObstacleType.seaweed, 0.88, 0.65),
    ]),

    // 2: Diagonal crossing logs (/)(\)
    ChunkDef(biome: Biome.marsh, heightFraction: 1.3, obstacles: [
      ObstacleDef(ObstacleType.log, 0.35, 0.28,  0.25 * math.pi, 0.16),
      ObstacleDef(ObstacleType.log, 0.65, 0.68, -0.25 * math.pi, 0.16),
    ]),

    // 3: Staggered parallel logs
    ChunkDef(biome: Biome.marsh, heightFraction: 1.3, obstacles: [
      ObstacleDef(ObstacleType.log,     0.30, 0.25, 0.0, 0.18),
      ObstacleDef(ObstacleType.log,     0.68, 0.55, 0.0, 0.18),
      ObstacleDef(ObstacleType.seaweed, 0.12, 0.48),
    ]),

    // 4: Seaweed walls + center log
    ChunkDef(biome: Biome.marsh, heightFraction: 1.4, obstacles: [
      ObstacleDef(ObstacleType.seaweed, 0.12, 0.20),
      ObstacleDef(ObstacleType.seaweed, 0.14, 0.55),
      ObstacleDef(ObstacleType.seaweed, 0.11, 0.82),
      ObstacleDef(ObstacleType.seaweed, 0.86, 0.30),
      ObstacleDef(ObstacleType.seaweed, 0.88, 0.65),
      ObstacleDef(ObstacleType.log,     0.50, 0.45, 0.0, 0.16),
    ]),

    // 5: Alternating three logs (slalom)
    ChunkDef(biome: Biome.marsh, heightFraction: 1.5, obstacles: [
      ObstacleDef(ObstacleType.log, 0.30, 0.20, 0.0, 0.16),
      ObstacleDef(ObstacleType.log, 0.68, 0.45, 0.0, 0.16),
      ObstacleDef(ObstacleType.log, 0.28, 0.72, 0.0, 0.16),
    ]),

    // 6: Long shallow diagonal + rock at end
    ChunkDef(biome: Biome.marsh, heightFraction: 1.4, obstacles: [
      ObstacleDef(ObstacleType.log,     0.50, 0.32, 0.15 * math.pi, 0.25),
      ObstacleDef(ObstacleType.seaweed, 0.14, 0.72),
      ObstacleDef(ObstacleType.seaweed, 0.86, 0.20),
      ObstacleDef(ObstacleType.rock,    0.50, 0.82),
    ]),

    // 7: X-pattern logs
    ChunkDef(biome: Biome.marsh, heightFraction: 1.5, obstacles: [
      ObstacleDef(ObstacleType.log,     0.42, 0.38,  0.25 * math.pi, 0.18),
      ObstacleDef(ObstacleType.log,     0.58, 0.38, -0.25 * math.pi, 0.18),
      ObstacleDef(ObstacleType.seaweed, 0.14, 0.22),
      ObstacleDef(ObstacleType.seaweed, 0.86, 0.22),
    ]),

    // 8: Dense seaweed walls + twin logs
    ChunkDef(biome: Biome.marsh, heightFraction: 1.5, obstacles: [
      ObstacleDef(ObstacleType.seaweed, 0.12, 0.20),
      ObstacleDef(ObstacleType.seaweed, 0.15, 0.48),
      ObstacleDef(ObstacleType.seaweed, 0.12, 0.76),
      ObstacleDef(ObstacleType.seaweed, 0.85, 0.22),
      ObstacleDef(ObstacleType.seaweed, 0.88, 0.55),
      ObstacleDef(ObstacleType.seaweed, 0.85, 0.80),
      ObstacleDef(ObstacleType.log,     0.50, 0.35, 0.0,            0.14),
      ObstacleDef(ObstacleType.log,     0.50, 0.65, 0.1 * math.pi, 0.14),
    ]),

    // 9: Full marsh — four logs + seaweed + rock
    ChunkDef(biome: Biome.marsh, heightFraction: 1.6, obstacles: [
      ObstacleDef(ObstacleType.log,     0.26, 0.18,  0.0,            0.15),
      ObstacleDef(ObstacleType.log,     0.70, 0.38,  0.20 * math.pi, 0.15),
      ObstacleDef(ObstacleType.log,     0.28, 0.58, -0.15 * math.pi, 0.15),
      ObstacleDef(ObstacleType.log,     0.66, 0.76,  0.0,            0.15),
      ObstacleDef(ObstacleType.seaweed, 0.12, 0.50),
      ObstacleDef(ObstacleType.seaweed, 0.86, 0.25),
      ObstacleDef(ObstacleType.rock,    0.48, 0.90),
    ]),

    // ══ LOTUS GARDEN BIOME (10–19): lilyPad dense + lotus ════

    // 10: Gentle entry — scattered lily pads
    ChunkDef(biome: Biome.lotusGarden, heightFraction: 1.0, obstacles: [
      ObstacleDef(ObstacleType.lilyPad, 0.20, 0.30),
      ObstacleDef(ObstacleType.lilyPad, 0.38, 0.52),
      ObstacleDef(ObstacleType.lilyPad, 0.72, 0.35),
      ObstacleDef(ObstacleType.lilyPad, 0.60, 0.68),
    ]),

    // 11: First lotus + lily pads
    ChunkDef(biome: Biome.lotusGarden, heightFraction: 1.2, obstacles: [
      ObstacleDef(ObstacleType.lotus,   0.25, 0.35),
      ObstacleDef(ObstacleType.lotus,   0.72, 0.55),
      ObstacleDef(ObstacleType.lilyPad, 0.15, 0.60),
      ObstacleDef(ObstacleType.lilyPad, 0.45, 0.72),
      ObstacleDef(ObstacleType.lilyPad, 0.82, 0.25),
    ]),

    // 12: Dense lily pad field
    ChunkDef(biome: Biome.lotusGarden, heightFraction: 1.3, obstacles: [
      ObstacleDef(ObstacleType.lilyPad, 0.15, 0.18),
      ObstacleDef(ObstacleType.lilyPad, 0.32, 0.28),
      ObstacleDef(ObstacleType.lilyPad, 0.55, 0.22),
      ObstacleDef(ObstacleType.lilyPad, 0.72, 0.15),
      ObstacleDef(ObstacleType.lilyPad, 0.20, 0.52),
      ObstacleDef(ObstacleType.lilyPad, 0.48, 0.58),
      ObstacleDef(ObstacleType.lilyPad, 0.75, 0.50),
      ObstacleDef(ObstacleType.lilyPad, 0.28, 0.78),
      ObstacleDef(ObstacleType.lilyPad, 0.62, 0.75),
    ]),

    // 13: Two lily clusters left & right, gap in middle
    ChunkDef(biome: Biome.lotusGarden, heightFraction: 1.3, obstacles: [
      ObstacleDef(ObstacleType.lilyPad, 0.12, 0.22),
      ObstacleDef(ObstacleType.lilyPad, 0.24, 0.35),
      ObstacleDef(ObstacleType.lilyPad, 0.15, 0.52),
      ObstacleDef(ObstacleType.lilyPad, 0.26, 0.68),
      ObstacleDef(ObstacleType.lilyPad, 0.72, 0.18),
      ObstacleDef(ObstacleType.lilyPad, 0.84, 0.32),
      ObstacleDef(ObstacleType.lilyPad, 0.75, 0.55),
      ObstacleDef(ObstacleType.lilyPad, 0.86, 0.70),
    ]),

    // 14: Lotus maze
    ChunkDef(biome: Biome.lotusGarden, heightFraction: 1.4, obstacles: [
      ObstacleDef(ObstacleType.lotus,   0.22, 0.20),
      ObstacleDef(ObstacleType.lotus,   0.58, 0.30),
      ObstacleDef(ObstacleType.lotus,   0.25, 0.58),
      ObstacleDef(ObstacleType.lotus,   0.72, 0.65),
      ObstacleDef(ObstacleType.lilyPad, 0.40, 0.44),
      ObstacleDef(ObstacleType.lilyPad, 0.42, 0.78),
      ObstacleDef(ObstacleType.lilyPad, 0.82, 0.45),
    ]),

    // 15: Lotus centerpiece + lily border
    ChunkDef(biome: Biome.lotusGarden, heightFraction: 1.3, obstacles: [
      ObstacleDef(ObstacleType.lotus,   0.50, 0.38),
      ObstacleDef(ObstacleType.lilyPad, 0.22, 0.22),
      ObstacleDef(ObstacleType.lilyPad, 0.78, 0.22),
      ObstacleDef(ObstacleType.lilyPad, 0.18, 0.58),
      ObstacleDef(ObstacleType.lilyPad, 0.80, 0.58),
      ObstacleDef(ObstacleType.lilyPad, 0.35, 0.72),
      ObstacleDef(ObstacleType.lilyPad, 0.65, 0.72),
    ]),

    // 16: Very dense lily pads (15 pads)
    ChunkDef(biome: Biome.lotusGarden, heightFraction: 1.5, obstacles: [
      ObstacleDef(ObstacleType.lilyPad, 0.13, 0.14),
      ObstacleDef(ObstacleType.lilyPad, 0.28, 0.20),
      ObstacleDef(ObstacleType.lilyPad, 0.55, 0.15),
      ObstacleDef(ObstacleType.lilyPad, 0.78, 0.20),
      ObstacleDef(ObstacleType.lilyPad, 0.18, 0.36),
      ObstacleDef(ObstacleType.lilyPad, 0.42, 0.34),
      ObstacleDef(ObstacleType.lilyPad, 0.66, 0.40),
      ObstacleDef(ObstacleType.lilyPad, 0.85, 0.36),
      ObstacleDef(ObstacleType.lilyPad, 0.12, 0.58),
      ObstacleDef(ObstacleType.lilyPad, 0.35, 0.60),
      ObstacleDef(ObstacleType.lilyPad, 0.60, 0.62),
      ObstacleDef(ObstacleType.lilyPad, 0.83, 0.58),
      ObstacleDef(ObstacleType.lilyPad, 0.22, 0.80),
      ObstacleDef(ObstacleType.lilyPad, 0.48, 0.82),
      ObstacleDef(ObstacleType.lilyPad, 0.72, 0.80),
    ]),

    // 17: Lily pads + seaweed border + two lotus
    ChunkDef(biome: Biome.lotusGarden, heightFraction: 1.4, obstacles: [
      ObstacleDef(ObstacleType.seaweed, 0.10, 0.25),
      ObstacleDef(ObstacleType.seaweed, 0.12, 0.62),
      ObstacleDef(ObstacleType.seaweed, 0.88, 0.35),
      ObstacleDef(ObstacleType.seaweed, 0.86, 0.72),
      ObstacleDef(ObstacleType.lilyPad, 0.30, 0.28),
      ObstacleDef(ObstacleType.lilyPad, 0.52, 0.42),
      ObstacleDef(ObstacleType.lilyPad, 0.68, 0.28),
      ObstacleDef(ObstacleType.lotus,   0.40, 0.65),
      ObstacleDef(ObstacleType.lotus,   0.68, 0.70),
    ]),

    // 18: Mixed lotus garden
    ChunkDef(biome: Biome.lotusGarden, heightFraction: 1.5, obstacles: [
      ObstacleDef(ObstacleType.lotus,   0.20, 0.18),
      ObstacleDef(ObstacleType.lotus,   0.75, 0.28),
      ObstacleDef(ObstacleType.lilyPad, 0.12, 0.42),
      ObstacleDef(ObstacleType.lilyPad, 0.32, 0.52),
      ObstacleDef(ObstacleType.lilyPad, 0.52, 0.55),
      ObstacleDef(ObstacleType.lilyPad, 0.68, 0.50),
      ObstacleDef(ObstacleType.lilyPad, 0.86, 0.44),
      ObstacleDef(ObstacleType.lotus,   0.42, 0.75),
      ObstacleDef(ObstacleType.lilyPad, 0.65, 0.80),
    ]),

    // 19: Full lotus challenge
    ChunkDef(biome: Biome.lotusGarden, heightFraction: 1.6, obstacles: [
      ObstacleDef(ObstacleType.lotus,   0.25, 0.18),
      ObstacleDef(ObstacleType.lotus,   0.68, 0.25),
      ObstacleDef(ObstacleType.lilyPad, 0.14, 0.36),
      ObstacleDef(ObstacleType.lilyPad, 0.38, 0.33),
      ObstacleDef(ObstacleType.lilyPad, 0.58, 0.40),
      ObstacleDef(ObstacleType.lilyPad, 0.84, 0.36),
      ObstacleDef(ObstacleType.lotus,   0.47, 0.58),
      ObstacleDef(ObstacleType.lilyPad, 0.20, 0.65),
      ObstacleDef(ObstacleType.lilyPad, 0.35, 0.72),
      ObstacleDef(ObstacleType.lilyPad, 0.62, 0.68),
      ObstacleDef(ObstacleType.lilyPad, 0.82, 0.72),
      ObstacleDef(ObstacleType.lotus,   0.25, 0.88),
      ObstacleDef(ObstacleType.lotus,   0.72, 0.85),
    ]),

    // ══ RAPIDS BIOME (20–29): rocks + whirlpools ═════════════

    // 20: Entry rapids — scattered rocks
    ChunkDef(biome: Biome.rapids, heightFraction: 1.1, obstacles: [
      ObstacleDef(ObstacleType.rock, 0.22, 0.30),
      ObstacleDef(ObstacleType.rock, 0.68, 0.48),
      ObstacleDef(ObstacleType.rock, 0.40, 0.72),
    ]),

    // 21: First whirlpool — single central vortex
    ChunkDef(biome: Biome.rapids, heightFraction: 1.2, obstacles: [
      ObstacleDef(ObstacleType.whirlpool, 0.50, 0.40),
      ObstacleDef(ObstacleType.rock,      0.18, 0.25),
      ObstacleDef(ObstacleType.rock,      0.82, 0.62),
    ]),

    // 22: Rock slalom
    ChunkDef(biome: Biome.rapids, heightFraction: 1.3, obstacles: [
      ObstacleDef(ObstacleType.rock, 0.25, 0.18),
      ObstacleDef(ObstacleType.rock, 0.65, 0.30),
      ObstacleDef(ObstacleType.rock, 0.20, 0.52),
      ObstacleDef(ObstacleType.rock, 0.72, 0.62),
      ObstacleDef(ObstacleType.rock, 0.38, 0.80),
    ]),

    // 23: Dual whirlpools flanking center rocks
    ChunkDef(biome: Biome.rapids, heightFraction: 1.3, obstacles: [
      ObstacleDef(ObstacleType.whirlpool, 0.22, 0.38),
      ObstacleDef(ObstacleType.whirlpool, 0.78, 0.62),
      ObstacleDef(ObstacleType.rock,      0.50, 0.20),
      ObstacleDef(ObstacleType.rock,      0.50, 0.78),
    ]),

    // 24: Dense rock field
    ChunkDef(biome: Biome.rapids, heightFraction: 1.4, obstacles: [
      ObstacleDef(ObstacleType.rock, 0.18, 0.16),
      ObstacleDef(ObstacleType.rock, 0.45, 0.20),
      ObstacleDef(ObstacleType.rock, 0.72, 0.18),
      ObstacleDef(ObstacleType.rock, 0.28, 0.45),
      ObstacleDef(ObstacleType.rock, 0.65, 0.50),
      ObstacleDef(ObstacleType.rock, 0.18, 0.72),
      ObstacleDef(ObstacleType.rock, 0.55, 0.75),
      ObstacleDef(ObstacleType.rock, 0.82, 0.70),
    ]),

    // 25: Whirlpool pair + four rocks
    ChunkDef(biome: Biome.rapids, heightFraction: 1.4, obstacles: [
      ObstacleDef(ObstacleType.whirlpool, 0.24, 0.42),
      ObstacleDef(ObstacleType.whirlpool, 0.76, 0.55),
      ObstacleDef(ObstacleType.rock,      0.48, 0.25),
      ObstacleDef(ObstacleType.rock,      0.52, 0.55),
      ObstacleDef(ObstacleType.rock,      0.38, 0.78),
      ObstacleDef(ObstacleType.rock,      0.65, 0.82),
    ]),

    // 26: Rock maze + trailing whirlpool
    ChunkDef(biome: Biome.rapids, heightFraction: 1.5, obstacles: [
      ObstacleDef(ObstacleType.rock,      0.18, 0.14),
      ObstacleDef(ObstacleType.rock,      0.50, 0.18),
      ObstacleDef(ObstacleType.rock,      0.78, 0.24),
      ObstacleDef(ObstacleType.rock,      0.28, 0.40),
      ObstacleDef(ObstacleType.rock,      0.68, 0.45),
      ObstacleDef(ObstacleType.rock,      0.15, 0.62),
      ObstacleDef(ObstacleType.rock,      0.50, 0.65),
      ObstacleDef(ObstacleType.rock,      0.82, 0.70),
      ObstacleDef(ObstacleType.whirlpool, 0.38, 0.85),
    ]),

    // 27: Three whirlpools in triangle
    ChunkDef(biome: Biome.rapids, heightFraction: 1.4, obstacles: [
      ObstacleDef(ObstacleType.whirlpool, 0.25, 0.28),
      ObstacleDef(ObstacleType.whirlpool, 0.72, 0.50),
      ObstacleDef(ObstacleType.whirlpool, 0.35, 0.75),
      ObstacleDef(ObstacleType.rock,      0.55, 0.28),
      ObstacleDef(ObstacleType.rock,      0.18, 0.60),
      ObstacleDef(ObstacleType.rock,      0.82, 0.82),
    ]),

    // 28: Mixed rapids challenge
    ChunkDef(biome: Biome.rapids, heightFraction: 1.5, obstacles: [
      ObstacleDef(ObstacleType.rock,      0.20, 0.14),
      ObstacleDef(ObstacleType.rock,      0.76, 0.20),
      ObstacleDef(ObstacleType.whirlpool, 0.46, 0.30),
      ObstacleDef(ObstacleType.rock,      0.22, 0.48),
      ObstacleDef(ObstacleType.rock,      0.70, 0.52),
      ObstacleDef(ObstacleType.whirlpool, 0.50, 0.70),
      ObstacleDef(ObstacleType.rock,      0.30, 0.82),
      ObstacleDef(ObstacleType.rock,      0.72, 0.86),
    ]),

    // 29: Final rapids — maximum challenge
    ChunkDef(biome: Biome.rapids, heightFraction: 1.6, obstacles: [
      ObstacleDef(ObstacleType.rock,      0.15, 0.10),
      ObstacleDef(ObstacleType.rock,      0.45, 0.16),
      ObstacleDef(ObstacleType.rock,      0.78, 0.14),
      ObstacleDef(ObstacleType.whirlpool, 0.28, 0.30),
      ObstacleDef(ObstacleType.rock,      0.62, 0.36),
      ObstacleDef(ObstacleType.rock,      0.18, 0.52),
      ObstacleDef(ObstacleType.whirlpool, 0.66, 0.58),
      ObstacleDef(ObstacleType.rock,      0.38, 0.68),
      ObstacleDef(ObstacleType.rock,      0.80, 0.72),
      ObstacleDef(ObstacleType.whirlpool, 0.25, 0.86),
    ]),
  ];

  // Biome-weighted obstacle type tables for procedural chunks
  static const List<ObstacleType> _marshTypes = [
    ObstacleType.log, ObstacleType.log, ObstacleType.log,
    ObstacleType.seaweed, ObstacleType.seaweed,
    ObstacleType.rock,
  ];
  static const List<ObstacleType> _lotusTypes = [
    ObstacleType.lilyPad, ObstacleType.lilyPad, ObstacleType.lilyPad,
    ObstacleType.lotus, ObstacleType.lotus,
    ObstacleType.seaweed,
  ];
  static const List<ObstacleType> _rapidsTypes = [
    ObstacleType.rock, ObstacleType.rock, ObstacleType.rock,
    ObstacleType.whirlpool, ObstacleType.whirlpool,
    ObstacleType.rock,
  ];

  static ChunkDef generateProcedural(int seed, int chunkIndex, Biome biome) {
    final rng = math.Random(seed ^ (chunkIndex * 2654435761));
    const minGapFraction = 0.35;

    final typeTable = switch (biome) {
      Biome.marsh       => _marshTypes,
      Biome.lotusGarden => _lotusTypes,
      Biome.rapids      => _rapidsTypes,
    };

    final obstacles = <ObstacleDef>[];
    final leftCount  = 2 + rng.nextInt(3);
    final rightCount = 2 + rng.nextInt(3);

    for (int i = 0; i < leftCount; i++) {
      final type = typeTable[rng.nextInt(typeTable.length)];
      final relX = (0.05 + rng.nextDouble() * (0.5 - minGapFraction / 2 - 0.05))
          .clamp(0.05, 0.38);
      final relY = ((i + 1) / (leftCount + 1.0) + (rng.nextDouble() - 0.5) * 0.12)
          .clamp(0.08, 0.92);
      final angle    = type == ObstacleType.log ? (rng.nextDouble() - 0.5) * math.pi * 0.4 : 0.0;
      final halfLen  = type == ObstacleType.log ? 0.10 + rng.nextDouble() * 0.10 : 0.12;
      obstacles.add(ObstacleDef(type, relX, relY, angle, halfLen));
    }

    for (int i = 0; i < rightCount; i++) {
      final type = typeTable[rng.nextInt(typeTable.length)];
      final relX = ((0.5 + minGapFraction / 2) + rng.nextDouble() * (0.45 - minGapFraction / 2))
          .clamp(0.62, 0.95);
      final relY = ((i + 1) / (rightCount + 1.0) + (rng.nextDouble() - 0.5) * 0.12)
          .clamp(0.08, 0.92);
      final angle   = type == ObstacleType.log ? (rng.nextDouble() - 0.5) * math.pi * 0.4 : 0.0;
      final halfLen = type == ObstacleType.log ? 0.10 + rng.nextDouble() * 0.10 : 0.12;
      obstacles.add(ObstacleDef(type, relX, relY, angle, halfLen));
    }

    return ChunkDef(
      biome: biome,
      obstacles: obstacles,
      heightFraction: 1.0 + rng.nextDouble() * 0.6,
    );
  }
}

// ── Obstacle (runtime instance) ───────────────────────────────

class ShipObstacle {
  final ObstacleType type;
  final double worldX;
  final double worldY;
  final double radius;     // circle radius; capsule end-cap radius for log
  final double visualSize; // for painter
  final double angle;      // rotation radians (log direction)
  final double halfLength; // px — capsule half-length for log, 0 for others

  const ShipObstacle({
    required this.type,
    required this.worldX,
    required this.worldY,
    required this.radius,
    required this.visualSize,
    this.angle = 0.0,
    this.halfLength = 0.0,
  });
}

// ── Chunk manager ─────────────────────────────────────────────

class ChunkManager {
  final double canvasWidth;
  final double canvasHeight;
  final int seed;

  double _worldFrontY = 0.0;
  final List<ShipObstacle> _obstacles = [];

  // ── Shuffle-bag state ─────────────────────────────────────────
  // Seeded RNG ensures host and client produce identical sequences.
  late final math.Random _rng;

  // Per-biome bags of remaining preset indices (0–9). Refilled and
  // re-shuffled whenever a bag empties.
  final Map<Biome, List<int>> _bags = {};

  Biome _currentBiome = Biome.marsh;

  // Alternates: true = emit preset, false = emit procedural then switch biome.
  bool _isPresetTurn = true;

  // Monotonic counter used only to seed procedural generation.
  int _proceduralCount = 0;

  static const int _presetsPerBiome = 10;

  Biome get currentBiome => _currentBiome;

  ChunkManager({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.seed,
  }) {
    _rng = math.Random(seed);
    // Random starting biome (deterministic via seed).
    _currentBiome = Biome.values[_rng.nextInt(Biome.values.length)];
    // Pre-fill bags for all biomes.
    for (final biome in Biome.values) {
      _bags[biome] = _shuffledBag(biome);
    }
  }

  // Returns a freshly shuffled list of preset indices [0, _presetsPerBiome).
  List<int> _shuffledBag(Biome biome) {
    final bag = List.generate(_presetsPerBiome, (i) => i);
    for (int i = bag.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final tmp = bag[i]; bag[i] = bag[j]; bag[j] = tmp;
    }
    return bag;
  }

  // Draws the next preset index for [biome], refilling the bag if empty.
  int _drawPreset(Biome biome) {
    if (_bags[biome]!.isEmpty) _bags[biome] = _shuffledBag(biome);
    return _bags[biome]!.removeLast();
  }

  // Picks a random biome that is not the current one.
  Biome _pickNextBiome() {
    final others = Biome.values.where((b) => b != _currentBiome).toList();
    return others[_rng.nextInt(others.length)];
  }

  List<ShipObstacle> get allObstacles => _obstacles;

  List<ShipObstacle> obstaclesInRange(double yMin, double yMax) =>
      _obstacles.where((o) => o.worldY >= yMin && o.worldY <= yMax).toList();

  void ensureAhead(double frontY) {
    while (_worldFrontY < frontY + canvasHeight) {
      _generateNext();
    }
  }

  void cullBehind(double behindY) {
    _obstacles.removeWhere((o) => o.worldY < behindY - canvasHeight * 0.5);
  }

  void _generateNext() {
    final ChunkDef def;

    if (_isPresetTurn) {
      // Preset from current biome's shuffle bag.
      final biomeOffset = _currentBiome.index * _presetsPerBiome;
      def = PaperShipChunkLibrary.presets[biomeOffset + _drawPreset(_currentBiome)];
    } else {
      // Procedural chunk closes out the current biome, then we switch.
      def = PaperShipChunkLibrary.generateProcedural(
          seed, _proceduralCount, _currentBiome);
      _proceduralCount++;
      _currentBiome = _pickNextBiome();
    }

    _isPresetTurn = !_isPresetTurn;

    final chunkHeight = def.heightFraction * canvasHeight;
    _instantiateChunk(def, _worldFrontY, chunkHeight);
    _worldFrontY += chunkHeight;
  }

  void _instantiateChunk(ChunkDef def, double startY, double chunkHeight) {
    for (final obs in def.obstacles) {
      final radius  = _radiusFor(obs.type);
      final halfLen = obs.type == ObstacleType.log
          ? obs.relHalfLen * canvasWidth
          : 0.0;
      final visual = obs.type == ObstacleType.whirlpool
          ? canvasWidth * 0.060 // draw radius smaller than influence radius
          : radius * 1.2;
      _obstacles.add(ShipObstacle(
        type:       obs.type,
        worldX:     obs.relX * canvasWidth,
        worldY:     startY + obs.relY * chunkHeight,
        radius:     radius,
        visualSize: visual,
        angle:      obs.angle,
        halfLength: halfLen,
      ));
    }
  }

  double _radiusFor(ObstacleType type) => switch (type) {
    ObstacleType.rock       => canvasWidth * 0.055,
    ObstacleType.lotus      => canvasWidth * 0.045,
    ObstacleType.seaweed    => canvasWidth * 0.030,
    ObstacleType.log        => canvasWidth * 0.028, // end-cap radius
    ObstacleType.lilyPad    => canvasWidth * 0.030,
    ObstacleType.whirlpool  => canvasWidth * 0.115, // large influence zone
  };
}
