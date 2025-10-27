import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/scene_models.dart';
import '../core/utils/asset_loader.dart';
import '../core/utils/sfx_service.dart';
import '../core/widgets/app_header.dart';
import '../core/widgets/main_feature_buttons.dart';
import '../core/widgets/nav_menu_footer.dart';
import 'modals/schedule_task_modal.dart';
import 'modals/emotion_diary_modal.dart';
import 'modals/garden_modal.dart';
import 'modals/aquarium_modal.dart';
import 'modals/drawing_modal.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    _showToast('Scene Shop');
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

    return SizedBox(
      width: sceneSize,
      height: sceneSize,
      child: Stack(
        children: [
          // Scene background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                AssetLoader.getSceneAsset(SceneSet.defaultSet, _currentScene),
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
  }

  Widget _buildFeatureButtons() {
    // Feature buttons change based on scene
    final buttons = _getFeatureButtonsForScene(_currentScene);
    
    return MainFeatureButtons(buttons: buttons);
  }

  List<FeatureButton> _getFeatureButtonsForScene(SceneType scene) {
    switch (scene) {
      case SceneType.livingRoom:
        return [
          FeatureButton(
            icon: Icons.calendar_today,
            label: 'Tasks',
            onPressed: () {
              SfxService().buttonClick();
              ScheduleTaskModal.show(context);
            },
          ),
          FeatureButton(
            icon: Icons.mood,
            label: 'Mood',
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
            label: 'Garden',
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
            label: 'Aquarium',
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
            label: 'Draw',
            onPressed: () {
              SfxService().buttonClick();
              DrawingModal.show(context);
            },
          ),
          FeatureButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            onPressed: () {
              SfxService().buttonClick();
              _showToast('Gallery');
            },
          ),
        ];
      
      case SceneType.musicRoom:
        return [
          FeatureButton(
            icon: Icons.play_circle,
            label: 'Compose',
            onPressed: () {
              SfxService().buttonClick();
              _showToast('Compose Music');
            },
          ),
          FeatureButton(
            icon: Icons.library_music,
            label: 'Library',
            onPressed: () {
              SfxService().buttonClick();
              _showToast('Music Library');
            },
          ),
        ];
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}