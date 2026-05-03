import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/mixins/main_screen_mixin.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/mascot_sprite_widget.dart';
import '../core/widgets/speech_bubble.dart';
import '../core/providers/scene_provider.dart';
import '../core/providers/score_provider.dart';
import '../core/utils/sfx_service.dart';
import '../core/l10n/app_localizations.dart';
import '../models/scene_models.dart';
import 'modals/profile_modal.dart';
import 'modals/scene_shop_modal.dart';
import 'modals/achievements_modal.dart';
import 'modals/settings_modal.dart';
import 'mobile_portrait_tutorial_screen.dart';

/// Desktop Landscape Layout Screen
///
/// Structure:
/// - Left: Square scene panel (full height), flush to left edge
/// - Right: Sidebar with coin display, action buttons, feature buttons, scene nav
/// - Keyboard shortcuts 1–5 switch scenes
class DesktopLandscapeScreen extends StatefulWidget {
  const DesktopLandscapeScreen({super.key});

  @override
  State<DesktopLandscapeScreen> createState() => _DesktopLandscapeScreenState();
}

class _DesktopLandscapeScreenState extends State<DesktopLandscapeScreen>
    with MainScreenMixin {
  // Scene nav order matches keyboard shortcuts 1–5
  static const List<SceneType> _sceneOrder = [
    SceneType.livingRoom,   // 1
    SceneType.garden,       // 2
    SceneType.aquarium,     // 3
    SceneType.paintingRoom, // 4
    SceneType.musicRoom,    // 5
  ];

  // Key → SceneType mapping for shortcuts 1–5
  SceneType? _keyToScene(LogicalKeyboardKey key) {
    switch (key) {
      case LogicalKeyboardKey.digit1:
      case LogicalKeyboardKey.numpad1:
        return SceneType.livingRoom;
      case LogicalKeyboardKey.digit2:
      case LogicalKeyboardKey.numpad2:
        return SceneType.garden;
      case LogicalKeyboardKey.digit3:
      case LogicalKeyboardKey.numpad3:
        return SceneType.aquarium;
      case LogicalKeyboardKey.digit4:
      case LogicalKeyboardKey.numpad4:
        return SceneType.paintingRoom;
      case LogicalKeyboardKey.digit5:
      case LogicalKeyboardKey.numpad5:
        return SceneType.musicRoom;
      default:
        return null;
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isModalOpen = ModalRoute.of(context)?.isCurrent == false;

    // Esc: close modal if open, otherwise open Settings
    if (key == LogicalKeyboardKey.escape) {
      if (isModalOpen) {
        Navigator.of(context).pop();
      } else {
        SfxService().buttonClick();
        SettingsModal.show(context);
      }
      return KeyEventResult.handled;
    }

    // Remaining shortcuts only fire when no modal is open
    if (isModalOpen) return KeyEventResult.ignored;

    // 1–5: switch scene
    final scene = _keyToScene(key);
    if (scene != null) {
      SfxService().pageTransition();
      setState(() => currentScene = scene);
      showSceneGreeting(scene);
      return KeyEventResult.handled;
    }

    // S: Scene Shop
    if (key == LogicalKeyboardKey.keyS) {
      SfxService().buttonClick();
      SceneShopModal.show(context);
      return KeyEventResult.handled;
    }

    // P: Profile
    if (key == LogicalKeyboardKey.keyP) {
      SfxService().buttonClick();
      ProfileModal.show(context);
      return KeyEventResult.handled;
    }

    // H or F1: Tutorial
    if (key == LogicalKeyboardKey.keyH ||
        key == LogicalKeyboardKey.f1) {
      SfxService().buttonClick();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MobilePortraitTutorialScreen(
            isFromMainScreen: true,
          ),
        ),
      );
      return KeyEventResult.handled;
    }

    // A: Achievements
    if (key == LogicalKeyboardKey.keyA) {
      SfxService().buttonClick();
      AchievementsModal.show(context, onNavigate: onAchievementNavigate);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

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
    final theme = context.theme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              theme.background,
              theme.border,
              theme.border,
              theme.background,
            ],
            stops: const [0.0, 0.40, 0.60, 1.0],
          ),
        ),
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) => _handleKeyEvent(event),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const sidebarWidth = 240.0;
              final sceneSize = min(
                constraints.maxHeight,
                constraints.maxWidth - sidebarWidth,
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left margin (equal spacing)
                  const Spacer(),
                  // Scene panel (square, visual main)
                  SizedBox(
                    width: sceneSize,
                    child: Center(
                      child: _buildScenePanel(context, sceneSize),
                    ),
                  ),
                  // Middle gap (equal spacing)
                  const Spacer(),
                  // Sidebar (fixed 240px)
                  SizedBox(
                    width: sidebarWidth,
                    child: _buildSidebar(context),
                  ),
                  // Right margin (equal spacing)
                  const Spacer(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Scene panel ─────────────────────────────────────────────────────────────

  Widget _buildScenePanel(BuildContext context, double sceneSize) {
    final mascotSize = sceneSize / 2.4;

    return Consumer<SceneProvider>(
      builder: (context, sceneProvider, _) {
        final sceneAssetPath = sceneProvider.getCurrentSceneAsset(currentScene);

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
                    sceneAssetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, _) => Container(
                      color: context.theme.border,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              size: 64, color: context.theme.primary),
                          const SizedBox(height: 16),
                          Text(
                            currentScene.toString().split('.').last,
                            style: AppTypography.bodyLarge(context,
                                color: context.theme.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Speech bubble
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

              // Mascot
              Positioned(
                bottom: 20,
                left: (sceneSize - mascotSize) / 2,
                child: GestureDetector(
                  onTap: onMascotTapped,
                  child: MascotSpriteWidget(
                    expression: currentExpression,
                    size: mascotSize,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Sidebar ─────────────────────────────────────────────────────────────────

  Widget _buildSidebar(BuildContext context) {
    final theme = context.theme;

    return Container(
      color: theme.border,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top: coin + scene shop + achievements + menu ────────────────
            _buildCoinDisplay(context),
            Divider(height: 2, thickness: 2, color: theme.primary),
            _buildTopGroup(context),
            Divider(height: 2, thickness: 2, color: theme.primary),
            // ── Middle: feature buttons (centered) ──────────────────────────
            const Spacer(),
            _buildFeatureButtonsSection(context),
            const Spacer(),
            // ── Bottom: scene nav ────────────────────────────────────────────
            Divider(height: 2, thickness: 2, color: theme.primary),
            _buildSceneNavButtons(context),
            if (isDebugMode || kDebugMode) _buildDebugIndicator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinDisplay(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    return Consumer<ScoreProvider>(
      builder: (context, scoreProvider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: theme.primary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monetization_on, size: 18, color: theme.background),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${l10n.points}: ${scoreProvider.currentPoints}',
                  style: AppTypography.labelLarge(context,
                      color: theme.background, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopGroup(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            icon: Icons.landscape,
            label: l10n.sceneShop,
            width: double.infinity,
            onPressed: () {
              SfxService().buttonClick();
              SceneShopModal.show(context);
            },
          ),
          const SizedBox(height: 8),
          AppButton(
            icon: Icons.emoji_events_outlined,
            label: l10n.achievements,
            width: double.infinity,
            onPressed: () {
              SfxService().buttonClick();
              AchievementsModal.show(context, onNavigate: onAchievementNavigate);
            },
          ),
          const SizedBox(height: 8),
          // Menu dropdown: profile / tutorial / settings
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                ProfileModal.show(context);
              } else if (value == 'guide') {
                SfxService().buttonClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MobilePortraitTutorialScreen(
                      isFromMainScreen: true,
                    ),
                  ),
                );
              } else if (value == 'settings') {
                SfxService().buttonClick();
                SettingsModal.show(context);
              }
            },
            color: theme.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 4),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(children: [
                  Icon(Icons.account_circle_outlined, color: theme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.menuProfile, style: AppTypography.bodyLarge(context, color: theme.text)),
                ]),
              ),
              PopupMenuItem<String>(
                value: 'guide',
                child: Row(children: [
                  Icon(Icons.help_outline, color: theme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.tutorialTitle, style: AppTypography.bodyLarge(context, color: theme.text)),
                ]),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(children: [
                  Icon(Icons.settings, color: theme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.settings, style: AppTypography.bodyLarge(context, color: theme.text)),
                ]),
              ),
            ],
            child: Material(
              color: theme.primary,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu, size: 20, color: theme.background),
                    const SizedBox(width: 8),
                    Text(
                      l10n.menu,
                      style: AppTypography.labelLarge(context,
                          color: theme.background, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButtonsSection(BuildContext context) {
    final buttons = getFeatureButtonsForScene(currentScene);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons
            .map((btn) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppButton(
                    icon: btn.icon,
                    label: btn.label,
                    width: double.infinity,
                    onPressed: btn.onPressed,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSceneNavButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _sceneOrder
            .map((scene) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppButton(
                    icon: sceneIcon(scene),
                    label: sceneLabel(scene),
                    isActive: scene == currentScene,
                    width: double.infinity,
                    onPressed: () {
                      SfxService().pageTransition();
                      setState(() => currentScene = scene);
                      showSceneGreeting(scene);
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDebugIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: isDebugMode ? Colors.deepPurple : Colors.grey,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          child: const Icon(Icons.bug_report, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
