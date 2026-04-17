import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/score_provider.dart';
import '../providers/achievement_provider.dart';
import '../utils/asset_loader.dart';
import '../utils/sfx_service.dart';
import '../utils/mascot_dialogue_service.dart';
import '../utils/data_manager.dart';
import '../utils/sleep_guide_service.dart';
import '../utils/auth_service.dart';
import '../widgets/achievement_popup.dart';
import '../../models/scene_models.dart';
import '../widgets/main_feature_buttons.dart' show FeatureButton;
import '../../screens/modals/schedule_task_modal.dart';
import '../../screens/modals/emotion_diary_modal.dart';
import '../../screens/modals/garden_modal.dart';
import '../../screens/modals/rock_balancing_lobby_modal.dart';
import '../../screens/modals/firefly_lobby_modal.dart';
import '../../screens/modals/aquarium_modal.dart';
import '../../screens/modals/paper_ship_lobby_modal.dart';
import '../../screens/modals/drawing_modal.dart';
import '../../screens/modals/gallery_modal.dart';
import '../../screens/modals/composing_modal.dart';
import '../../screens/modals/library_modal.dart';
import '../../screens/modals/breathing_exercise_modal.dart';
import '../../screens/modals/sleep_guide_modal.dart';

/// Shared state and logic for main screens (portrait and landscape).
///
/// No AnimationController — dialogue uses Timer only, so no TickerProvider needed.
mixin MainScreenMixin<T extends StatefulWidget> on State<T> {
  SceneType currentScene = SceneType.livingRoom;
  MascotExpression currentExpression = MascotExpression.idle;
  bool isDebugMode = false;
  String? currentDialogue;
  Timer? dialogueTimer;
  final dialogueService = MascotDialogueService();

  MascotExpression get defaultExpression {
    final settings = DataManager().sleepSettings;
    return SleepGuideService().isSleepTime(settings)
        ? MascotExpression.sleepy
        : MascotExpression.idle;
  }

  void initMainScreen() {
    checkDebugMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runRetroactiveCheck();
      if (mounted) setState(() => currentExpression = defaultExpression);
    });
  }

  void disposeMainScreen() {
    dialogueTimer?.cancel();
  }

  Future<void> runRetroactiveCheck() async {
    if (!mounted) return;
    final score = context.read<ScoreProvider>();
    // Re-sync ScoreProvider from Hive before any achievement checks so that
    // a post-delete / post-logout state is always reflected correctly.
    score.refresh();
    final achProvider = context.read<AchievementProvider>();
    await achProvider.retroactiveCheck(score);
    if (!mounted) return;

    final progress = achProvider.progress;
    if (!progress.isUnlocked('first_steps')) {
      final newly = await achProvider.onFirstLaunch(score);
      if (newly.isNotEmpty && mounted) AchievementPopup.show(context, newly);
    }

    if (!mounted) return;
    final appOpenedAchs = await achProvider.onAppOpened(score);
    if (appOpenedAchs.isNotEmpty && mounted) {
      AchievementPopup.show(context, appOpenedAchs);
    }
  }

  Future<void> checkDebugMode() async {
    final authService = AuthService();
    final debug = await authService.isDebugMode;
    if (mounted) setState(() => isDebugMode = debug);
  }

  void showSceneGreeting(SceneType scene) {
    final l10n = AppLocalizations.of(context);
    final settings = DataManager().sleepSettings;
    if (SleepGuideService().isSleepTime(settings)) {
      final dialogue = dialogueService.getSleepDialogue(l10n);
      showDialogue(dialogue, MascotExpression.sleepy);
      return;
    }
    final dialogue = dialogueService.getSceneGreeting(scene, l10n);
    final expression = dialogueService.getRandomExpression();
    showDialogue(dialogue, expression);
  }

  void showClickDialogue() {
    final l10n = AppLocalizations.of(context);
    final settings = DataManager().sleepSettings;
    if (SleepGuideService().isSleepTime(settings)) {
      final dialogue = dialogueService.getSleepDialogue(l10n);
      showDialogue(dialogue, MascotExpression.sleepy);
      return;
    }
    final dialogue = dialogueService.getClickDialogue(currentScene, l10n);
    final expression = dialogueService.getRandomExpression();
    showDialogue(dialogue, expression);
  }

  void showDialogue(String text, MascotExpression expression) {
    cancelDialogueTimer();
    setState(() {
      currentDialogue = text;
      currentExpression = expression;
    });
    dialogueTimer = Timer(const Duration(milliseconds: 3500), hideDialogue);
  }

  void hideDialogue() {
    setState(() {
      currentDialogue = null;
      currentExpression = defaultExpression;
    });
  }

  void cancelDialogueTimer() {
    dialogueTimer?.cancel();
    dialogueTimer = null;
  }

  void onMascotTapped() {
    SfxService().buttonClick();
    showClickDialogue();
  }

  /// Callback for AchievementsModal navigation — navigate to feature by ID.
  void onAchievementNavigate(String featureId) {
    switch (featureId) {
      case 'schedule': ScheduleTaskModal.show(context);
      case 'diary': EmotionDiaryModal.show(context);
      case 'breathing': BreathingExerciseModal.show(context);
      case 'sleep': SleepGuideModal.show(context);
      case 'garden': GardenModal.show(context);
      case 'aquarium': AquariumModal.show(context);
      case 'painting': DrawingModal.show(context);
      case 'music': ComposingModal.show(context);
    }
  }

  List<FeatureButton> getFeatureButtonsForScene(SceneType scene) {
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
          FeatureButton(
            icon: Icons.terrain,
            label: l10n.rockBalancing,
            onPressed: () {
              SfxService().buttonClick();
              RockBalancingLobbyModal.show(context);
            },
          ),
          FeatureButton(
            icon: Icons.wb_twilight,
            label: l10n.fireflyCatching,
            onPressed: () {
              SfxService().buttonClick();
              FireflyLobbyModal.show(context);
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
          FeatureButton(
            icon: Icons.sailing,
            label: l10n.paperShip,
            onPressed: () {
              SfxService().buttonClick();
              PaperShipLobbyModal.show(context);
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
              GalleryModal.show(context, onPaintingSelected: () {});
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
              LibraryModal.show(context, onTrackSelected: () {});
            },
          ),
        ];
    }
  }

  /// Scene navigation icon — matches NavMenuFooter._getSceneIcon()
  IconData sceneIcon(SceneType scene) {
    switch (scene) {
      case SceneType.livingRoom: return Icons.home;
      case SceneType.garden: return Icons.local_florist;
      case SceneType.aquarium: return Icons.water;
      case SceneType.paintingRoom: return Icons.palette;
      case SceneType.musicRoom: return Icons.music_note;
    }
  }

  /// Scene navigation label — uses l10n for consistency
  String sceneLabel(SceneType scene) {
    final l10n = AppLocalizations.of(context);
    switch (scene) {
      case SceneType.livingRoom: return l10n.livingRoom;
      case SceneType.garden: return l10n.garden;
      case SceneType.aquarium: return l10n.aquarium;
      case SceneType.paintingRoom: return l10n.paintingRoom;
      case SceneType.musicRoom: return l10n.musicRoom;
    }
  }

  /// Mascot image path for current expression.
  String get mascotAssetPath => AssetLoader.getMascotAsset(currentExpression);
}
