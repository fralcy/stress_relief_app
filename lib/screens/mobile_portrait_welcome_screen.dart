import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../core/providers/theme_provider.dart';
import '../core/providers/locale_provider.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_slider.dart';
import '../core/widgets/app_dropdown.dart';
import '../core/utils/data_manager.dart';
import '../core/utils/bgm_service.dart';
import '../core/utils/sfx_service.dart';
import '../core/utils/navigation_service.dart';
import '../core/l10n/app_localizations.dart';
import '../models/user_settings.dart';
import 'mobile_portrait_tutorial_screen.dart';

/// Welcome Screen với Initial Setup
class MobilePortraitWelcomeScreen extends StatefulWidget {
  const MobilePortraitWelcomeScreen({super.key});

  @override
  State<MobilePortraitWelcomeScreen> createState() => _MobilePortraitWelcomeScreenState();
}

class _MobilePortraitWelcomeScreenState extends State<MobilePortraitWelcomeScreen> {
  int _currentStep = 0;
  late UserSettings _settings;
  
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

  @override
  void initState() {
    super.initState();
    _settings = DataManager().userSettings;
  }

  void _nextStep() {
    SfxService().buttonClick();
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _finishSetup();
    }
  }

  void _previousStep() {
    SfxService().buttonClick();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _finishSetup() {
    // Save settings
    DataManager().saveUserSettings(_settings);
    
    // Apply theme
    context.read<ThemeProvider>().setTheme(_settings.currentTheme);
    
    // Apply language
    context.read<LocaleProvider>().setLocale(_settings.currentLanguage);
    
    // Apply audio
    BgmService().changeBgm(_settings.bgm);
    BgmService().changeVolume(_settings.bgmVolume);
    
    // Apply SFX settings
    SfxService().setEnabled(_settings.sfxEnabled);
    SfxService().changeVolume(_settings.sfxVolume);
    
    // Navigate to tutorial screen
    NavigationService.navigateWithFade(
      context, 
      const MobilePortraitTutorialScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(theme),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildStepContent(theme),
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Step labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStepLabel(AppLocalizations.of(context).language, 0, theme),
              _buildStepLabel(AppLocalizations.of(context).theme, 1, theme),
              _buildStepLabel(AppLocalizations.of(context).audio, 2, theme),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: List.generate(3, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isActive || isCompleted 
                        ? theme.primary 
                        : theme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: theme.primary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ] : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepLabel(String label, int stepIndex, AppTheme theme) {
    final isActive = stepIndex == _currentStep;
    final isCompleted = stepIndex < _currentStep;
    
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.normal,
        color: isActive || isCompleted ? theme.primary : theme.text.withOpacity(0.5),
      ),
    );
  }

  Widget _buildStepContent(AppTheme theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(_currentStep),
        child: _getStepWidget(theme),
      ),
    );
  }
  
  Widget _getStepWidget(AppTheme theme) {
    switch (_currentStep) {
      case 0:
        return _buildLanguageStep(theme);
      case 1:
        return _buildThemeStep(theme);
      case 2:
        return _buildAudioStep(theme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildThemeStep(AppTheme theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.palette_outlined,
              size: 60,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context).chooseYourTheme,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).pickColorScheme,
            style: TextStyle(
              fontSize: 16,
              color: theme.text.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Theme options
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: AppThemes.all.map((themeOption) {
              final isSelected = _settings.currentTheme == themeOption.id;

              return GestureDetector(
                onTap: () {
                  SfxService().buttonClick();
                  setState(() {
                    _settings = _settings.copyWith(currentTheme: themeOption.id);
                  });
                  // Preview theme immediately
                  context.read<ThemeProvider>().setTheme(themeOption.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  height: 110,
                  decoration: BoxDecoration(
                    color: themeOption.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? themeOption.primary : themeOption.border,
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isSelected ? 0.15 : 0.08),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Color preview circles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: themeOption.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: themeOption.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getLocalizedThemeName(themeOption.id, AppLocalizations.of(context)),
                        style: TextStyle(
                          color: themeOption.text,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Icon(
                          Icons.check_circle,
                          color: themeOption.primary,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLanguageStep(AppTheme theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.language_outlined,
              size: 60,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context).selectLanguage,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).choosePreferredLanguage,
            style: TextStyle(
              fontSize: 16,
              color: theme.text.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Language options
          _buildLanguageOption(
            theme: theme,
            flag: '🇬🇧',
            language: 'English',
            code: 'en',
          ),
          const SizedBox(height: 16),
          _buildLanguageOption(
            theme: theme,
            flag: '🇻🇳',
            language: 'Tiếng Việt',
            code: 'vi',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required AppTheme theme,
    required String flag,
    required String language,
    required String code,
  }) {
    final isSelected = _settings.currentLanguage == code;
    
    return GestureDetector(
      onTap: () {
        SfxService().buttonClick();
        setState(() {
          _settings = _settings.copyWith(currentLanguage: code);
        });
        // Preview language immediately
        context.read<LocaleProvider>().setLocale(code);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.primary.withOpacity(0.1) 
              : theme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primary : theme.border,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.border.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                language,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: theme.text,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioStep(AppTheme theme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.headphones_outlined,
              size: 60,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context).audioSettings,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).customizeAudioExperience,
            style: TextStyle(
              fontSize: 16,
              color: theme.text.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // Audio Settings Cards
          _buildAudioCard(
            theme: theme,
            icon: Icons.library_music_outlined,
            title: AppLocalizations.of(context).backgroundMusic,
            child: Column(
              children: [
                const SizedBox(height: 16),
                AppDropdown<String>(
                  value: _settings.bgm,
                  items: _bgmList,
                  itemBuilder: (bgm) {
                    String localizedName;
                    switch (bgm) {
                      case 'Lofi Beats':
                        localizedName = AppLocalizations.of(context).bgmLofiBeats;
                        break;
                      case 'Rain Sounds':
                        localizedName = AppLocalizations.of(context).bgmRainSounds;
                        break;
                      case 'Piano Music':
                        localizedName = AppLocalizations.of(context).bgmPianoMusic;
                        break;
                      case 'Acoustic Ballad':
                        localizedName = AppLocalizations.of(context).bgmAcousticBallad;
                        break;
                      case 'Folk Song':
                        localizedName = AppLocalizations.of(context).bgmFolkSong;
                        break;
                      case 'Indie Vibes':
                        localizedName = AppLocalizations.of(context).bgmIndieVibes;
                        break;
                      case 'Soft Pop':
                        localizedName = AppLocalizations.of(context).bgmSoftPop;
                        break;
                      case 'Chill Acoustic':
                        localizedName = AppLocalizations.of(context).bgmChillAcoustic;
                        break;
                      default:
                        localizedName = bgm;
                    }
                    return Row(
                      children: [
                        Icon(Icons.music_note, size: 16, color: theme.primary),
                        const SizedBox(width: 8),
                        Text(localizedName),
                      ],
                    );
                  },
                  onChanged: (bgm) {
                    SfxService().buttonClick();
                    setState(() {
                      _settings = _settings.copyWith(bgm: bgm);
                    });
                    // Preview the new BGM immediately
                    BgmService().changeBgm(bgm);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.volume_down, color: theme.text.withOpacity(0.6), size: 20),
                    Expanded(
                      child: AppSlider(
                        label: '${_settings.bgmVolume}%',
                        value: _settings.bgmVolume.toDouble(),
                        min: 0,
                        max: 100,
                        onChanged: (val) {
                          final newVolume = val.round();
                          setState(() {
                            _settings = _settings.copyWith(bgmVolume: newVolume);
                          });
                          BgmService().changeVolume(newVolume);
                        },
                      ),
                    ),
                    Icon(Icons.volume_up, color: theme.text.withOpacity(0.6), size: 20),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          _buildAudioCard(
            theme: theme,
            icon: Icons.volume_up_outlined,
            title: AppLocalizations.of(context).soundEffects,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).enableSFX,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: _settings.sfxEnabled,
                      onChanged: (val) {
                        setState(() {
                          _settings = _settings.copyWith(sfxEnabled: val);
                        });
                        SfxService().setEnabled(val);
                        if (val) {
                          SfxService().buttonClick();
                        }
                      },
                      activeColor: theme.primary,
                    ),
                  ],
                ),
                if (_settings.sfxEnabled) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.volume_down, color: theme.text.withOpacity(0.6), size: 20),
                      Expanded(
                        child: AppSlider(
                          label: '${_settings.sfxVolume}%',
                          value: _settings.sfxVolume.toDouble(),
                          min: 0,
                          max: 100,
                          onChanged: (val) {
                            final newVolume = val.round();
                            setState(() {
                              _settings = _settings.copyWith(sfxVolume: newVolume);
                            });
                            SfxService().changeVolume(newVolume);
                            SfxService().buttonClick();
                          },
                        ),
                      ),
                      Icon(Icons.volume_up, color: theme.text.withOpacity(0.6), size: 20),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCard({
    required AppTheme theme,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: theme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.text,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(
          top: BorderSide(
            color: theme.border.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: AppButton(
                  label: AppLocalizations.of(context).back,
                  onPressed: _previousStep,
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: AppButton(
                  label: _currentStep == 2 ? AppLocalizations.of(context).getStarted : AppLocalizations.of(context).next,
                  isActive: true,
                  onPressed: _nextStep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedThemeName(String themeId, AppLocalizations l10n) {
    switch (themeId) {
      case 'pastel_blue_breeze':
        return l10n.themePastelBlueBreeze;
      case 'calm_lavender':
        return l10n.themeCalmLavender;
      case 'sunny_pastel_yellow':
        return l10n.themeSunnyPastelYellow;
      case 'minty_fresh':
        return l10n.themeMintyFresh;
      case 'midnight_blue':
        return l10n.themeMidnightBlue;
      case 'soft_purple_night':
        return l10n.themeSoftPurpleNight;
      case 'warm_sunset':
        return l10n.themeWarmSunset;
      case 'serene_green_night':
        return l10n.themeSereneGreenNight;
      default:
        return themeId; // fallback to ID
    }
  }
}