import 'package:flutter/material.dart';
import '../constants/app_typography.dart';

/// Widget hiển thị một nhãn nổi lên và mờ dần, dùng để phản hồi thao tác.
///
/// Dùng bên trong một Stack với Positioned — widget tự tính left/top từ [x]/[y].
///
/// Caller chịu trách nhiệm:
///   - Tạo AnimationController (thường 900ms, vsync: this)
///   - Gọi controller.forward()
///   - Sau khi hoàn thành, dispose controller và xoá widget khỏi danh sách
class FloatingLabelAnim extends StatelessWidget {
  /// Tâm X của nhãn trong Stack (pixel)
  final double x;

  /// Tâm Y khởi đầu của nhãn trong Stack (pixel)
  final double y;

  /// Nội dung text, ví dụ "+50 🪙" hoặc "+12 cm!"
  final String label;

  /// Controller do caller tạo và quản lý lifecycle
  final AnimationController controller;

  /// Màu nền của pill (mặc định amber)
  final Color backgroundColor;

  /// Màu chữ (mặc định trắng)
  final Color textColor;

  /// Khoảng cách nổi lên tính bằng pixel (mặc định 55)
  final double floatDistance;

  const FloatingLabelAnim({
    super.key,
    required this.x,
    required this.y,
    required this.label,
    required this.controller,
    this.backgroundColor = Colors.amber,
    this.textColor = Colors.white,
    this.floatDistance = 55,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final p = controller.value;
        return Positioned(
          left: x - 28,
          top: y - p * floatDistance - 16,
          child: Opacity(
            opacity: (1.0 - p * 1.1).clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: AppTypography.bodySmall(context, color: textColor)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}
