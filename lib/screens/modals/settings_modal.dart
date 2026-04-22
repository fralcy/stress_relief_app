import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/score_provider.dart';
import '../../core/providers/achievement_provider.dart';
import '../../core/providers/scene_provider.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_slider.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/bgm_service.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/sync_service.dart';
import '../../core/utils/auth_service.dart';
import '../../core/utils/navigation_service.dart';
import '../../core/utils/notifier.dart';
import '../../core/l10n/app_localizations.dart';
import '../../models/user_settings.dart';
import '../mobile_portrait_login_screen.dart';
import '../mobile_portrait_welcome_screen.dart';

/// Modal cài đặt app
class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();

  /// Helper để show modal
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.settings,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      content: const SettingsModal(),
    );
  }
}

class _SettingsModalState extends State<SettingsModal> {
  late UserSettings _settings;
  final AuthService _authService = AuthService();
  bool _isDebugMode = false;

  // Available BGM options
  final List<String> _bgmList = [
    'Lofi Beats',
    'Rain Sounds',
    'Piano Music',
    'Acoustic Ballad',
    'Folk Song',
    'Indie Vibes',
    'Soft Pop',
    'Chill Acoustic',
  ];

  bool get _isLoggedIn => _authService.isLoggedIn;

  @override
  void initState() {
    super.initState();
    _settings = DataManager().userSettings;
    _checkDebugMode();
  }

  Future<void> _checkDebugMode() async {
    final isDebug = await _authService.isDebugMode;
    if (mounted) {
      setState(() {
        _isDebugMode = isDebug;
      });
    }
  }

  void _saveSettings() {
    DataManager().saveUserSettings(_settings);
  }

  Future<void> _handleSync() async {
    SfxService().buttonClick();
    final l10n = AppLocalizations.of(context);
    
    // Import SyncService and AuthService
    final syncService = SyncService();
    final authService = AuthService();
    
    // Check if user is logged in
    if (!authService.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseLoginFirst),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: l10n.login,
            onPressed: () {
              // Navigate to login screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MobilePortraitLoginScreen(),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.syncing),
          ],
        ),
      ),
    );

    try {
      // Perform smart sync
      final result = await syncService.smartSync();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Refresh providers with synced data
      context.read<ScoreProvider>().refresh();
      context.read<SceneProvider>().refresh();
      context.read<ThemeProvider>().refresh();
      context.read<LocaleProvider>().refresh();
      await BgmService().applySettings();
      SfxService().applySettings();

      if (!mounted) return;
      // Retroactive check: cloud download may have changed data counts
      final score = context.read<ScoreProvider>();
      await context.read<AchievementProvider>().retroactiveCheck(score);

      if (!mounted) return;
      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(result),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${l10n.syncFailed}: $e'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    SfxService().buttonClick();
    final l10n = AppLocalizations.of(context);
    final errorColor = context.colorScheme.error;
    
    // Confirm logout
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.syncingAndLoggingOut),
          ],
        ),
      ),
    );

    try {
      // Perform logout with sync and clear data
      final syncService = SyncService();
      await syncService.logoutAndSync();

      // Refresh providers to reflect cleared state
      if (!mounted) return;
      context.read<ScoreProvider>().refresh();
      context.read<AchievementProvider>().refresh();
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close settings modal

      // Navigate to login screen after successful logout
      NavigationService.navigateAndClearStack(
        context,
        const MobilePortraitLoginScreen(),
      );

      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(l10n.logoutSuccessful),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${l10n.logoutFailed}: $e'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    SfxService().buttonClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MobilePortraitLoginScreen(),
      ),
    );
  }

  Future<void> _handleDebugExit() async {
    SfxService().buttonClick();
    final l10n = AppLocalizations.of(context);
    final errorColor = context.colorScheme.error;

    // Confirm exit
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exitDebugModeTitle),
        content: Text(l10n.exitDebugModeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: Text(l10n.exitDebugModeButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.clearingDataAndExiting),
          ],
        ),
      ),
    );

    try {
      // Clear auth flags and data
      await _authService.clearAuthFlags();
      await DataManager().clearAll();
      await DataManager().initialize(); // Re-initialize data manager

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close settings modal

      // Navigate to welcome screen
      NavigationService.navigateAndClearStack(
        context,
        const MobilePortraitWelcomeScreen(),
      );

      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(l10n.debugModeExited),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${l10n.operationFailed}: $e'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    SfxService().buttonClick();
    final l10n = AppLocalizations.of(context);
    final errorColor = context.colorScheme.error;

    // Step 1: Warning confirmation
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    if (step1 != true || !mounted) return;

    // Step 2: Password confirmation
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => _PasswordConfirmDialog(
        title: l10n.deleteAccountConfirmTitle,
        prompt: l10n.deleteAccountPasswordPrompt,
        confirmLabel: l10n.deleteAccount,
        cancelLabel: l10n.cancel,
        confirmColor: errorColor,
      ),
    );

    if (password == null || password.isEmpty || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.deletingAccount),
          ],
        ),
      ),
    );

    try {
      final authService = AuthService();
      final syncService = SyncService();

      // 1. Re-authenticate
      await authService.reauthenticate(password: password);
      // 2. Delete Firestore data
      await syncService.deleteUserData();
      // 3. Delete Firebase Auth account
      await authService.deleteAccount();
      // 4. Clear local Hive data and re-initialize to defaults
      await DataManager().clearAll();
      await DataManager().initialize();

      if (!mounted) return;
      // Refresh in-memory providers so UI reflects cleared state
      context.read<ScoreProvider>().refresh();
      context.read<AchievementProvider>().refresh();

      Navigator.pop(context); // close loading
      Navigator.pop(context); // close settings modal

      NavigationService.navigateAndClearStack(
        context,
        const MobilePortraitWelcomeScreen(),
      );

      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(l10n.deleteAccountSuccess),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      NavigationService.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${l10n.deleteAccountFailed}: $e'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          backgroundColor: errorColor,
        ),
      );
    }
  }

  void _resetToDefault() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetToDefault),
        content: Text(l10n.resetConfirmation),
        actions: [
          TextButton(
            onPressed: () {
              SfxService().buttonClick();
              Navigator.pop(context);
            },
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              SfxService().buttonClick();
              setState(() {
                _settings = UserSettings.initial();
                _saveSettings();
              });
              // Reset theme provider
              context.read<ThemeProvider>().setTheme(_settings.currentTheme);
              Navigator.pop(context);
            },
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========== AUDIO ==========
        _buildSection(l10n.audio, theme, [
          _buildLabel(l10n.bgm, theme),
          const SizedBox(height: 8),
          AppDropdown<String>(
            value: _settings.bgm,
            items: _bgmList,
            itemBuilder: (bgm) {
              String localizedName;
              switch (bgm) {
                case 'Lofi Beats':
                  localizedName = l10n.bgmLofiBeats;
                  break;
                case 'Rain Sounds':
                  localizedName = l10n.bgmRainSounds;
                  break;
                case 'Piano Music':
                  localizedName = l10n.bgmPianoMusic;
                  break;
                case 'Acoustic Ballad':
                  localizedName = l10n.bgmAcousticBallad;
                  break;
                case 'Folk Song':
                  localizedName = l10n.bgmFolkSong;
                  break;
                case 'Indie Vibes':
                  localizedName = l10n.bgmIndieVibes;
                  break;
                case 'Soft Pop':
                  localizedName = l10n.bgmSoftPop;
                  break;
                case 'Chill Acoustic':
                  localizedName = l10n.bgmChillAcoustic;
                  break;
                default:
                  localizedName = bgm;
              }
              return Text(localizedName);
            },
            onChanged: (bgm) {
              SfxService().buttonClick();
              setState(() {
                _settings = _settings.copyWith(bgm: bgm);
                _saveSettings();
              });
              // ← THÊM DÒNG NÀY để apply ngay
              BgmService().changeBgm(bgm);
            },
          ),
          const SizedBox(height: 16),
          AppSlider(
            label: l10n.volume,
            value: _settings.bgmVolume.toDouble(),
            min: 0,
            max: 100,
            onChanged: (val) {
              final newVolume = val.round();
              setState(() {
                _settings = _settings.copyWith(bgmVolume: newVolume);
                _saveSettings();
              });
              BgmService().changeVolume(newVolume);
            },
            showValue: true,
          ),
          const SizedBox(height: 24),
          _buildLabel(l10n.sfx, theme),
          const SizedBox(height: 8),

          // Toggle ON/OFF
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.enabled,
                style: AppTypography.bodyMedium(context, color: theme.text),
              ),
              Switch(
                value: _settings.sfxEnabled,
                activeThumbColor: theme.primary,
                onChanged: (val) {
                  setState(() {
                    _settings = _settings.copyWith(sfxEnabled: val);
                    _saveSettings();
                  });
                  SfxService().setEnabled(val); // Apply ngay
                  
                  // Play test sound khi bật
                  if (val) {
                    SfxService().buttonClick();
                  }
                },
              ),
            ],
          ),

          // Volume slider (chỉ hiện khi SFX enabled)
          if (_settings.sfxEnabled) ...[
            const SizedBox(height: 16),
            AppSlider(
              label: l10n.volume,
              value: _settings.sfxVolume.toDouble(),
              min: 0,
              max: 100,
              onChanged: (val) {
                final newVolume = val.round();
                setState(() {
                  _settings = _settings.copyWith(sfxVolume: newVolume);
                  _saveSettings();
                });
                SfxService().changeVolume(newVolume);
                
                // Play test sound để nghe volume
                SfxService().buttonClick();
              },
              showValue: true,
            ),
          ],
        ]),

        const SizedBox(height: 32),

        // ========== DISPLAY ==========
        _buildSection(l10n.display, theme, [
          _buildLabel(l10n.theme, theme),
          const SizedBox(height: 12),
          _buildThemeSelector(theme),
          const SizedBox(height: 24),
          _buildLabel(l10n.preview, theme),
          const SizedBox(height: 8),
          _buildThemePreview(theme),
          const SizedBox(height: 24),
          _buildLabel(l10n.language, theme),
          const SizedBox(height: 12),
          _buildLanguageSelector(),
        ]),

        const SizedBox(height: 32),

        // ========== NOTIFICATION ==========
        _buildSection(l10n.notification, theme, [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.taskReminder}:',
                style: AppTypography.bodyLarge(context, color: theme.text),
              ),
              Switch(
                value: _settings.taskReminderEnabled,
                activeThumbColor: theme.primary,
                onChanged: (val) async {
                  if (val) {
                    // Request notification permission when enabling
                    final permitted = await Notifier.requestPermissions();
                    if (!permitted) {
                      SfxService().error();
                      return;
                    }
                  }
                  
                  setState(() {
                    _settings = _settings.copyWith(taskReminderEnabled: val);
                    _saveSettings();
                  });
                  
                  // Update task notifications
                  final tasks = DataManager().scheduleTasks;
                  await Notifier.updateAllTaskReminders(
                    tasks: tasks,
                    settings: _settings,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_settings.taskReminderEnabled)
            _buildBeforeSelector(
              '${l10n.before}:',
              _settings.taskReminderTime,
              (minutes) {
                setState(() {
                  _settings = _settings.copyWith(taskReminderTime: minutes);
                  _saveSettings();
                });
              },
              theme,
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.sleepReminder}:',
                style: AppTypography.bodyLarge(context, color: theme.text),
              ),
              Switch(
                value: _settings.sleepReminderEnabled,
                activeThumbColor: theme.primary,
                onChanged: (val) async {
                  if (val) {
                    final permitted = await Notifier.requestPermissions();
                    if (!mounted) return;
                    if (!permitted) {
                      SfxService().error();
                      return;
                    }
                  }
                  setState(() {
                    _settings = _settings.copyWith(sleepReminderEnabled: val);
                    _saveSettings();
                  });
                  if (val) {
                    await Notifier.scheduleSleepReminder(_settings);
                  } else {
                    await Notifier.cancelSleepReminder();
                  }
                },
              ),
            ],
          ),
        ]),

        const SizedBox(height: 32),

        // ========== ACCOUNT ==========
        _buildSection(l10n.cloudSync, theme, [
          if (_isDebugMode) ...[
            // Debug mode: Show exit button only
            Center(
              child: ElevatedButton(
                onPressed: _handleDebugExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: context.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Builder(
                  builder: (context) => Text(
                    'Exit Debug Mode',
                    style: AppTypography.labelLarge(context, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ] else if (_isLoggedIn) ...[
            // Logged in: Show sync and logout buttons
            Center(
              child: AppButton(
                label: l10n.sync,
                onPressed: _handleSync,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colorScheme.error,
                  foregroundColor: context.colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Builder(
                  builder: (context) => Text(
                    l10n.logout,
                    style: AppTypography.labelLarge(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _handleDeleteAccount,
                child: Text(
                  l10n.deleteAccount,
                  style: TextStyle(
                    color: context.colorScheme.error,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Guest mode: Show login button
            Center(
              child: AppButton(
                label: l10n.login,
                onPressed: _handleLogin,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _resetToDefault,
              child: Text(
                l10n.resetToDefault,
                style: TextStyle(
                  color: theme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ]),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSection(String title, AppTheme theme, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) => Text(
            title,
            style: AppTypography.h4(context, color: theme.text),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildLabel(String text, AppTheme theme) {
    return Builder(
      builder: (context) => Text(
        text,
        style: AppTypography.labelLarge(context, color: theme.text),
      ),
    );
  }



  Widget _buildThemeSelector(AppTheme currentTheme) {
    final l10n = AppLocalizations.of(context);
    return AppDropdown<String>(
      value: _settings.currentTheme,
      items: AppThemes.all.map((t) => t.id).toList(),
      itemBuilder: (themeId) {
        String localizedName;
        switch (themeId) {
          case 'pastel_blue_breeze':
            localizedName = l10n.themePastelBlueBreeze;
            break;
          case 'calm_lavender':
            localizedName = l10n.themeCalmLavender;
            break;
          case 'warm_amber':
            localizedName = l10n.themeWarmAmber;
            break;
          case 'minty_fresh':
            localizedName = l10n.themeMintyFresh;
            break;
          case 'midnight_blue':
            localizedName = l10n.themeMidnightBlue;
            break;
          case 'soft_purple_night':
            localizedName = l10n.themeSoftPurpleNight;
            break;
          case 'warm_sunset':
            localizedName = l10n.themeWarmSunset;
            break;
          case 'serene_green_night':
            localizedName = l10n.themeSereneGreenNight;
            break;
          default:
            final theme = AppThemes.getById(themeId);
            localizedName = theme.name;
        }
        return Text(localizedName);
      },
      onChanged: (themeId) {
        SfxService().buttonClick();
        setState(() {
          _settings = _settings.copyWith(currentTheme: themeId);
          _saveSettings();
        });
        // Update theme provider để UI thay đổi real-time
        context.read<ThemeProvider>().setTheme(themeId);
      },
    );
  }

  Widget _buildThemePreview(AppTheme theme) {
    final selectedTheme = AppThemes.getById(_settings.currentTheme);
    final colors = selectedTheme.previewColors;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: theme.border, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: colors.map((color) {
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color,
                border: Border(
                  right: color != colors.last
                      ? BorderSide(color: theme.border, width: 1)
                      : BorderSide.none,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBeforeSelector(
    String label,
    int minutes,
    Function(int) onChanged,
    AppTheme theme,
  ) {
    final l10n = AppLocalizations.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyLarge(context, color: theme.text),
        ),
        InkWell(
          onTap: () async {
            final picked = await showDialog<int>(
              context: context,
              builder: (context) => SimpleDialog(
                title: Text(l10n.remindBeforeMinutes),
                children: [15, 30, 45, 60].map((min) {
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, min),
                    child: Text('$min ${l10n.minutes}'),
                  );
                }).toList(),
              ),
            );
            if (picked != null) {
              SfxService().buttonClick();
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.border, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (context) => Text(
                    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}',
                    style: AppTypography.bodyLarge(context, color: context.colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: context.colorScheme.onPrimary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    final languageOptions = {
      'vi': 'Tiếng Việt',
      'en': 'English',
    };

    return AppDropdown<String>(
      value: _settings.currentLanguage,
      items: languageOptions.keys.toList(),
      itemBuilder: (langCode) => Text(languageOptions[langCode]!),
      onChanged: (langCode) { 
        SfxService().buttonClick();
        
        setState(() {
          _settings = _settings.copyWith(currentLanguage: langCode);
          _saveSettings();
        });
        
        context.read<LocaleProvider>().setLocale(langCode);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Password confirmation dialog used for the delete-account flow
// ---------------------------------------------------------------------------

class _PasswordConfirmDialog extends StatefulWidget {
  final String title;
  final String prompt;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;

  const _PasswordConfirmDialog({
    required this.title,
    required this.prompt,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmColor,
  });

  @override
  State<_PasswordConfirmDialog> createState() => _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.prompt),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(widget.cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: TextButton.styleFrom(foregroundColor: widget.confirmColor),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}