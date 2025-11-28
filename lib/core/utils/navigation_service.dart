import 'package:flutter/material.dart';
import 'auth_service.dart';

/// Service quản lý logic điều hướng cho toàn bộ ứng dụng
/// 
/// Flow logic:
/// - Lần đầu mở: splash -> welcome -> tutorial -> login -> main
/// - Lần sau: splash -> main (nếu đã có user data hoặc guest mode)
/// - Guest mode: có thể vào main mà không cần đăng nhập
/// - Authenticated: vào main screen luôn
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();
  
  final AuthService _authService = AuthService();
  
  /// Xác định màn hình đích từ splash screen
  Future<String> getInitialRoute() async {
    final userMode = await _authService.userMode;
    
    switch (userMode) {
      case 'first_launch':
        // Lần đầu mở app -> welcome screen để setup
        return '/welcome';

      case 'debug':
      case 'guest':
      case 'logged_in':
        // Debug, guest, hoặc đã đăng nhập -> main screen
        return '/main';

      default:
        // Fallback -> welcome screen
        return '/welcome';
    }
  }
  
  /// Navigate từ welcome screen
  /// Welcome -> Tutorial (sau khi setup xong)
  String getRouteAfterWelcome() {
    return '/tutorial';
  }
  
  /// Navigate từ tutorial screen  
  /// Tutorial -> Login (sau khi xem hướng dẫn xong)
  String getRouteAfterTutorial() {
    return '/login';
  }
  
  /// Navigate từ login screen (thành công)
  /// Login -> Main (sau khi đăng nhập thành công)
  String getRouteAfterLogin() {
    return '/main';
  }
  
  /// Navigate từ register screen (thành công)
  /// Register -> Main (sau khi đăng ký thành công)
  String getRouteAfterRegister() {
    return '/main';
  }
  
  /// Navigate khi chọn guest mode
  /// Any screen -> Main (skip login)
  Future<String> getRouteForGuestMode() async {
    await _authService.setGuestMode();
    return '/main';
  }
  
  /// Reset về welcome screen (khi logout hoặc reset app)
  Future<String> getRouteForReset() async {
    // Clear auth flags nhưng giữ nguyên first_launch = false
    // để lần sau vào main screen
    return '/welcome';
  }
  
  /// Check xem có thể skip welcome/tutorial không
  /// (dùng cho debug hoặc testing)
  Future<bool> canSkipOnboarding() async {
    final userMode = await _authService.userMode;
    return userMode != 'first_launch';
  }
  
  /// Navigate với transition smooth
  static void navigateWithFade(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
  
  /// Navigate và clear stack (dùng khi chuyển sang main screen)
  static void navigateAndClearStack(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false, // Clear entire stack
    );
  }
  
  /// Navigate với slide transition (dùng cho login/register flow)
  static void navigateWithSlide(BuildContext context, Widget screen, {bool isRightToLeft = false}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: isRightToLeft ? -begin : begin, end: end)
              .chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
  
  /// Pop với slide transition
  static void popWithSlide(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  /// Debug info về navigation state
  Future<Map<String, dynamic>> getNavigationDebugInfo() async {
    final authDebug = await _authService.getAuthDebugInfo();
    final initialRoute = await getInitialRoute();
    
    return {
      ...authDebug,
      'initialRoute': initialRoute,
      'canSkipOnboarding': await canSkipOnboarding(),
    };
  }
}