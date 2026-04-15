import 'package:flutter/material.dart';
import 'mobile_portrait_screen.dart';
import 'desktop_landscape_screen.dart';

/// Responsive wrapper — picks layout based on screen dimensions.
///
/// Desktop landscape: width >= 720px AND width > height
/// Otherwise: mobile portrait (including phones in landscape)
class ResponsiveScreen extends StatelessWidget {
  const ResponsiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 720 &&
            constraints.maxWidth > constraints.maxHeight &&
            constraints.maxHeight >= 600;
        if (isDesktop) {
          return const DesktopLandscapeScreen();
        }
        return const MobilePortraitScreen();
      },
    );
  }
}
