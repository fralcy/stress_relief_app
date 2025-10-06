import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/theme_storage.dart';
import 'core/utils/locale_storage.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/app_localizations_delegate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final locale = await LocaleStorage.getLocale();
    setState(() {
      _locale = locale;
    });
  }

  void _changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stress Relief App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.background,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.text),
          bodyMedium: TextStyle(color: AppColors.text),
        ),
      ),
      // Localization config
      locale: _locale,
      supportedLocales: LocaleStorage.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LocalizationTestScreen(onLocaleChange: _changeLocale),
    );
  }
}

/// Test screen để xem localization hoạt động
class LocalizationTestScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  
  const LocalizationTestScreen({
    super.key,
    required this.onLocaleChange,
  });

  @override
  State<LocalizationTestScreen> createState() => _LocalizationTestScreenState();
}

class _LocalizationTestScreenState extends State<LocalizationTestScreen> {
  String _currentTheme = '';
  Locale _currentLocale = const Locale('vi', 'VN');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeId = await ThemeStorage.getThemeId();
    final locale = await LocaleStorage.getLocale();
    setState(() {
      _currentTheme = themeId;
      _currentLocale = locale;
    });
  }

  Future<void> _changeLanguage(Locale locale) async {
    await LocaleStorage.saveLocale(locale);
    setState(() {
      _currentLocale = locale;
    });
    widget.onLocaleChange(locale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Test theme color box
              Container(
                width: 200,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Center(
                  child: Text(
                    l10n.theme,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Test localization strings
              Text(
                l10n.settings,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Show room names
              Text(
                '${l10n.livingRoom} • ${l10n.garden} • ${l10n.aquarium}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
              Text(
                '${l10n.paintingRoom} • ${l10n.musicRoom}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Language switcher
              Text(
                l10n.language,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _changeLanguage(const Locale('vi', 'VN')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentLocale.languageCode == 'vi'
                          ? AppColors.primary
                          : AppColors.background,
                      foregroundColor: _currentLocale.languageCode == 'vi'
                          ? Colors.white
                          : AppColors.text,
                    ),
                    child: const Text('Tiếng Việt'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _changeLanguage(const Locale('en', 'US')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentLocale.languageCode == 'en'
                          ? AppColors.primary
                          : AppColors.background,
                      foregroundColor: _currentLocale.languageCode == 'en'
                          ? Colors.white
                          : AppColors.text,
                    ),
                    child: const Text('English'),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Info
              Text(
                'Theme ID: $_currentTheme',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
              Text(
                '${l10n.language}: ${_currentLocale.languageCode}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}