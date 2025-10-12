import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_slider.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/utils/data_manager.dart';
import '../../core/l10n/app_localizations.dart';
import '../../models/user_settings.dart';

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

  // Available BGM options
  final List<String> _bgmList = [
    'Lofi Beats',
    'Rain Sounds',
    'Piano Music',
    'Acoustic Ballad',
    'Traditional Melodies',
    'Indie Vibes',
    'Soft Pop',
    'Chill Acoustic',
  ];

  // Available themes with 5-color preview
  final List<Map<String, dynamic>> _themeList = [
    {
      'id': 'pastel_blue_breeze',
      'name': 'Pastel Blue Breeze',
      'colors': [
        AppColors.primary,
        AppColors.secondary,
        AppColors.text,
        AppColors.background,
        AppColors.border,
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _settings = DataManager().userSettings;
  }

  void _saveSettings() {
    DataManager().saveUserSettings(_settings);
  }

  void _showSyncToast() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.cloudSyncComingSoon),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _settings = UserSettings.initial();
                _saveSettings();
              });
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========== AUDIO ==========
        _buildSection(l10n.audio, [
          _buildLabel(l10n.bgm),
          const SizedBox(height: 8),
          AppDropdown<String>(
            value: _settings.bgm,
            items: _bgmList,
            itemBuilder: (bgm) => Text(bgm),
            onChanged: (bgm) {
              setState(() {
                _settings = _settings.copyWith(bgm: bgm);
                _saveSettings();
              });
            },
          ),
          const SizedBox(height: 16),
          AppSlider(
            label: l10n.volume,
            value: _settings.bgmVolume / 100,
            onChanged: (val) {
              setState(() {
                _settings = _settings.copyWith(bgmVolume: (val * 100).round());
                _saveSettings();
              });
            },
            showValue: true,
          ),
          const SizedBox(height: 24),
          _buildLabel(l10n.sfx),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.enabled,
                style: const TextStyle(color: AppColors.text, fontSize: 16),
              ),
              _buildToggleButtons(
                value: _settings.sfxEnabled,
                onChanged: (val) {
                  setState(() {
                    _settings = _settings.copyWith(sfxEnabled: val);
                    _saveSettings();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSlider(
            label: l10n.volume,
            value: _settings.sfxVolume / 100,
            onChanged: (val) {
              setState(() {
                _settings = _settings.copyWith(sfxVolume: (val * 100).round());
                _saveSettings();
              });
            },
            showValue: true,
          ),
        ]),

        const SizedBox(height: 32),

        // ========== DISPLAY ==========
        _buildSection(l10n.display, [
          _buildLabel(l10n.theme),
          const SizedBox(height: 12),
          _buildThemeSelector(),
          const SizedBox(height: 24),
          _buildLabel(l10n.preview),
          const SizedBox(height: 8),
          _buildThemePreview(),
          const SizedBox(height: 24),
          _buildLabel(l10n.language),
          const SizedBox(height: 12),
          _buildLanguageSelector(),
        ]),

        const SizedBox(height: 32),

        // ========== MASCOT ==========
        _buildSection(l10n.mascot, [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.name}:',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.mascotName,
                  style: const TextStyle(color: AppColors.text, fontSize: 16),
                ),
              ),
            ],
          ),
        ]),

        const SizedBox(height: 32),

        // ========== NOTIFICATION ==========
        _buildSection(l10n.notification, [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.sleepReminder}:',
                style: const TextStyle(color: AppColors.text, fontSize: 16),
              ),
              _buildToggleButtons(
                value: _settings.sleepReminderEnabled,
                onChanged: (val) {
                  setState(() {
                    _settings = _settings.copyWith(sleepReminderEnabled: val);
                    _saveSettings();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_settings.sleepReminderEnabled)
            _buildTimeSelector(
              '${l10n.time}:',
              _settings.sleepReminderTime,
              (time) {
                final minutes = time.hour * 60 + time.minute;
                setState(() {
                  _settings = _settings.copyWith(sleepReminderTimeMinutes: minutes);
                  _saveSettings();
                });
              },
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.taskReminder}:',
                style: const TextStyle(color: AppColors.text, fontSize: 16),
              ),
              _buildToggleButtons(
                value: _settings.taskReminderEnabled,
                onChanged: (val) {
                  setState(() {
                    _settings = _settings.copyWith(taskReminderEnabled: val);
                    _saveSettings();
                  });
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
            ),
        ]),

        const SizedBox(height: 32),

        // ========== CLOUD SYNC ==========
        _buildSection(l10n.cloudSync, [
          Center(
            child: AppButton(
              label: l10n.sync,
              onPressed: _showSyncToast,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _resetToDefault,
              child: Text(
                l10n.resetToDefault,
                style: const TextStyle(
                  color: AppColors.primary,
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ON/OFF toggle buttons sử dụng AppButton với isActive
  Widget _buildToggleButtons({required bool value, required Function(bool) onChanged}) {
    final l10n = AppLocalizations.of(context);
    
    return SizedBox(
      width: 80,
      height: 36,
      child: AppButton(
        label: value ? l10n.on : l10n.off,
        isActive: value,
        onPressed: () => onChanged(!value),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return AppDropdown<String>(
      value: _settings.currentTheme,
      items: _themeList.map((t) => t['id'] as String).toList(),
      itemBuilder: (themeId) {
        final theme = _themeList.firstWhere((t) => t['id'] == themeId);
        return Text(theme['name'] as String);
      },
      onChanged: (themeId) {
        setState(() {
          _settings = _settings.copyWith(currentTheme: themeId);
          _saveSettings();
        });
      },
    );
  }

  Widget _buildThemePreview() {
    final theme = _themeList.firstWhere((t) => t['id'] == _settings.currentTheme);
    final colors = theme['colors'] as List<Color>;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1.5),
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
                      ? const BorderSide(color: AppColors.border, width: 1)
                      : BorderSide.none,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.text, fontSize: 16),
        ),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time.format(context),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBeforeSelector(String label, int minutes, Function(int) onChanged) {
    final l10n = AppLocalizations.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.text, fontSize: 16),
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
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
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
        setState(() {
          _settings = _settings.copyWith(currentLanguage: langCode);
          _saveSettings();
        });
        // Đóng modal và reload app để cập nhật ngôn ngữ
        Navigator.pop(context);
      },
    );
  }
}