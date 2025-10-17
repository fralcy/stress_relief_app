import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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
        color: context.theme.background,
        border: Border.all(color: context.theme.border, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(), // Remove default underline
        icon: Icon(
          Icons.arrow_drop_down,
          color: context.theme.text,
          size: 24,
        ),
        hint: hint != null
            ? Text(
                hint!,
                style: TextStyle(color: context.theme.text),
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
        dropdownColor: context.theme.background,
        style: TextStyle(
          color: context.theme.text,
          fontSize: 16,
        ),
      ),
    );
  }
}