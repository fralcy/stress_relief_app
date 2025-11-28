import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/auth_service.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/sync_service.dart';
import '../../core/utils/navigation_service.dart';
import '../../core/providers/score_provider.dart';
import 'mobile_portrait_register_screen.dart';
import 'mobile_portrait_screen.dart';
import 'mobile_portrait_forgot_password_screen.dart';

/// Mobile Portrait Login Screen
/// 
/// Form đăng nhập với:
/// - Email
/// - Password
/// - Dynamic theme support
/// - Localization support
/// - Navigation to register screen
class MobilePortraitLoginScreen extends StatefulWidget {
  const MobilePortraitLoginScreen({super.key});

  @override
  State<MobilePortraitLoginScreen> createState() => _MobilePortraitLoginScreenState();
}

class _MobilePortraitLoginScreenState extends State<MobilePortraitLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Check for debug credentials FIRST
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email == 'hidden.sequence@testmail.com' && password == 'UUDDLRLRBA') {
        await _activateDebugMode();
        return;
      }

      // Login with Firebase Auth
      final userCredential = await _authService.login(
        email: email,
        password: password,
      );

      if (mounted && userCredential != null) {
        // Check if upgrading from guest mode
        final wasGuest = await _authService.isGuestMode;
        if (wasGuest) {
          await _authService.upgradeFromGuest();
        }
        
        // Update DataManager with Firebase user info
        final user = userCredential.user!;
        final dataManager = DataManager();
        
        // Switch to logged in user mode
        await dataManager.switchToLoggedInUser(
          userId: user.uid,
          email: user.email!,
          displayName: user.displayName,
          hasCloudData: false, // Will be checked during sync
        );
        
        // Auto sync after successful login
        try {
          final syncService = SyncService();
          final syncResult = await syncService.smartSync();

          if (mounted) {
            // Refresh ScoreProvider to load synced data
            context.read<ScoreProvider>().refresh();

            setState(() => _isLoading = false);

            // Show success message with sync info
            String message = wasGuest
                ? '${AppLocalizations.of(context).upgradedFromGuestMode} $syncResult'
                : '${AppLocalizations.of(context).loginSuccessful} $syncResult';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: context.theme.primary,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (syncError) {
          if (mounted) {
            setState(() => _isLoading = false);
            
            // Show login success but sync warning
            String message = wasGuest
                ? '${AppLocalizations.of(context).upgradedFromGuestMode} ${AppLocalizations.of(context).syncWillRetryLater}'
                : '${AppLocalizations.of(context).loginSuccessful} ${AppLocalizations.of(context).syncWillRetryLater}';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: context.theme.primary,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
        
        // Navigate to main app screen
        NavigationService.navigateAndClearStack(
          context,
          const MobilePortraitScreen(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _useAsGuest() async {
    try {
      // Set guest mode
      await _authService.setGuestMode();

      // Switch DataManager to guest mode
      await DataManager().switchToGuestMode();

      if (mounted) {
        // Show guest mode message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).usingAsGuestMessage),
            backgroundColor: context.theme.primary,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to main app screen
        NavigationService.navigateAndClearStack(
          context,
          const MobilePortraitScreen(),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).failedToStartGuestMode}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _activateDebugMode() async {
    try {
      // Set debug mode
      await _authService.setDebugMode();

      // Switch DataManager to debug mode
      await DataManager().switchToDebugMode();

      if (mounted) {
        setState(() => _isLoading = false);

        // Show subtle success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debug mode activated'),
            backgroundColor: Colors.deepPurple,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to main screen
        await Future.delayed(const Duration(milliseconds: 500));
        NavigationService.navigateAndClearStack(
          context,
          const MobilePortraitScreen(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug activation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MobilePortraitForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primary.withOpacity(0.2),
              theme.background,
              theme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  
                  // Header
                  Text(
                    l10n.welcomeBack,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    l10n.signIn,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.text.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Email field
                  _buildTextField(
                    controller: _emailController,
                    label: l10n.email,
                    hint: l10n.enterEmail,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.invalidEmail;
                      }
                      // Simple email validation
                      if (!value.contains('@') || !value.contains('.')) {
                        return l10n.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password field
                  _buildTextField(
                    controller: _passwordController,
                    label: l10n.password,
                    hint: l10n.enterPassword,
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: theme.text.withOpacity(0.5),
                      ),
                      onPressed: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.enterPassword;
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _navigateToForgotPassword,
                      child: Text(
                        AppLocalizations.of(context).forgotPassword,
                        style: TextStyle(
                          color: theme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.signIn,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Guest mode button
                  OutlinedButton(
                    onPressed: _useAsGuest,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).useAsGuest,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.primary,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.dontHaveAccount,
                        style: TextStyle(
                          color: theme.text.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MobilePortraitRegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          l10n.signUp,
                          style: TextStyle(
                            color: theme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final theme = context.theme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(color: theme.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.text.withOpacity(0.4)),
            prefixIcon: Icon(prefixIcon, color: theme.primary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: theme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}