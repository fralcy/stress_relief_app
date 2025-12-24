import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_shapes.dart';
import '../constants/app_typography.dart';

/// Custom button với theme pastel
/// 
/// Variants:
/// - Icon only
/// - Icon + Text (horizontal)
/// 
/// States:
/// - Normal: primary background
/// - Active/Toggle: secondary background
/// - Disabled: secondary background with reduced opacity
class AppButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback? onPressed;
  final bool isActive;
  final bool isDisabled;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    this.icon,
    this.label,
    this.onPressed,
    this.isActive = false,
    this.isDisabled = false,
    this.width,
    this.height,
  }) : assert(icon != null || label != null, 'Must provide icon or label');

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    // M3 Semantic Color Usage
    Color backgroundColor;
    Color foregroundColor;

    if (isDisabled) {
      // M3 disabled state colors
      backgroundColor = context.onSurface.withValues(alpha: 0.12);
      foregroundColor = context.onSurface.withValues(alpha: 0.38);
    } else if (isActive) {
      // Active state uses secondary color
      backgroundColor = theme.secondary;
      foregroundColor = context.onSecondary;
    } else {
      // Normal state uses primary color
      backgroundColor = theme.primary;
      foregroundColor = context.onPrimary;
    }

    return SizedBox(
      width: width,
      height: height ?? 48,
      child: ElevatedButton(
        // Giữ onPressed là null khi disabled
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          // M3 colors with semantic meaning
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,

          // Ép màu khi disabled giống màu background (custom hoàn toàn)
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor,

          // M3 elevation (flat design)
          elevation: 0,
          shadowColor: Colors.transparent,

          // M3 shape (centralized)
          shape: context.shapes.medium,

          // WCAG AA + M3 minimum touch target
          minimumSize: Size(
            icon != null && label == null ? 48 : 64,
            48,
          ),

          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 20 : 16,
            vertical: 12,
          ),

          // Flutter tự động tính toán hiệu ứng nhấn dựa trên foregroundColor
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Icon only
    if (icon != null && label == null) {
      return Icon(icon, size: 24);
    }

    // Label only
    if (icon == null && label != null) {
      return Builder(
        builder: (context) => Text(
          label!,
          style: AppTypography.labelLarge(context, fontWeight: FontWeight.w600),
        ),
      );
    }

    // Icon + Label (horizontal)
    return Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label!,
            style: AppTypography.labelLarge(context, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}