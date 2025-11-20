import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
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
    return MaterialApp(
      title: 'Stress Relief App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: context.theme.primary,
          secondary: context.theme.secondary,
          surface: context.theme.background,
          background: context.theme.background,
        ),
        scaffoldBackgroundColor: context.theme.background,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: context.theme.text),
          bodyMedium: TextStyle(color: context.theme.text),
        ),
      ),
      // Localization
      locale: locale, // ← ĐỔI TỪ _locale THÀNH locale
      supportedLocales: LocaleStorage.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Bắt đầu với splash screen
      home: const MobilePortraitSplashScreen(),
    );
  }
}