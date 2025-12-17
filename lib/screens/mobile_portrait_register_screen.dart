import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/auth_service.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/sync_service.dart';
import '../../core/utils/navigation_service.dart';
import '../../core/providers/score_provider.dart';
import 'mobile_portrait_screen.dart';

/// Mobile Portrait Register Screen
/// 
/// Form đăng ký với:
/// - Email
/// - Username  
/// - Password
/// - Confirm password
/// - Dynamic theme support
/// - Localization support
class MobilePortraitRegisterScreen extends StatefulWidget {
  const MobilePortraitRegisterScreen({super.key});

  @override
  State<MobilePortraitRegisterScreen> createState() => _MobilePortraitRegisterScreenState();
}

class _MobilePortraitRegisterScreenState extends State<MobilePortraitRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Register with Firebase Auth
      final userCredential = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Check if upgrading from guest mode
      final wasGuest = await _authService.isGuestMode;

      // Create user profile after successful Firebase registration
      if (userCredential?.user != null) {
        if (wasGuest) {
          await _authService.upgradeFromGuest();
        }

        // Switch to logged in user mode
        await DataManager().switchToLoggedInUser(
          userId: userCredential!.user!.uid,
          email: _emailController.text.trim(),
          displayName: _emailController.text.trim().split('@')[0],
          hasCloudData: false, // New account
        );

        // Auto sync after successful registration
        try {
          final syncService = SyncService();
          final syncResult = await syncService.smartSync();

          if (mounted) {
            // Refresh ScoreProvider to load synced data
            context.read<ScoreProvider>().refresh();

            setState(() => _isLoading = false);

            // Show success message with sync info
            String message = wasGuest
                ? '${AppLocalizations.of(context).welcomeUpgradedFromGuest} $syncResult'
                : '${AppLocalizations.of(context).registrationSuccessful} $syncResult';
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

            // Show registration success but sync warning
            String message = wasGuest
                ? '${AppLocalizations.of(context).welcomeUpgradedFromGuest} ${AppLocalizations.of(context).syncWillRetryLater}'
                : '${AppLocalizations.of(context).registrationSuccessful} ${AppLocalizations.of(context).syncWillRetryLater}';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: context.theme.primary,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        // Navigate to main app screen (skip login since already registered)
        if (mounted) {
          NavigationService.navigateAndClearStack(
            context,
            const MobilePortraitScreen(),
          );
        }
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
                  const SizedBox(height: 40),
                  
                  // Header
                  Text(
                    l10n.letsGetStarted,
                    style: AppTypography.display(context, color: theme.text),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    l10n.createAccount,
                    style: AppTypography.bodyLarge(context, color: theme.text.withOpacity(0.6)),
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
                      if (value.length < 6) {
                        return l10n.passwordTooShort;
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Confirm password field
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: l10n.confirmPassword,
                    hint: l10n.enterPassword,
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: theme.text.withOpacity(0.5),
                      ),
                      onPressed: () {
                        setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.enterPassword;
                      }
                      if (value != _passwordController.text) {
                        return l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Register button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
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
                        : Builder(
                            builder: (context) => Text(
                              l10n.signUp,
                              style: AppTypography.button(context),
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sign in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.alreadyHaveAccount,
                        style: AppTypography.bodyLarge(context, color: theme.text.withOpacity(0.6)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Builder(
                          builder: (context) => Text(
                            l10n.signIn,
                            style: AppTypography.button(context, color: theme.primary),
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
          style: AppTypography.labelMedium(context, color: theme.text),
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