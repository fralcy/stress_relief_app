import 'package:flutter/material.dart';
import 'app_button.dart';

/// Feature buttons - thay đổi theo scene hiện tại
/// 
/// Layout: Ngang, center, spacing 12px
class MainFeatureButtons extends StatelessWidget {
  final List<FeatureButton> buttons;

  const MainFeatureButtons({
    super.key,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: buttons.map((btn) {
          return AppButton(
            icon: btn.icon,
            label: btn.label,
            onPressed: btn.onPressed,
          );
        }).toList(),
      ),
    );
  }
}

/// Data class cho feature button
class FeatureButton {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const FeatureButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}