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
    
    // Determine background color based on state
    Color backgroundColor;
    if (isDisabled) {
      backgroundColor = theme.secondary.withOpacity(0.5);
    } else if (isActive) {
      backgroundColor = theme.secondary;
    } else {
      backgroundColor = theme.primary;
    }

    return SizedBox(
      width: width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: theme.background,
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