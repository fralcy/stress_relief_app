import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Custom slider cho volume control
/// 
/// Features:
/// - Track: border color
/// - Thumb: primary color
/// - Optional label display
class AppSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? label;
  final bool showValue;

  const AppSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.label,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (label != null || showValue)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: AppTypography.labelMedium(context, color: theme.text),
                  ),
                if (showValue)
                  Text(
                    '${value.round()}',
                    style: AppTypography.labelMedium(context, color: theme.primary),
                  ),
              ],
            ),
          ),
        
        // Slider with end caps
        Row(
          children: [       
            // Slider
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  // Track
                  activeTrackColor: theme.primary,
                  inactiveTrackColor: theme.border,
                  trackHeight: 8,
                  trackShape: const RoundedRectSliderTrackShape(),

                  // Thumb - WCAG AA compliant (48dp diameter)
                  thumbColor: theme.primary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 24, // Increased from 10 to 24 (48dp diameter)
                  ),

                  // Overlay (khi press)
                  overlayColor: theme.primary.withOpacity(0.2),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 28, // Increased from 20 to 28
                  ),

                  // Minimum interactive dimension
                  minThumbSeparation: 48,
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}