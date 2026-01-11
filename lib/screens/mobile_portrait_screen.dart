import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/l10n/app_localizations.dart';
import '../models/scene_models.dart';
import '../core/utils/asset_loader.dart';
import '../core/utils/sfx_service.dart';
import '../core/utils/mascot_dialogue_service.dart';
import '../core/widgets/app_header.dart';
import '../core/widgets/main_feature_buttons.dart';
import '../core/widgets/nav_menu_footer.dart';
import '../core/widgets/speech_bubble.dart';
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
import 'modals/breathing_exercise_modal.dart';
import 'modals/sleep_guide_modal.dart';
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
  bool _isDebugMode = false;

  // Mascot dialogue state
  String? _currentDialogue;
  Timer? _dialogueTimer;
  final _dialogueService = MascotDialogueService();

  @override
  void initState() {
    super.initState();
    _checkDebugMode();
  }

  @override
  void dispose() {
    _dialogueTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkDebugMode() async {
    final authService = AuthService();
    final isDebug = await authService.isDebugMode;
    if (mounted) {
      setState(() {
        _isDebugMode = isDebug;
      });
    }
  }

  // Mascot dialogue methods
  void _showSceneGreeting(SceneType scene) {
    final l10n = AppLocalizations.of(context);
    final dialogue = _dialogueService.getSceneGreeting(scene, l10n);
    final expression = _dialogueService.getRandomExpression();
    _showDialogue(dialogue, expression);
  }

  void _showClickDialogue() {
    final l10n = AppLocalizations.of(context);
    final dialogue = _dialogueService.getClickDialogue(_currentScene, l10n);
    final expression = _dialogueService.getRandomExpression();
    _showDialogue(dialogue, expression);
  }

  void _showDialogue(String text, MascotExpression expression) {
    _cancelDialogueTimer();
    setState(() {
      _currentDialogue = text;
      _currentExpression = expression;
    });
    _dialogueTimer = Timer(const Duration(milliseconds: 3500), _hideDialogue);
  }

  void _hideDialogue() {
    setState(() {
      _currentDialogue = null;
      _currentExpression = MascotExpression.idle;
    });
  }

  void _cancelDialogueTimer() {
    _dialogueTimer?.cancel();
    _dialogueTimer = null;
  }

  void _onMascotTapped() {
    SfxService().buttonClick();
    _showClickDialogue();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Debug FAB (visual indicator only - shown in debug mode OR Flutter debug build)
      floatingActionButton: (_isDebugMode || kDebugMode) ? FloatingActionButton(
        mini: true,
        onPressed: () {}, // Empty callback - just a visual indicator
        backgroundColor: _isDebugMode ? Colors.deepPurple : Colors.grey,
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
                    _showSceneGreeting(scene);
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
                              style: AppTypography.bodyLarge(context,
                                color: context.theme.text.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Speech bubble (above mascot)
              if (_currentDialogue != null)
                Positioned(
                  bottom: 20 + (mascotSize * 0.635) + 30, // Above visible mascot part
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: min(sceneSize * 0.7, 300),
                      ),
                      child: SpeechBubble(
                        text: _currentDialogue!,
                        tailPosition: BubbleTailPosition.bottom,
                      ),
                    ),
                  ),
                ),

              // Mascot (center-bottom) with tap handler
              Positioned(
                bottom: 20,
                left: (sceneSize - mascotSize) / 2,
                child: GestureDetector(
                  onTap: _onMascotTapped,
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
          FeatureButton(
            icon: Icons.air,
            label: l10n.breathing,
            onPressed: () {
              SfxService().buttonClick();
              BreathingExerciseModal.show(context);
            },
          ),
          FeatureButton(
            icon: Icons.bedtime,
            label: l10n.sleep,
            onPressed: () {
              SfxService().buttonClick();
              SleepGuideModal.show(context);
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