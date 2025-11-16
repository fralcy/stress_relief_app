import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../main.dart';

/// Mobile Portrait Splash Screen
/// 
/// Hiển thị mascot + scene khi mở app
/// - Gradient background matching app theme
/// - Fade transition khi xuất hiện và biến mất
/// - Auto navigate sau 2.5 giây
/// - Check auth status để route đúng màn hình
class MobilePortraitSplashScreen extends StatefulWidget {
  const MobilePortraitSplashScreen({super.key});

  @override
  State<MobilePortraitSplashScreen> createState() => _MobilePortraitSplashScreenState();
}

class _MobilePortraitSplashScreenState extends State<MobilePortraitSplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup smooth fade animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.forward();
    
    // Navigate sau 2.5 giây
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    // Fade out trước khi chuyển màn
    await _controller.reverse();
    
    if (!mounted) return;
    
    // Navigate với page transition mượt đến TestMenuScreen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const TestMenuScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.background,
              theme.primary.withOpacity(0.3),
              theme.primary.withOpacity(0.3),
              theme.background,
            ],
            stops: const [0.0, 0.25, 0.75, 1.0],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/mobile_splash.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) {
                // Fallback nếu không có splash art
                return Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: theme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.spa,
                        size: 64,
                        color: theme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PeacePal',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
