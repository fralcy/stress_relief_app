import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_shapes.dart';
import '../constants/app_typography.dart';

/// Custom dropdown với theme pastel
/// 
/// Features:
/// - Border: app border color
/// - Background: white
/// - Text: app text color
/// - Icon: dropdown arrow
class AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final Function(T) onChanged;
  final String? hint;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        // M3 surface color
        color: context.surfaceColor,

        // M3 outline color
        border: Border.all(
          color: context.outline,
          width: 1,
        ),

        // M3 shape (small)
        borderRadius: context.shapes.small.borderRadius as BorderRadius,
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(), // Remove default underline

        // M3 icon colors
        icon: Icon(
          Icons.arrow_drop_down,
          color: context.onSurfaceVariant,
          size: 24,
        ),
        iconDisabledColor: context.onSurface.withValues(alpha: 0.38),

        hint: hint != null
            ? Text(
                hint!,
                style: TextStyle(color: context.onSurfaceVariant),
              )
            : null,
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: itemBuilder(item),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },

        // M3 dropdown menu styling
        dropdownColor: context.surfaceColor,
        style: AppTypography.bodyLarge(context, color: context.theme.text),
      ),
    );
  }
}