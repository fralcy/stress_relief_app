import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_shapes.dart';
import 'core/constants/app_typography.dart';
import 'core/utils/locale_storage.dart';
import 'core/l10n/app_localizations_delegate.dart';
import 'core/utils/data_manager.dart';
import 'core/utils/bgm_service.dart';
import 'core/utils/sfx_service.dart';
import 'core/utils/notifier.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/score_provider.dart';
import 'core/providers/scene_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import splash screen
import 'screens/mobile_portrait_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase FIRST (AuthService depends on it)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Init DataManager (Hive) AFTER Firebase
  await DataManager().initialize();

  // Init BGM Service
  await BgmService().initialize();
  // Init SFX Service
  await SfxService().initialize();

  // Init Notifier
  if (!kIsWeb) {
    await Notifier.initialize();
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ScoreProvider()),
        ChangeNotifierProvider(create: (_) => SceneProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

   @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BgmService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        BgmService().pause();
        break;
      case AppLifecycleState.resumed:
        BgmService().resume();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().currentLocale;
    final appTheme = context.watch<ThemeProvider>().currentTheme;

    return MaterialApp(
      title: 'PeacePal - Stress Relief App',

      // Material 3 Theme with full M3 support
      theme: ThemeData(
        useMaterial3: true,

        // M3 ColorScheme generated from AppTheme with semantic colors
        colorScheme: appTheme.toColorScheme(),

        // M3 Typography mapped from AppTypography
        textTheme: AppTypography.toTextTheme(context, color: appTheme.text),

        // Scaffold background
        scaffoldBackgroundColor: appTheme.background,

        // M3 Card theme
        cardTheme: CardThemeData(
          elevation: 0,
          shape: AppShapes.large,
          shadowColor: Colors.black.withValues(alpha: 0.05),
        ),

        // M3 Elevated Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: AppShapes.medium,
          ),
        ),

        // M3 Filled Button theme
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: AppShapes.medium,
          ),
        ),

        // M3 Outlined Button theme
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: AppShapes.medium,
          ),
        ),

        // M3 Text Button theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: AppShapes.medium,
          ),
        ),

        // M3 Input Decoration theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: AppShapes.small.borderRadius as BorderRadius,
          ),
          filled: true,
        ),

        // M3 Slider theme (maintain WCAG AA compliance)
        sliderTheme: const SliderThemeData(
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 24), // 48dp diameter for WCAG AA
          overlayShape: RoundSliderOverlayShape(overlayRadius: 28),
        ),

        // M3 Dialog theme
        dialogTheme: DialogThemeData(
          shape: AppShapes.extraLarge,
          elevation: 3,
        ),

        // M3 Bottom Sheet theme
        bottomSheetTheme: BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: (AppShapes.extraLarge.borderRadius as BorderRadius).topLeft,
            ),
          ),
        ),
      ),

      // Localization
      locale: locale,
      supportedLocales: LocaleStorage.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Start with splash screen
      home: const MobilePortraitSplashScreen(),
    );
  }
}