import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/mixins/main_screen_mixin.dart';
import '../core/utils/sfx_service.dart';
import '../core/widgets/app_header.dart';
import '../core/widgets/main_feature_buttons.dart';
import '../core/widgets/nav_menu_footer.dart';
import '../core/widgets/speech_bubble.dart';
import '../core/providers/scene_provider.dart';
import 'modals/scene_shop_modal.dart';
import 'modals/achievements_modal.dart';
import 'mobile_portrait_tutorial_screen.dart';
import 'package:flutter/foundation.dart';

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

class _MobilePortraitScreenState extends State<MobilePortraitScreen>
    with MainScreenMixin {
  @override
  void initState() {
    super.initState();
    initMainScreen();
  }

  @override
  void dispose() {
    disposeMainScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: (isDebugMode || kDebugMode)
          ? FloatingActionButton(
              mini: true,
              onPressed: () {},
              backgroundColor: isDebugMode ? Colors.deepPurple : Colors.grey,
              child: const Icon(Icons.bug_report, color: Colors.white),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.theme.background,
              context.theme.border,
              context.theme.border,
              context.theme.background,
            ],
            stops: const [0.0, 0.25, 0.75, 1.0],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
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
                  _buildFeatureButtons(),
                  const SizedBox(height: 88),
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
                  onAchievementsPressed: () {
                    SfxService().buttonClick();
                    AchievementsModal.show(context,
                        onNavigate: onAchievementNavigate);
                  },
                  onHelpPressed: () {
                    SfxService().buttonClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MobilePortraitTutorialScreen(
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
                  currentScene: currentScene,
                  onSceneChanged: (scene) {
                    SfxService().pageTransition();
                    setState(() => currentScene = scene);
                    showSceneGreeting(scene);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildSceneWithMascot(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sceneSize = min(screenWidth, 800.0);
    final mascotSize = sceneSize / 2.4;

    return Consumer<SceneProvider>(
      builder: (context, sceneProvider, child) {
        final sceneAssetPath = sceneProvider.getCurrentSceneAsset(currentScene);

        return SizedBox(
          width: sceneSize,
          height: sceneSize,
          child: Stack(
            children: [
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
                            Icon(Icons.image_not_supported,
                                size: 64, color: context.theme.border),
                            const SizedBox(height: 16),
                            Text(
                              currentScene.toString().split('.').last,
                              style: AppTypography.bodyLarge(context,
                                  color: context.theme.border),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              if (currentDialogue != null)
                Positioned(
                  bottom: 20 + (mascotSize * 0.635) + 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: min(sceneSize * 0.7, 300),
                      ),
                      child: SpeechBubble(
                        text: currentDialogue!,
                        tailPosition: BubbleTailPosition.bottom,
                      ),
                    ),
                  ),
                ),

              Positioned(
                bottom: 20,
                left: (sceneSize - mascotSize) / 2,
                child: GestureDetector(
                  onTap: onMascotTapped,
                  child: Image.asset(
                    mascotAssetPath,
                    width: mascotSize,
                    height: mascotSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: mascotSize,
                        height: mascotSize,
                        decoration: BoxDecoration(
                          color: context.theme.secondary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text('🐱',
                            style: TextStyle(fontSize: mascotSize / 2)),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureButtons() {
    return MainFeatureButtons(
        buttons: getFeatureButtonsForScene(currentScene));
  }
}
