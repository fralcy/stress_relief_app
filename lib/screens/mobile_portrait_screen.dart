import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/l10n/app_localizations.dart';
import '../models/scene_models.dart';
import '../core/utils/asset_loader.dart';
import '../core/utils/sfx_service.dart';
import '../core/widgets/app_header.dart';
import '../core/widgets/main_feature_buttons.dart';
import '../core/widgets/nav_menu_footer.dart';
import '../core/providers/scene_provider.dart';
import 'modals/scene_shop_modal.dart';
import 'modals/schedule_task_modal.dart';
import 'modals/emotion_diary_modal.dart';
import 'modals/garden_modal.dart';
import 'modals/aquarium_modal.dart';
import 'modals/drawing_modal.dart';
import 'modals/gallery_modal.dart';
import 'modals/composing_modal.dart';
import 'modals/library_modal.dart';
import 'mobile_portrait_tutorial_screen.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/auth_service.dart';
/// Mobile Portrait Layout Screen
/// 
/// Structure:
/// - Gradient background (primary center → background edges)
/// - Scene (square, full width, centered vertically)
/// - Mascot (inside scene, center-bottom)
/// - Header (top, transparent)
/// - Feature buttons (below scene)
/// - Nav footer (bottom, transparent)
class MobilePortraitScreen extends StatefulWidget {
  const MobilePortraitScreen({super.key});

  @override
  State<MobilePortraitScreen> createState() => _MobilePortraitScreenState();
}

class _MobilePortraitScreenState extends State<MobilePortraitScreen> {
  SceneType _currentScene = SceneType.livingRoom;
  MascotExpression _currentExpression = MascotExpression.idle;

  // Debug functionality
  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Navigation Debug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Expected Flow:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('🔄 First Launch:\nSplash → Welcome → Tutorial → Login → Main'),
            const Text('👤 Guest Mode: Splash → Main'),
            const Text('🔐 Logged In: Splash → Main'),
            const SizedBox(height: 16),
            const Text('Test Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _resetToFirstLaunch(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Reset to First Launch'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _setGuestMode(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Set Guest Mode'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToFirstLaunch(BuildContext context) async {
    final authService = AuthService();
    await authService.clearAuthFlags();
    
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to first launch. Restart app to test flow.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _setGuestMode(BuildContext context) async {
    final authService = AuthService();
    await authService.setGuestMode();
    
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set to guest mode. Restart app to test flow.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Debug FAB (only in debug mode)
      floatingActionButton: kDebugMode ? FloatingActionButton(
        mini: true,
        onPressed: () => _showDebugDialog(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.bug_report, color: Colors.white),
      ) : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.theme.background,
              context.theme.primary.withOpacity(0.3),
              context.theme.primary.withOpacity(0.3),
              context.theme.background,
            ],
            stops: const [0.0, 0.25, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content: Scene + Mascot + Feature Buttons
              Column(
                children: [
                  const SizedBox(height: 68),
                  Expanded(
                    child: Center(
                      child: _buildSceneWithMascot(context),
                    ),
                  ),
                  
                  // Feature buttons (changes per scene)
                  _buildFeatureButtons(),
                  
                  const SizedBox(height: 88), // Space for nav footer
                ],
              ),
              
              // Header (overlay)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppHeader(
                  onSceneShopPressed: () {
                    SfxService().buttonClick();
                    SceneShopModal.show(context);
                  },
                  onHelpPressed: () {
                    SfxService().buttonClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MobilePortraitTutorialScreen(
                          isFromMainScreen: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Nav Footer (overlay)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: NavMenuFooter(
                  currentScene: _currentScene,
                  onSceneChanged: (scene) {
                    SfxService().pageTransition();
                    setState(() => _currentScene = scene);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSceneWithMascot(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sceneSize = screenWidth;
    final mascotSize = sceneSize / 2.4;

    return Consumer<SceneProvider>(
      builder: (context, sceneProvider, child) {
        // Get current scene asset path dynamically from provider
        final sceneAssetPath = sceneProvider.getCurrentSceneAsset(_currentScene);
        
        return SizedBox(
          width: sceneSize,
          height: sceneSize,
          child: Stack(
            children: [
              // Scene background - sử dụng dynamic asset từ provider
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    sceneAssetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: context.theme.border,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: context.theme.text.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentScene.toString().split('.').last,
                              style: TextStyle(
                                color: context.theme.text.withOpacity(0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Mascot (center-bottom)
              Positioned(
                bottom: 20,
                left: (sceneSize - mascotSize) / 2,
                child: Image.asset(
                  AssetLoader.getMascotAsset(_currentExpression),
                  width: mascotSize,
                  height: mascotSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: mascotSize,
                      height: mascotSize,
                      decoration: BoxDecoration(
                        color: context.theme.secondary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '🐱',
                        style: TextStyle(fontSize: mascotSize / 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureButtons() {
    // Feature buttons change based on scene
    final buttons = _getFeatureButtonsForScene(_currentScene);
    
    return MainFeatureButtons(buttons: buttons);
  }

  List<FeatureButton> _getFeatureButtonsForScene(SceneType scene) {
    final l10n = AppLocalizations.of(context);
    
    switch (scene) {
      case SceneType.livingRoom:
        return [
          FeatureButton(
            icon: Icons.calendar_today,
            label: l10n.tasks,
            onPressed: () {
              SfxService().buttonClick();
              ScheduleTaskModal.show(context);
            },
          ),
          FeatureButton(
            icon: Icons.mood,
            label: l10n.mood,
            onPressed: () {
              SfxService().buttonClick();
              EmotionDiaryModal.show(context);
            },
          ),
        ];
      
      case SceneType.garden:
        return [
          FeatureButton(
            icon: Icons.agriculture,
            label: l10n.garden,
            onPressed: () {
              SfxService().buttonClick();
              GardenModal.show(context);
            },
          ),
        ];
      
      case SceneType.aquarium:
        return [
          FeatureButton(
            icon: Icons.food_bank,
            label: l10n.aquarium,
            onPressed: () {
              SfxService().buttonClick();
              AquariumModal.show(context);
            },
          ),
        ];
      
      case SceneType.paintingRoom:
        return [
          FeatureButton(
            icon: Icons.create,
            label: l10n.draw,
            onPressed: () {
              SfxService().buttonClick();
              DrawingModal.show(context);
            },
          ),
          FeatureButton(
            icon: Icons.photo_library,
            label: l10n.gallery,
            onPressed: () {
              SfxService().buttonClick();
              GalleryModal.show(
                context,
                onPaintingSelected: () {},
              );
            },
          ),
        ];
      
      case SceneType.musicRoom:
        return [
          FeatureButton(
            icon: Icons.play_circle,
            label: l10n.compose,
            onPressed: () {
              SfxService().buttonClick();
              ComposingModal.show(context);
            },
          ),
          FeatureButton(
            icon: Icons.library_music,
            label: l10n.library,
            onPressed: () {
              SfxService().buttonClick();
              LibraryModal.show(
                context,
                onTrackSelected: () {},
              );
            },
          ),
        ];
    }
  }


}