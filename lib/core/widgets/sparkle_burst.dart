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
    // TODO: Implement
    // Logic:
    //   - Sinh [particleCount] hướng bay đều nhau (360 / particleCount độ)
    //   - Mỗi hạt: hình tròn 4–6px
    //   - Animation t ∈ [0, 1]:
    //       pos = origin + direction * t * radius
    //       opacity = (1.0 - t).clamp(0, 1)
    //       scale  = 1.0 - t * 0.5
    //   - Vẽ bằng AnimatedBuilder + CustomPaint hoặc Positioned stack
    //   - Có thể thêm màu biến thiên nhẹ (color.withOpacity(opacity))
    throw UnimplementedError('SparkleBurst.build chưa được triển khai');
  }
}
