import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tutorial_overlay/flutter_tutorial_overlay.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/fish_config.dart';
import '../../core/utils/asset_loader.dart';
import '../../core/utils/aquarium_service.dart';
import '../../core/utils/auth_service.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/providers/score_provider.dart';
import '../../core/providers/achievement_provider.dart';
import '../../core/widgets/achievement_popup.dart';
import '../../models/aquarium_progress.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/floating_label_anim.dart';
import '../../core/l10n/app_localizations.dart';

/// Modal mini-game nuôi cá
class AquariumModal extends StatefulWidget {
  const AquariumModal({super.key});

  @override
  State<AquariumModal> createState() => _AquariumModalState();

  static Future<void> show(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (size.width >= 720 && size.width > size.height && size.height >= 600) {
      return _showLandscape(context);
    }
    final l10n = AppLocalizations.of(context);
    final modalKey = GlobalKey<_AquariumModalState>();
    return AppModal.show(
      context: context,
      title: l10n.aquarium,
      maxHeight: size.height * 0.92,
      content: AquariumModal(key: modalKey),
      onHelpPressed: () => modalKey.currentState?._showTutorial(),
    );
  }

  static Future<void> _showLandscape(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modalKey = GlobalKey<_AquariumModalState>();
    final size = MediaQuery.of(context).size;
    final dialogWidth = (size.width * 0.92).clamp(0.0, 1100.0);
    final dialogHeight = size.height * 0.92;
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: AppModal(
            isDialog: true,
            title: l10n.aquarium,
            scrollable: false,
            content: AquariumModal(key: modalKey),
            onHelpPressed: () => modalKey.currentState?._showTutorial(),
          ),
        ),
      ),
    );
  }
}

class _AquariumModalState extends State<AquariumModal> with TickerProviderStateMixin {
  late AquariumProgress _progress;
  final List<_FishAnimationData> _fishAnimations = [];
  Timer? _animationTimer;

  // Feed particle animations — mỗi cá có animation riêng, chạy song song
  final List<_FeedParticleAnim> _feedAnims = [];

  // Coin animations per fish
  final List<_CoinAnimState> _coinAnims = [];

  bool _isDebugMode = false;
  final AuthService _authService = AuthService();
  final _random = Random();

  double _tankSize = 0;

  /// Fish image size scales with the tank — ~12 % of tank width, clamped 32–64 px.
  double get _fishDisplaySize =>
      _tankSize > 0 ? (_tankSize * 0.12).clamp(32.0, 64.0) : 48.0;

  final GlobalKey _tankKey = GlobalKey();
  final GlobalKey _fishShopKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _startAnimationTimer();
    _checkDebugMode();

  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    for (final fa in _feedAnims) {
      fa.cleanupTimer?.cancel();
      fa.controller.dispose();
    }
    for (final anim in _coinAnims) {
      anim.controller.dispose();
    }
    super.dispose();
  }

  void _startAnimationTimer() {
    _animationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) setState(() => _updateFishAnimations());
    });
  }

  void _updateFishAnimations() {
    if (_tankSize == 0) return;
    final fishSize = _fishDisplaySize;
    final maxCoord = _tankSize - fishSize;

    for (int i = 0; i < _fishAnimations.length; i++) {
      final anim = _fishAnimations[i];
      if (anim.isBeingFed) continue; // Cá đứng yên khi đang ăn

      final fish = i < _progress.fishes.length ? _progress.fishes[i] : null;
      final isHungry = fish != null && AquariumService.isHungry(fish);
      anim.isHungry = isHungry;

      double newX, newY;
      if (isHungry) {
        // Cá đói di chuyển gần hơn, trong vùng nhỏ hơn (60% giữa bể)
        final centerX = maxCoord / 2;
        final centerY = maxCoord / 2;
        final spread = maxCoord * 0.3;
        newX = (centerX + (_random.nextDouble() - 0.5) * spread * 2).clamp(maxCoord * 0.1, maxCoord * 0.9);
        newY = (centerY + (_random.nextDouble() - 0.5) * spread * 2).clamp(maxCoord * 0.1, maxCoord * 0.9);
      } else {
        final pos = AquariumService.getRandomPosition(maxCoord, maxCoord);
        newX = pos['x']!;
        newY = pos['y']!;
      }

      anim.oldX = anim.targetX;
      anim.flipHorizontal = newX > anim.targetX;
      anim.targetX = newX;
      anim.targetY = newY;
      anim.targetScale = AquariumService.getRandomScale();
    }
  }

  void _loadProgress() {
    var progress = DataManager().aquariumProgress;
    progress ??= AquariumProgress(
      fishes: [Fish(type: 'betta'), Fish(type: 'betta')],
      earnings: 0,
    );
    setState(() {
      _progress = progress!;
      _initializeFishAnimations();
    });
    _saveProgress();
  }

  void _initializeFishAnimations() {
    if (_tankSize == 0) return;
    _fishAnimations.clear();
    final fishSize = _fishDisplaySize;

    for (int i = 0; i < _progress.fishes.length; i++) {
      final fish = _progress.fishes[i];
      final pos = AquariumService.getRandomPosition(_tankSize - fishSize, _tankSize - fishSize);
      _fishAnimations.add(_FishAnimationData(
        currentX: pos['x']!,
        currentY: pos['y']!,
        targetX: pos['x']!,
        targetY: pos['y']!,
        oldX: pos['x']!,
        currentScale: 1.0,
        targetScale: 1.0,
        flipHorizontal: false,
        isHungry: AquariumService.isHungry(fish),
        isBeingFed: false,
      ));
    }
  }

  void _saveProgress() => DataManager().saveAquariumProgress(_progress);

  Future<void> _checkDebugMode() async {
    final isDebug = await _authService.isDebugMode;
    if (mounted) setState(() => _isDebugMode = isDebug);
  }

  // Priority: claim trước, sau đó mới feed (để không mất xu tích lũy)
  Future<void> _onTapFish(int index) async {
    if (index >= _progress.fishes.length) return;
    final fish = _progress.fishes[index];
    final anim = _fishAnimations[index];

    final claimable = AquariumService.calculateFishClaimablePoints(fish);
    if (claimable > 0) {
      await _claimFish(index, fish, anim, claimable);
    } else if (AquariumService.isHungry(fish)) {
      await _feedFish(index, fish, anim);
    }
  }

  Future<void> _feedFish(int index, Fish fish, _FishAnimationData anim) async {
    final fishSize = _fishDisplaySize;
    final double maxCoord = _tankSize - fishSize;

    final double landX = (anim.targetX + fishSize / 2 + (_random.nextDouble() - 0.5) * 16).clamp(4, maxCoord + fishSize - 4);
    final double startY = anim.targetY - 50;
    final double landY = (anim.targetY + fishSize / 3).clamp(0, maxCoord + fishSize - 4);

    final updatedFish = AquariumService.feedFish(fish);
    final newFishes = List<Fish>.from(_progress.fishes);
    newFishes[index] = updatedFish;

    // Tạo animation riêng cho con cá này — chạy song song với các cá khác
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final feedAnim = _FeedParticleAnim(
      controller: controller,
      fishAnim: anim,
      particleX: landX,
      particleStartY: startY,
      particleLandY: landY,
    );

    setState(() {
      _progress = _progress.copyWith(fishes: newFishes);
      anim.isHungry = false;
      anim.isBeingFed = true;
      _feedAnims.add(feedAnim);
    });

    controller.forward().then((_) {
      if (!mounted) return;
      setState(() {
        feedAnim.phase = 1;
        anim.targetX = (landX - fishSize / 2).clamp(0, maxCoord);
        anim.targetY = (landY - fishSize / 2).clamp(0, maxCoord);
      });

      feedAnim.cleanupTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _feedAnims.remove(feedAnim);
          anim.isBeingFed = false;
        });
        feedAnim.controller.dispose();
      });
    });

    _saveProgress();
    SfxService().taskComplete();
    if (mounted) {
      final score = context.read<ScoreProvider>();
      final newly = await context.read<AchievementProvider>().onFishFed(score);
      if (newly.isNotEmpty && mounted) AchievementPopup.show(context, newly);
    }
  }

  Future<void> _claimFish(int index, Fish fish, _FishAnimationData anim, int claimable) async {
    final updatedFish = AquariumService.claimFish(fish);
    final newFishes = List<Fish>.from(_progress.fishes);
    newFishes[index] = updatedFish;

    final coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final coinAnim = _CoinAnimState(
      controller: coinController,
      points: claimable,
      x: anim.targetX + _fishDisplaySize / 2,
      y: anim.targetY + _fishDisplaySize / 2,
    );

    setState(() {
      _progress = _progress.copyWith(
        fishes: newFishes,
        earnings: _progress.earnings + claimable,
      );
      _coinAnims.add(coinAnim);
    });

    coinController.forward().then((_) {
      if (mounted) {
        setState(() => _coinAnims.remove(coinAnim));
        coinAnim.controller.dispose();
      }
    });

    await context.read<ScoreProvider>().addPoints(claimable);
    if (mounted) {
      final score = context.read<ScoreProvider>();
      final newly = await context
          .read<AchievementProvider>()
          .onAquariumClaimed(claimable, score);
      if (newly.isNotEmpty && mounted) AchievementPopup.show(context, newly);
    }

    _saveProgress();
    SfxService().reward();
  }

  void _onBuyFish(String fishType) async {
    final config = FishConfigs.getConfig(fishType);
    if (config == null) return;
    final currentProfile = DataManager().userProfile;
    if (currentProfile.currentPoints < config.price) return;
    if (_progress.fishes.length >= 10) return;

    await context.read<ScoreProvider>().subtractPoints(config.price);

    setState(() {
      final newFishes = List<Fish>.from(_progress.fishes)..add(Fish(type: fishType));
      _progress = _progress.copyWith(fishes: newFishes);
      final pos = AquariumService.getRandomPosition(_tankSize - _fishDisplaySize, _tankSize - _fishDisplaySize);
      _fishAnimations.add(_FishAnimationData(
        currentX: pos['x']!,
        currentY: pos['y']!,
        targetX: pos['x']!,
        targetY: pos['y']!,
        oldX: pos['x']!,
        currentScale: 0.0,
        targetScale: 1.0,
        flipHorizontal: false,
        isHungry: true,
        isBeingFed: false,
      ));
    });

    _saveProgress();
    SfxService().reward();

    if (mounted) {
      final score = context.read<ScoreProvider>();
      final newly = await context
          .read<AchievementProvider>()
          .onFishCountChanged(_progress.fishes.length, score);
      if (newly.isNotEmpty && mounted) AchievementPopup.show(context, newly);
    }
  }

  void _onSellFish(String fishType) async {
    final fishIndex = _progress.fishes.indexWhere((f) => f.type == fishType);
    if (fishIndex == -1) return;
    final config = FishConfigs.getConfig(fishType);
    if (config != null) await context.read<ScoreProvider>().addPoints(config.price);

    setState(() {
      final newFishes = List<Fish>.from(_progress.fishes)..removeAt(fishIndex);
      _progress = _progress.copyWith(fishes: newFishes);
      if (fishIndex < _fishAnimations.length) _fishAnimations.removeAt(fishIndex);
    });

    _saveProgress();
    SfxService().buttonClick();
  }

  void _showTutorial() {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    final tutorial = TutorialOverlay(
      context: context,
      steps: [
        TutorialStep(
          targetKey: _tankKey,
          title: '🐟 ${l10n.aquarium}',
          description: l10n.tutorialAquariumTankDesc,
          tag: 'tank',
        ),
        TutorialStep(
          targetKey: _fishShopKey,
          title: '🐠 ${l10n.tutorialAquariumShopTitle}',
          description: l10n.tutorialAquariumShopDesc,
          tag: 'shop',
        ),
      ],
      nextText: l10n.tutorialNext,
      skipText: l10n.tutorialSkip,
      finshText: l10n.tutorialGotIt,
      onComplete: () => SfxService().buttonClick(),
      tooltipBackgroundColor: theme.background,
      titleTextColor: theme.text,
      descriptionTextColor: theme.text,
      nextButtonStyle: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      skipButtonStyle: TextButton.styleFrom(
        foregroundColor: theme.text,
      ),
      finishButtonStyle: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
    );
    tutorial.show();
  }

  Future<void> _debugSkipFeedCycle() async {
    if (!_isDebugMode) return;
    final newFishes = AquariumService.debugSkipAllFeedCycles(_progress.fishes);
    setState(() {
      _progress = _progress.copyWith(fishes: newFishes);
      for (final anim in _fishAnimations) { anim.isHungry = true; }
    });
    _saveProgress();
    SfxService().buttonClick();
  }

  Future<void> _debugMaxPoints() async {
    if (!_isDebugMode) return;
    final newFishes = AquariumService.debugMaximizeAllClaimablePoints(_progress.fishes);
    setState(() => _progress = _progress.copyWith(fishes: newFishes));
    _saveProgress();
    SfxService().buttonClick();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth >= 560;
        return isLandscape ? _buildLandscape(context) : _buildPortrait(context);
      },
    );
  }

  Widget _buildPortrait(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final currentPoints = context.watch<ScoreProvider>().currentPoints;

    final totalFish = _progress.fishes.length;
    final totalPointsPerHour = _progress.fishes.fold<int>(0, (sum, fish) {
      final config = FishConfigs.getConfig(fish.type);
      return sum + (config?.pointsPerHour ?? 0);
    });
    final hungryCount = _progress.fishes.where(AquariumService.isHungry).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTankSection(theme, l10n, totalFish, totalPointsPerHour, hungryCount),
        const SizedBox(height: 16),
        Divider(color: theme.border, height: 1, thickness: 1.5),
        const SizedBox(height: 16),
        _buildFishShop(theme, l10n, currentPoints),
      ],
    );
  }

  Widget _buildLandscape(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final currentPoints = context.watch<ScoreProvider>().currentPoints;

    final totalFish = _progress.fishes.length;
    final totalPointsPerHour = _progress.fishes.fold<int>(0, (sum, fish) {
      final config = FishConfigs.getConfig(fish.type);
      return sum + (config?.pointsPerHour ?? 0);
    });
    final hungryCount = _progress.fishes.where(AquariumService.isHungry).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: tank viewport
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final side = min(constraints.maxWidth, constraints.maxHeight);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTankInfoBar(theme, l10n, totalFish, totalPointsPerHour, hungryCount),
                    const SizedBox(height: 12),
                    Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: _buildTankViewport(theme),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        VerticalDivider(width: 1, thickness: 1, color: theme.border),

        // Right: fish shop
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildFishShop(theme, l10n, currentPoints),
          ),
        ),
      ],
    );
  }

  Widget _buildTankSection(
    AppTheme theme,
    AppLocalizations l10n,
    int totalFish,
    int totalPointsPerHour,
    int hungryCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTankInfoBar(theme, l10n, totalFish, totalPointsPerHour, hungryCount),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.0,
          child: _buildTankViewport(theme),
        ),
      ],
    );
  }

  Widget _buildTankInfoBar(
    AppTheme theme,
    AppLocalizations l10n,
    int totalFish,
    int totalPointsPerHour,
    int hungryCount,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '🐟 $totalFish/10 • $totalPointsPerHour ${l10n.points}/${l10n.hour}',
          style: AppTypography.bodyMedium(context,
            color: theme.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (hungryCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primary.withOpacity(0.4)),
            ),
            child: Text(
              '🐟 $hungryCount ${l10n.fishHungry}',
              style: AppTypography.captionSmall(context,
                color: theme.primary,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildTankViewport(AppTheme theme) {
    return Container(
      key: _tankKey,
      decoration: BoxDecoration(
        border: Border.all(color: theme.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final newSize = constraints.maxWidth;
            if (_tankSize != newSize) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _tankSize = newSize;
                    _initializeFishAnimations();
                  });
                }
              });
            }
            return Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    image: true,
                    label: 'Aquarium tank background',
                    child: Image.asset(
                      AssetLoader.getTankAsset(
                        DataManager().userSettings.currentScenes[2].sceneSet,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (_tankSize > 0) ..._buildAnimatedFish(),
                ..._buildFeedParticles(),
                ..._buildCoinAnimations(),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedFish() {
    if (_progress.fishes.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '${l10n.noFishYet}\n${l10n.buyFishBelow}',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(context,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ];
    }

    final theme = context.theme;
    final List<Widget> fishWidgets = [];

    for (int i = 0; i < _progress.fishes.length && i < _fishAnimations.length; i++) {
      final fish = _progress.fishes[i];
      final anim = _fishAnimations[i];
      final isHungry = anim.isHungry;
      final claimable = AquariumService.calculateFishClaimablePoints(fish);
      final cycleProgress = AquariumService.calculateFishCycleProgress(fish);

      // Cá đang ăn dùng duration nhanh hơn (bơi về phía thức ăn)
      final moveDuration = anim.isBeingFed
          ? const Duration(milliseconds: 1000)
          : AquariumService.getFishMovementDuration(fish);

      final fishSize = _fishDisplaySize;
      final hitboxSize = fishSize * 1.5;
      final hitboxOffset = fishSize * 0.25;
      fishWidgets.add(
        AnimatedPositioned(
          duration: moveDuration,
          curve: Curves.easeInOut,
          left: anim.targetX - hitboxOffset,
          top: anim.targetY - hitboxOffset,
          child: GestureDetector(
            onTap: () => _onTapFish(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: hitboxSize,
              height: hitboxSize,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 500),
                scale: anim.targetScale,
                child: Stack(
                  children: [
                    // Cá
                    Align(
                      alignment: Alignment.center,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..scale(anim.flipHorizontal ? -1.0 : 1.0, 1.0),
                        child: Semantics(
                          image: true,
                          label: '${_getFishName(fish.type)} fish',
                          child: Image.asset(
                            AssetLoader.getFishAsset(fish.type),
                            width: fishSize,
                            height: fishSize,
                          ),
                        ),
                      ),
                    ),

                    // Góc trên trái: icon đói
                    if (isHungry)
                      const Positioned(
                        top: 1,
                        left: 1,
                        child: Text('🍞', style: TextStyle(fontSize: 12)),
                      ),

                    // Góc trên phải: icon có thể nhận điểm
                    if (claimable > 0)
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                      ),

                    // Progress bar phía dưới cá
                    Positioned(
                      bottom: 2,
                      left: hitboxOffset,
                      right: hitboxOffset,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: cycleProgress / 100,
                          backgroundColor: theme.border,
                          valueColor: AlwaysStoppedAnimation(
                            theme.primary,
                          ),
                          minHeight: 3,
                        ),
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

    return fishWidgets;
  }

  // Particles song song — mỗi cá đang được cho ăn có widget riêng
  List<Widget> _buildFeedParticles() {
    return _feedAnims.map((fa) {
      if (fa.phase == 1) {
        return Positioned(
          left: fa.particleX - 4,
          top: fa.particleLandY - 4,
          child: _particleDot(),
        );
      }
      return AnimatedBuilder(
        animation: fa.controller,
        builder: (context, _) {
          final p = fa.controller.value;
          final currentY = fa.particleStartY + (fa.particleLandY - fa.particleStartY) * p;
          return Positioned(
            left: fa.particleX - 4,
            top: currentY,
            child: _particleDot(),
          );
        },
      );
    }).toList();
  }

  Widget _particleDot() => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.brown.shade400,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2),
          ],
        ),
      );

  List<Widget> _buildCoinAnimations() {
    return _coinAnims.map((coinAnim) => FloatingLabelAnim(
      x: coinAnim.x,
      y: coinAnim.y,
      label: '+${coinAnim.points}',
      controller: coinAnim.controller,
      backgroundColor: context.theme.primary,
    )).toList();
  }

  Widget _buildFishShop(AppTheme theme, AppLocalizations l10n, int currentPoints) {
    final Map<String, int> fishCounts = {};
    for (var fish in _progress.fishes) {
      fishCounts[fish.type] = (fishCounts[fish.type] ?? 0) + 1;
    }
    final isTankFull = _progress.fishes.length >= 10;

    return Column(
      key: _fishShopKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.fishShop,
              style: AppTypography.bodyLarge(context, color: theme.text, fontWeight: FontWeight.bold)),
            if (isTankFull)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(l10n.tankFull,
                  style: AppTypography.bodySmall(context, color: Colors.red, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...FishConfigs.fishes.entries.map((entry) {
          final fishType = entry.key;
          final config = entry.value;
          final owned = fishCounts[fishType] ?? 0;
          String localizedName = config.name;
          switch (fishType) {
            case 'betta': localizedName = l10n.betta; break;
            case 'guppy': localizedName = l10n.guppy; break;
            case 'neon': localizedName = l10n.neonTetra; break;
            case 'molly': localizedName = l10n.molly; break;
            case 'cory': localizedName = l10n.cory; break;
            case 'platy': localizedName = l10n.platy; break;
          }
          return _buildFishCard(fishType, localizedName, config.pointsPerHour, config.price,
              owned, theme, l10n, currentPoints, isTankFull);
        }),
        if (_isDebugMode) ...[
          const SizedBox(height: 16),
          Divider(color: theme.border, height: 1, thickness: 1.5),
          const SizedBox(height: 16),
          Text('DEBUG MODE',
            style: AppTypography.bodyLarge(context, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _debugSkipFeedCycle,
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('Skip Cycle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _debugMaxPoints,
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('Max Points'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFishCard(
    String fishType, String name, int pointsPerHour, int price, int owned,
    AppTheme theme, AppLocalizations l10n, int currentPoints, bool isTankFull,
  ) {
    final canBuy = currentPoints >= price && !isTankFull;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border.all(color: theme.border, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Semantics(
            image: true,
            label: '${_getFishName(fishType)} fish',
            child: Image.asset(AssetLoader.getFishAsset(fishType), width: 48, height: 48),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                  style: AppTypography.bodyLarge(context, color: theme.text, fontWeight: FontWeight.bold)),
                Text('$pointsPerHour ${l10n.points}/${l10n.hour}',
                  style: AppTypography.bodyMedium(context, color: theme.text.withOpacity(0.7))),
                Row(
                  children: [
                    Text('${l10n.price}: $price',
                      style: AppTypography.bodySmall(context,
                        color: canBuy ? Colors.amber : context.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      )),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: owned > 0 ? () => _onSellFish(fishType) : null,
                color: owned > 0 ? theme.primary : theme.text.withOpacity(0.3),
              ),
              Text('$owned ${l10n.owned}',
                style: AppTypography.bodyMedium(context, color: theme.text, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: canBuy ? () => _onBuyFish(fishType) : null,
                color: canBuy ? theme.primary : theme.text.withOpacity(0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFishName(String fishType) {
    switch (fishType.toLowerCase()) {
      case 'betta': return 'Betta';
      case 'guppy': return 'Guppy';
      case 'neon': return 'Neon Tetra';
      case 'molly': return 'Molly';
      case 'cory': return 'Cory Catfish';
      case 'platy': return 'Platy';
      default: return fishType;
    }
  }
}

class _FishAnimationData {
  double currentX, currentY, targetX, targetY, oldX, currentScale, targetScale;
  bool flipHorizontal, isHungry, isBeingFed;

  _FishAnimationData({
    required this.currentX, required this.currentY,
    required this.targetX, required this.targetY,
    required this.oldX,
    required this.currentScale, required this.targetScale,
    required this.flipHorizontal,
    required this.isHungry,
    required this.isBeingFed,
  });
}

class _FeedParticleAnim {
  final AnimationController controller;
  final _FishAnimationData fishAnim;
  final double particleX, particleStartY, particleLandY;
  int phase = 0; // 0 = falling, 1 = landed
  Timer? cleanupTimer;

  _FeedParticleAnim({
    required this.controller,
    required this.fishAnim,
    required this.particleX,
    required this.particleStartY,
    required this.particleLandY,
  });
}

class _CoinAnimState {
  final AnimationController controller;
  final int points;
  final double x, y;

  _CoinAnimState({
    required this.controller,
    required this.points,
    required this.x,
    required this.y,
  });
}
