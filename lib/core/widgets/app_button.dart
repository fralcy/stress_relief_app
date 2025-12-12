import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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
    
    // Determine colors based on state and theme type
    Color backgroundColor;
    Color foregroundColor;
    
    if (isDisabled) {
      if (theme.isDark) {
        // Disabled - Dark
        backgroundColor = theme.primary.withOpacity(0.5);
        foregroundColor = theme.background.withOpacity(0.6);
      } else {
        // Disabled - Light
        backgroundColor = theme.border;
        foregroundColor = theme.background;
      }
    } else if (isActive) {
      // Active (Dark/Light)
      backgroundColor = theme.secondary;
      foregroundColor = theme.background;
    } else {
      // Normal (Dark/Light)
      backgroundColor = theme.primary;
      foregroundColor = theme.background;
    }

    return SizedBox(
      width: width,
      height: height ?? 48,
      child: ElevatedButton(
        // Giữ onPressed là null khi disabled
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          // Sử dụng cả 2 thuộc tính để ghi đè màu disabled mặc định của Flutter
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor, 
          foregroundColor: foregroundColor,
          disabledForegroundColor: foregroundColor,
          
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 20 : 16,
            vertical: 12,
          ),
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
      return Text(
        label!,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // Icon + Label (horizontal)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          label!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}