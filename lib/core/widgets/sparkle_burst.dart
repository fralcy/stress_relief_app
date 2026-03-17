import 'dart:math';
import 'package:flutter/material.dart';

/// Hiệu ứng nổ hạt nhỏ tại một điểm trong Stack, dùng cho:
///   - Rock Balancing: chúc mừng khi vượt kỷ lục độ cao
///   - Achievement unlock (tuỳ chọn)
///
/// Cách dùng trong Stack:
///   SparkleBurst(
///     origin: Offset(cx, cy),
///     controller: _celebrationCtrl,
///     color: theme.primary,
///   )
///
/// Caller chịu trách nhiệm:
///   - Tạo AnimationController (thường 800–1000ms, vsync: this)
///   - Gọi controller.forward()
///   - Sau khi hoàn thành, dispose controller và xoá widget
class SparkleBurst extends StatelessWidget {
  /// Vị trí tâm nổ trong Stack (pixel)
  final Offset origin;

  /// Controller do caller tạo và quản lý
  final AnimationController controller;

  /// Số hạt (mặc định 12)
  final int particleCount;

  /// Màu hạt chính
  final Color color;

  /// Bán kính bay tối đa tính từ tâm (pixel, mặc định 40)
  final double radius;

  const SparkleBurst({
    super.key,
    required this.origin,
    required this.controller,
    this.particleCount = 12,
    this.color = Colors.amber,
    this.radius = 40,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final t = controller.value;
        return CustomPaint(
          painter: _SparklePainter(
            origin: origin,
            t: t,
            particleCount: particleCount,
            color: color,
            radius: radius,
          ),
          // Transparent child to occupy correct hit-test area
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Offset origin;
  final double t;
  final int particleCount;
  final Color color;
  final double radius;

  // Hướng bay cố định cho mỗi hạt — tính 1 lần theo particleCount
  late final List<Offset> _directions;

  _SparklePainter({
    required this.origin,
    required this.t,
    required this.particleCount,
    required this.color,
    required this.radius,
  }) {
    final angleStep = 2 * pi / particleCount;
    _directions = List.generate(particleCount, (i) {
      final angle = i * angleStep;
      return Offset(cos(angle), sin(angle));
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particleCount; i++) {
      final dist = t * radius;
      final pos = origin + _directions[i] * dist;
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final particleRadius = (3.0 + 2.0 * (1.0 - t)).clamp(1.0, 5.0);

      // Hạt chẵn: màu chính, hạt lẻ: màu nhạt hơn
      final c = (i % 2 == 0)
          ? color.withValues(alpha: opacity)
          : color.withValues(alpha: opacity * 0.6);

      canvas.drawCircle(pos, particleRadius, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}
