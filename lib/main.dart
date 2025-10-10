import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stress_relief_app/screens/component_showcase_screen.dart';
import 'core/constants/app_colors.dart';
import 'models/scene_models.dart';
import 'core/utils/theme_storage.dart';
import 'core/utils/locale_storage.dart';
import 'core/utils/asset_loader.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/app_localizations_delegate.dart';
import 'core/utils/data_manager.dart';
import 'package:stress_relief_app/screens/mobile_portrait_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dataManager = DataManager();
  await dataManager.initialize();

  runApp(MyApp());
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
      // home: const ComponentShowcaseScreen(), // ← Test UI Components
      home: const MobilePortraitScreen(), // ← Test Mobile Layout
    );
  }
}

/// Test screen cho Asset Loading
class AssetTestScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  
  const AssetTestScreen({
    super.key,
    required this.onLocaleChange,
  });

  @override
  State<AssetTestScreen> createState() => _AssetTestScreenState();
}

class _AssetTestScreenState extends State<AssetTestScreen> {
  SceneType _currentScene = SceneType.livingRoom;
  SceneSet _currentSet = SceneSet.defaultSet;
  MascotExpression _currentExpression = MascotExpression.idle;
  
  bool _isPreloading = false;
  bool _hasPreloaded = false; // Track để không preload nhiều lần

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Chỉ preload 1 lần
    if (!_hasPreloaded) {
      _preloadAssets();
      _hasPreloaded = true;
    }
  }

  Future<void> _preloadAssets() async {
    setState(() => _isPreloading = true);
    await AssetLoader.preloadAll(context);
    setState(() => _isPreloading = false);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              '🎨 Asset Loader Test',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            if (_isPreloading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Scene Test
            _buildSectionCard(
              title: '🏠 Scene Backgrounds',
              child: Column(
                children: [
                  // Scene type selector
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SceneType.values.map((type) {
                      final isSelected = _currentScene == type;
                      return ChoiceChip(
                        label: Text(_getSceneName(type, l10n)),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _currentScene = type);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.text,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Scene preview
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        AssetLoader.getSceneAsset(_currentSet, _currentScene),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'Placeholder: ${_getSceneName(_currentScene, l10n)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Path info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Path: ${AssetLoader.getSceneAsset(_currentSet, _currentScene)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Mascot Test
            _buildSectionCard(
              title: '🐱 Mascot Expressions',
              child: Column(
                children: [
                  // Expression selector
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MascotExpression.values.map((expr) {
                      final isSelected = _currentExpression == expr;
                      return ChoiceChip(
                        label: Text(_getExpressionName(expr)),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _currentExpression = expr);
                        },
                        selectedColor: AppColors.secondary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.text,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mascot preview
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondary, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        AssetLoader.getMascotAsset(_currentExpression),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getExpressionEmoji(_currentExpression),
                                  style: const TextStyle(fontSize: 80),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getExpressionName(_currentExpression),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Path info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Path: ${AssetLoader.getMascotAsset(_currentExpression)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
  
  String _getSceneName(SceneType type, AppLocalizations l10n) {
    switch (type) {
      case SceneType.livingRoom:
        return l10n.livingRoom;
      case SceneType.garden:
        return l10n.garden;
      case SceneType.aquarium:
        return l10n.aquarium;
      case SceneType.paintingRoom:
        return l10n.paintingRoom;
      case SceneType.musicRoom:
        return l10n.musicRoom;
    }
  }
  
  String _getExpressionName(MascotExpression expr) {
    switch (expr) {
      case MascotExpression.idle:
        return 'Nghỉ';
      case MascotExpression.happy:
        return 'Vui';
      case MascotExpression.calm:
        return 'Thư giãn';
      case MascotExpression.sad:
        return 'Buồn';
      case MascotExpression.sleepy:
        return 'Buồn ngủ';
      case MascotExpression.surprised:
        return 'Ngạc nhiên';
    }
  }
  
  String _getExpressionEmoji(MascotExpression expr) {
    switch (expr) {
      case MascotExpression.idle:
        return '😐';
      case MascotExpression.happy:
        return '😊';
      case MascotExpression.calm:
        return '😌';
      case MascotExpression.sad:
        return '😢';
      case MascotExpression.sleepy:
        return '😴';
      case MascotExpression.surprised:
        return '😲';
    }
  }
}