import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/utils/navigation_service.dart';
import 'mobile_portrait_welcome_screen.dart';
import 'responsive_screen.dart';

/// Desktop Landscape Splash Screen
///
/// Hiển thị khi mở app ở chế độ landscape/desktop.
/// - Gradient ngang (centerLeft → centerRight) nhất quán với layout landscape
/// - Asset: assets/images/desktop_splash.png (landscape orientation)
/// - Fade in → 1.5s → fade out → navigate
class DesktopLandscapeSplashScreen extends StatefulWidget {
  const DesktopLandscapeSplashScreen({super.key});

  @override
  State<DesktopLandscapeSplashScreen> createState() =>
      _DesktopLandscapeSplashScreenState();
}

class _DesktopLandscapeSplashScreenState
    extends State<DesktopLandscapeSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    await _controller.reverse();
    if (!mounted) return;

    final navigationService = NavigationService();
    final targetRoute = await navigationService.getInitialRoute();
    if (!mounted) return;

    Widget targetScreen;
    switch (targetRoute) {
      case '/welcome':
        targetScreen = const MobilePortraitWelcomeScreen();
        break;
      case '/main':
        targetScreen = const ResponsiveScreen();
        break;
      default:
        targetScreen = const MobilePortraitWelcomeScreen();
    }

    NavigationService.navigateWithFade(context, targetScreen);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              theme.background,
              theme.primary.withValues(alpha: 0.3),
              theme.primary.withValues(alpha: 0.3),
              theme.background,
            ],
            stops: const [0.0, 0.25, 0.75, 1.0],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/desktop_splash.webp',
              height: double.infinity,
              fit: BoxFit.fitHeight,
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.spa, size: 80, color: theme.primary),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) => Text(
                        'PeacePal',
                        style: AppTypography.h1(context, color: theme.text),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
