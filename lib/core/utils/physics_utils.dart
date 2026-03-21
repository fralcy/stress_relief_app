import 'dart:math' as math;
import 'dart:ui' show Offset;

// ============================================================
//  PhysicsUtils — pure math, không có Flutter widget dependency
//  Dùng chung cho:
//    - Rock Balancing: polygon rigid body, SAT collision
// ============================================================

// ── Polygon ─────────────────────────────────────────────────

/// Diện tích đa giác lồi (Shoelace formula). Kết quả luôn dương.
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
  if (area.abs() < 1e-6) {
    return vertices.reduce((a, b) => a + b) / vertices.length.toDouble();
  }
  area /= 2;
  return Offset(cx / (6 * area), cy / (6 * area));
}

/// Moment of inertia I của đa giác quanh trọng tâm.
double momentOfInertia(List<Offset> vertices, double mass) {
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
  if (den == 0) return mass * 1000;
  return (mass / 6) * (num / den);
}

/// Sinh đa giác lồi từ các điểm ngẫu nhiên dùng Monotone Chain convex hull.
/// Đảm bảo 100% lồi — không có đỉnh lõm gây lỗi SAT.
List<Offset> randomConvexPolygon({
  required int seed,
  required int index,
  double radius = 40,
}) {
  final rng = math.Random(seed ^ (index * 0x9e3779b9));
  final count = 8 + rng.nextInt(4); // 8–11 điểm nguồn
  final points = List.generate(count, (_) {
    final angle = rng.nextDouble() * 2 * math.pi;
    final r = radius * (0.5 + rng.nextDouble() * 0.5);
    return Offset(math.cos(angle) * r, math.sin(angle) * r);
  });
  return _makeConvexHull(points);
}

/// Monotone Chain — trả về convex hull theo thứ tự ngược chiều kim đồng hồ.
List<Offset> _makeConvexHull(List<Offset> points) {
  if (points.length <= 3) return points;
  final pts = [...points]
    ..sort((a, b) => a.dx == b.dx ? a.dy.compareTo(b.dy) : a.dx.compareTo(b.dx));

  final upper = <Offset>[];
  for (final p in pts) {
    while (upper.length >= 2 &&
        _cross(upper[upper.length - 2], upper.last, p) <= 0) {
      upper.removeLast();
    }
    upper.add(p);
  }

  final lower = <Offset>[];
  for (final p in pts.reversed) {
    while (lower.length >= 2 &&
        _cross(lower[lower.length - 2], lower.last, p) <= 0) {
      lower.removeLast();
    }
    lower.add(p);
  }

  upper.removeLast();
  lower.removeLast();
  return upper + lower;
}

double _cross(Offset o, Offset a, Offset b) =>
    (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

// ── Helpers ──────────────────────────────────────────────────

/// Nội suy tuyến tính
double lerpDouble(double a, double b, double t) => a + (b - a) * t;

/// Clamp giá trị trong khoảng [lo, hi]
double clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

