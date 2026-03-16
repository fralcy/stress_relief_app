// ignore: unused_import — sẽ dùng khi implement randomConvexPolygon và waveY
import 'dart:math';
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';

// ============================================================
//  PhysicsUtils — pure math, không có Flutter widget dependency
//  Dùng chung cho:
//    - Rock Balancing: polygon rigid body, SAT collision
//    - Paper Ship:     wave superposition
// ============================================================

// ── Polygon ─────────────────────────────────────────────────

/// Diện tích đa giác lồi (Shoelace formula). Kết quả luôn dương.
/// Dùng để tính khối lượng: mass = area * densityFactor
double polygonArea(List<Offset> vertices) {
  // TODO
  throw UnimplementedError();
}

/// Trọng tâm (centroid) của đa giác lồi.
/// Là điểm đặt trọng lực và gốc để tính moment of inertia.
Offset polygonCentroid(List<Offset> vertices) {
  // TODO
  throw UnimplementedError();
}

/// Moment of inertia I của đa giác quanh trọng tâm.
/// I = mass * Σ(vertex distances²) / 6  (xấp xỉ đủ dùng)
/// Dùng để tính angular acceleration: α = torque / I
double momentOfInertia(List<Offset> vertices, double mass) {
  // TODO
  throw UnimplementedError();
}

/// Sinh đa giác lồi ngẫu nhiên có 5–8 đỉnh từ seed.
/// [seed]  — từ gameStart payload, đảm bảo host & client sinh cùng hình
/// [index] — thứ tự viên đá (0-based), để mỗi viên khác nhau
/// [radius]— bán kính xấp xỉ tính bằng pixel
///
/// Thuật toán: random góc đều, random r ∈ [0.5, 1.0] * radius, sort theo góc → convex
List<Offset> randomConvexPolygon({
  required int seed,
  required int index,
  double radius = 40,
}) {
  // TODO
  throw UnimplementedError();
}

// ── SAT Collision ────────────────────────────────────────────

/// Kiểm tra hai đa giác lồi có chồng lấn nhau không (Separating Axis Theorem).
bool satOverlap(List<Offset> a, List<Offset> b) {
  // TODO
  throw UnimplementedError();
}

/// Trả về contact normal và penetration depth nếu hai polygon chồng lấn,
/// hoặc null nếu không chạm. Normal hướng từ b sang a.
///
/// Dùng để tính impulse response:
///   impulse = -(1 + restitution) * relativeVelocity · normal / (1/ma + 1/mb)
({Offset normal, double depth})? satContact(List<Offset> a, List<Offset> b) {
  // TODO
  throw UnimplementedError();
}

// ── Wave Simulation (Paper Ship) ─────────────────────────────

/// Nguồn sóng tại một điểm. Mỗi lần người chơi chạm màn hình tạo một WaveSource.
@immutable
class WaveSource {
  final double x;        // vị trí nguồn sóng (pixel)
  final double amplitude; // biên độ ban đầu
  final double frequency; // Hz
  final double phase;     // phase offset (radian)
  final double startTime; // thời điểm tạo (seconds từ game start)
  final double decayRate; // độ giảm biên độ theo thời gian

  const WaveSource({
    required this.x,
    required this.amplitude,
    required this.frequency,
    required this.phase,
    required this.startTime,
    this.decayRate = 0.5,
  });
}

/// Tính y displacement của mặt nước tại vị trí [x] vào thời điểm [t].
/// Giao thoa của nhiều nguồn sóng bằng cách cộng biên độ (superposition).
///
///   y(x,t) = Σ A_i * decay(t) * sin(k*|x - xi| - ω*t + φ_i)
double waveY(double x, double t, List<WaveSource> sources) {
  // TODO
  throw UnimplementedError();
}

// ── Helpers ──────────────────────────────────────────────────

/// Nội suy tuyến tính: lerp(a, b, t) = a + (b - a) * t
double lerpDouble(double a, double b, double t) => a + (b - a) * t;

/// Clamp giá trị trong khoảng [min, max]
double clamp(double v, double min, double max) =>
    v < min ? min : (v > max ? max : v);
