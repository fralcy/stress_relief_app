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
  double area = 0;
  final n = vertices.length;
  for (int i = 0; i < n; i++) {
    final j = (i + 1) % n;
    area += vertices[i].dx * vertices[j].dy;
    area -= vertices[j].dx * vertices[i].dy;
  }
  return area.abs() / 2;
}

/// Trọng tâm (centroid) của đa giác lồi.
/// Là điểm đặt trọng lực và gốc để tính moment of inertia.
Offset polygonCentroid(List<Offset> vertices) {
  double cx = 0, cy = 0, area = 0;
  final n = vertices.length;
  for (int i = 0; i < n; i++) {
    final j = (i + 1) % n;
    final cross = vertices[i].dx * vertices[j].dy - vertices[j].dx * vertices[i].dy;
    cx += (vertices[i].dx + vertices[j].dx) * cross;
    cy += (vertices[i].dy + vertices[j].dy) * cross;
    area += cross;
  }
  area /= 2;
  return Offset(cx / (6 * area), cy / (6 * area));
}

/// Moment of inertia I của đa giác quanh trọng tâm.
/// Xấp xỉ đủ dùng cho rigid body rotation: α = torque / I
double momentOfInertia(List<Offset> vertices, double mass) {
  // Tính quanh origin, sau đó dùng parallel axis theorem để dịch về centroid
  double num = 0, den = 0;
  final n = vertices.length;
  for (int i = 0; i < n; i++) {
    final j = (i + 1) % n;
    final vi = vertices[i];
    final vj = vertices[j];
    final cross = (vj.dx * vi.dy - vi.dx * vj.dy).abs();
    num += cross * (vi.dx * vi.dx + vi.dx * vj.dx + vj.dx * vj.dx +
                    vi.dy * vi.dy + vi.dy * vj.dy + vj.dy * vj.dy);
    den += cross;
  }
  if (den == 0) return mass;
  return (mass / 6) * (num / den);
}

/// Sinh đa giác lồi ngẫu nhiên có 5–8 đỉnh từ seed.
/// [seed]   — từ gameStart payload, đảm bảo host & client sinh cùng hình
/// [index]  — thứ tự viên đá (0-based), mỗi viên khác nhau
/// [radius] — bán kính xấp xỉ tính bằng pixel
///
/// Thuật toán: random góc đều, random r ∈ [0.55, 1.0] * radius, sort theo góc → convex
List<Offset> randomConvexPolygon({
  required int seed,
  required int index,
  double radius = 40,
}) {
  final rng = Random(seed ^ (index * 0x9e3779b9));
  final vertexCount = 5 + rng.nextInt(4); // 5–8

  // Sinh các góc ngẫu nhiên rồi sort để đảm bảo convex
  final angles = List.generate(vertexCount, (_) => rng.nextDouble() * 2 * pi)
    ..sort();

  return angles.map((angle) {
    final r = radius * (0.55 + rng.nextDouble() * 0.45);
    return Offset(cos(angle) * r, sin(angle) * r);
  }).toList();
}

// ── SAT Collision ────────────────────────────────────────────

/// Kiểm tra hai đa giác lồi có chồng lấn nhau không (Separating Axis Theorem).
bool satOverlap(List<Offset> a, List<Offset> b) => satContact(a, b) != null;

/// Trả về contact normal và penetration depth nếu hai polygon chồng lấn,
/// hoặc null nếu không chạm. Normal hướng từ b sang a.
///
/// Dùng để tính impulse response:
///   impulse = -(1 + restitution) * relativeVelocity · normal / (1/ma + 1/mb)
({Offset normal, double depth})? satContact(List<Offset> a, List<Offset> b) {
  double minDepth = double.infinity;
  Offset minNormal = Offset.zero;

  // Kiểm tra các trục của cả hai polygon
  for (final poly in [a, b]) {
    final n = poly.length;
    for (int i = 0; i < n; i++) {
      final edge = poly[(i + 1) % n] - poly[i];
      // Normal vuông góc với cạnh
      final axis = Offset(-edge.dy, edge.dx);
      final len = axis.distance;
      if (len < 1e-10) continue;
      final normal = axis / len;

      final projA = _project(a, normal);
      final projB = _project(b, normal);

      final overlap = _overlapAmount(projA, projB);
      if (overlap <= 0) return null; // Có trục phân tách → không chạm

      if (overlap < minDepth) {
        minDepth = overlap;
        minNormal = normal;
      }
    }
  }

  // Đảm bảo normal hướng từ b sang a
  final centerA = _centroidSimple(a);
  final centerB = _centroidSimple(b);
  final d = centerA - centerB;
  if (d.dx * minNormal.dx + d.dy * minNormal.dy < 0) {
    minNormal = Offset(-minNormal.dx, -minNormal.dy);
  }

  return (normal: minNormal, depth: minDepth);
}

// ── Wave Simulation (Paper Ship) ─────────────────────────────

/// Nguồn sóng tại một điểm. Mỗi lần người chơi chạm màn hình tạo một WaveSource.
@immutable
class WaveSource {
  final double x;         // vị trí nguồn sóng (pixel)
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
///   y(x,t) = Σ A_i * e^(-decay*(t-t0)) * sin(k*|x - xi| - ω*t + φ_i)
double waveY(double x, double t, List<WaveSource> sources) {
  double y = 0;
  for (final s in sources) {
    final elapsed = t - s.startTime;
    if (elapsed < 0) continue;
    final amp = s.amplitude * exp(-s.decayRate * elapsed);
    final k = 2 * pi * s.frequency / 300; // wave number (300px = wavelength ref)
    final omega = 2 * pi * s.frequency;
    y += amp * sin(k * (x - s.x).abs() - omega * t + s.phase);
  }
  return y;
}

// ── Helpers ──────────────────────────────────────────────────

/// Nội suy tuyến tính: lerp(a, b, t) = a + (b - a) * t
double lerpDouble(double a, double b, double t) => a + (b - a) * t;

/// Clamp giá trị trong khoảng [min, max]
double clamp(double v, double min, double max) =>
    v < min ? min : (v > max ? max : v);

// ── Private helpers ───────────────────────────────────────────

/// Project polygon lên axis, trả về (min, max)
(double, double) _project(List<Offset> poly, Offset axis) {
  double mn = double.infinity, mx = double.negativeInfinity;
  for (final v in poly) {
    final p = v.dx * axis.dx + v.dy * axis.dy;
    if (p < mn) mn = p;
    if (p > mx) mx = p;
  }
  return (mn, mx);
}

/// Lượng chồng lấn trên một trục. Âm = không chồng lấn.
double _overlapAmount((double, double) a, (double, double) b) {
  return min(a.$2, b.$2) - max(a.$1, b.$1);
}

/// Centroid đơn giản (trung bình cộng đỉnh) — chỉ dùng nội bộ SAT
Offset _centroidSimple(List<Offset> poly) {
  double sx = 0, sy = 0;
  for (final v in poly) {
    sx += v.dx;
    sy += v.dy;
  }
  return Offset(sx / poly.length, sy / poly.length);
}
