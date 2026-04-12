import 'package:flutter/material.dart';
import 'mobile_portrait_splash_screen.dart';
import 'desktop_landscape_splash_screen.dart';

/// Responsive splash wrapper — chọn splash theo kích thước màn hình.
///
/// Desktop landscape (width >= 720 AND width > height): DesktopLandscapeSplashScreen
/// Còn lại: MobilePortraitSplashScreen
class ResponsiveSplashScreen extends StatelessWidget {
  const ResponsiveSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth >= 720 &&
            constraints.maxWidth > constraints.maxHeight;
        if (isLandscape) {
          return const DesktopLandscapeSplashScreen();
        }
        return const MobilePortraitSplashScreen();
      },
    );
  }
}
