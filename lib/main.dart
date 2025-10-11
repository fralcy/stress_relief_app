import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/locale_storage.dart';
import 'core/l10n/app_localizations_delegate.dart';
import 'core/utils/data_manager.dart';
import 'core/utils/notifier.dart';

// Import test screens
import 'screens/notifier_test_screen.dart';
import 'screens/asset_test_screen.dart';
import 'screens/component_showcase_screen.dart';
import 'screens/mobile_portrait_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Init DataManager (Hive)
  await DataManager().initialize();
  
  // Init Notifier
  if (!kIsWeb) {
    await Notifier.initialize();
  }
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

  void _loadLocale() {
    final locale = LocaleStorage.getLocale();
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
      // Localization
      locale: _locale,
      supportedLocales: LocaleStorage.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Choose which screen to test
      home: const TestMenuScreen(),
    );
  }
}

/// Menu để chọn test screen nào
class TestMenuScreen extends StatelessWidget {
  const TestMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Menu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Select a test screen:',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildTestCard(
            context,
            title: '🔔 Notifier Test',
            description: 'Test notification scheduling',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotifierTestScreen()),
            ),
          ),
          
          _buildTestCard(
            context,
            title: '🎨 Asset Test',
            description: 'Test asset loading and preview',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetTestScreen()),
            ),
          ),
          
          _buildTestCard(
            context,
            title: '🧩 Component Showcase',
            description: 'Test UI components',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ComponentShowcaseScreen()),
            ),
          ),
          
          _buildTestCard(
            context,
            title: '📱 Mobile Layout',
            description: 'Test mobile portrait screen',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MobilePortraitScreen()),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}