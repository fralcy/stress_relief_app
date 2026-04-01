import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tutorial_overlay/flutter_tutorial_overlay.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/asset_loader.dart';
import '../../core/utils/garden_service.dart';
import '../../core/utils/auth_service.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/utils/data_manager.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/score_provider.dart';
import '../../core/providers/achievement_provider.dart';
import '../../core/widgets/achievement_popup.dart';
import '../../models/garden_progress.dart';

/// Modal mini-game làm vườn/trồng trọt
class GardenModal extends StatefulWidget {
  const GardenModal({super.key});

  @override
  State<GardenModal> createState() => _GardenModalState();

  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modalKey = GlobalKey<_GardenModalState>();
    final fixedHeight = MediaQuery.of(context).size.height * 0.92;
    return AppModal.show(
      context: context,
      title: l10n.garden,
      maxHeight: fixedHeight,
      minHeight: fixedHeight,
      content: GardenModal(key: modalKey),
      onHelpPressed: () => modalKey.currentState?._showTutorial(),
    );
  }
}

class _GardenModalState extends State<GardenModal>
    with TickerProviderStateMixin {
  late GardenProgress _progress;
  String? _selectedPlantType;

  /// Last successfully executed action — used to break ties when a cell
  /// allows multiple actions simultaneously (e.g. needs water AND has pest).
  String? _lastAction;

  /// Cells already acted on during the current drag gesture.
  final Set<String> _draggedCells = {};

  Timer? _growthTimer;

  // Cell animation state
  final Map<String, AnimationController> _cellAnimations = {};
  final Map<String, String> _cellEffects = {};
  final Map<String, int> _cellHarvestPoints = {};

  // Debug mode
  bool _isDebugMode = false;
  final AuthService _authService = AuthService();

  // Tutorial overlay keys
  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _inventoryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _startGrowthTimer();
    _checkDebugMode();
  }

  @override
  void dispose() {
    _growthTimer?.cancel();
    for (final c in _cellAnimations.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ==================== INIT ====================

  void _startGrowthTimer() {
    _growthTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        setState(() {
          _progress = _progress.copyWith(
            plots: GardenService.updateAllCells(_progress.plots),
          );
        });
        _saveProgress();
      }
    });
  }

  void _loadProgress() {
    var progress = DataManager().gardenProgress;

    if (progress == null) {
      final emptyPlots = List.generate(4, (_) {
        return List.generate(4, (_) {
          return PlantCell(
            plantType: null,
            growthStage: 0,
            lastWatered: DateTime.now(),
            needsWater: false,
            hasPest: false,
            plantedAt: null,
          );
        });
      });
      progress = GardenProgress(
        plots: emptyPlots,
        inventory: {
          'carrot': 5,
          'tomato': 5,
          'corn': 5,
          'sunflower': 5,
          'rose': 5,
          'tulip': 5,
          'wheat': 5,
          'pumpkin': 5,
          'strawberry': 5,
          'lettuce': 5,
        },
        earnings: 0,
      );
    } else {
      progress = progress.copyWith(
        plots: GardenService.updateAllCells(progress.plots),
      );
    }

    DataManager().saveGardenProgress(progress);
    setState(() => _progress = progress!);
  }

  void _saveProgress() => DataManager().saveGardenProgress(_progress);

  Future<void> _checkDebugMode() async {
    final isDebug = await _authService.isDebugMode;
    if (mounted) setState(() => _isDebugMode = isDebug);
  }

  // ==================== DEBUG ====================

  Future<void> _debugAdvanceGrowth() async {
    if (!_isDebugMode) return;
    var plots = GardenService.debugAdvanceAllPlants(
      plots: _progress.plots,
      hours: 20,
    );
    plots = GardenService.updateAllCells(plots);
    setState(() => _progress = _progress.copyWith(plots: plots));
    _saveProgress();
    SfxService().buttonClick();
  }

  Future<void> _debugInstantGrowth() async {
    if (!_isDebugMode) return;
    var plots = GardenService.debugInstantGrowAll(plots: _progress.plots);
    plots = GardenService.updateAllCells(plots);
    setState(() => _progress = _progress.copyWith(plots: plots));
    _saveProgress();
    SfxService().buttonClick();
  }

  // ==================== TUTORIAL ====================

  void _showTutorial() {
    final l10n = AppLocalizations.of(context);
    TutorialOverlay(
      context: context,
      steps: [
        TutorialStep(
          targetKey: _gridKey,
          title: '🌱 ${l10n.garden}',
          description: l10n.tutorialGardenGridDesc,
          tag: 'grid',
        ),
        TutorialStep(
          targetKey: _inventoryKey,
          title: '🎒 ${l10n.tutorialGardenInventoryTitle}',
          description: l10n.tutorialGardenInventoryDesc,
          tag: 'inventory',
        ),
      ],
      nextText: l10n.tutorialNext,
      skipText: l10n.tutorialSkip,
      finshText: l10n.tutorialGotIt,
      onComplete: () => SfxService().buttonClick(),
    ).show();
  }

  // ==================== ANIMATIONS ====================

  AnimationController _getCellAnimCtrl(int row, int col) {
    final key = '$row-$col';
    return _cellAnimations.putIfAbsent(
      key,
      () => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _playCellAnimation(int row, int col, String effect) {
    final key = '$row-$col';
    _cellEffects[key] = effect;
    _getCellAnimCtrl(row, col).forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _cellEffects.remove(key);
          _cellHarvestPoints.remove(key);
        });
      }
    });
  }

  // ==================== SMART ACTION ====================

  /// Determines and executes the appropriate action for the tapped/dragged cell.
  ///
  /// Priority for occupied cells: harvest > pestControl > water.
  /// When multiple actions are available, [_lastAction] breaks the tie so the
  /// user can repeat the same gesture without switching modes.
  void _smartAction(int row, int col) async {
    final cell = _progress.plots[row][col];

    // Empty cell — plant if a seed is selected
    if (cell.plantType == null) {
      if (_selectedPlantType != null &&
          (_progress.inventory[_selectedPlantType!] ?? 0) > 0) {
        await _doPlant(row, col, _selectedPlantType!);
      }
      return;
    }

    // Build list of currently applicable actions in priority order
    final available = <String>[
      if (cell.growthStage >= 100) 'harvest',
      if (cell.hasPest) 'pestControl',
      if (cell.needsWater) 'water',
    ];

    if (available.isEmpty) return;

    // Repeat last action when it's still valid; otherwise use priority order
    final action =
        (available.length > 1 && available.contains(_lastAction))
            ? _lastAction!
            : available.first;

    switch (action) {
      case 'harvest':
        await _doHarvest(row, col);
      case 'pestControl':
        await _doPest(row, col);
      case 'water':
        await _doWater(row, col);
    }
  }

  // ==================== ACTIONS ====================

  Future<void> _doPlant(int row, int col, String plantType) async {
    final result = GardenService.plantSeed(
      plots: _progress.plots,
      inventory: _progress.inventory,
      row: row,
      col: col,
      plantType: plantType,
    );
    if (result == null) return;
    setState(() {
      _progress = _progress.copyWith(
        plots: result['plots'],
        inventory: result['inventory'],
      );
    });
    _saveProgress();
    _playCellAnimation(row, col, 'plant');
    SfxService().buttonClick();
    _lastAction = 'plant';
    if (mounted) {
      final score = context.read<ScoreProvider>();
      final newly = await context.read<AchievementProvider>().onPlanted(score);
      if (newly.isNotEmpty && mounted) AchievementPopup.show(context, newly);
    }
  }

  Future<void> _doWater(int row, int col) async {
    final result = GardenService.waterPlant(
      plots: _progress.plots,
      row: row,
      col: col,
    );
    if (result == null) return;
    setState(() => _progress = _progress.copyWith(plots: result));
    _saveProgress();
    _playCellAnimation(row, col, 'water');
    SfxService().buttonClick();
    _lastAction = 'water';
  }

  Future<void> _doPest(int row, int col) async {
    final result = GardenService.removePest(
      plots: _progress.plots,
      row: row,
      col: col,
    );
    if (result == null) return;
    setState(() => _progress = _progress.copyWith(plots: result));
    _saveProgress();
    _playCellAnimation(row, col, 'pest');
    SfxService().buttonClick();
    _lastAction = 'pestControl';
  }

  Future<void> _doHarvest(int row, int col) async {
    final result = GardenService.harvestPlant(
      plots: _progress.plots,
      inventory: _progress.inventory,
      earnings: _progress.earnings,
      row: row,
      col: col,
    );
    if (result == null) return;
    setState(() {
      _progress = _progress.copyWith(
        plots: result['plots'],
        inventory: result['inventory'],
        earnings: result['earnings'],
      );
    });
    _saveProgress();
    await context.read<ScoreProvider>().addPoints(result['pointsGained']);
    if (mounted) {
      final score = context.read<ScoreProvider>();
      final newly = await context
          .read<AchievementProvider>()
          .onHarvest(result['pointsGained'] as int, score);
      if (newly.isNotEmpty && mounted) AchievementPopup.show(context, newly);
    }
    _cellHarvestPoints['$row-$col'] = result['pointsGained'];
    _playCellAnimation(row, col, 'harvest');
    SfxService().taskComplete();
    _lastAction = 'harvest';
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGridSection(theme),

        const SizedBox(height: 16),
        Divider(color: theme.border, height: 1, thickness: 1.5),
        const SizedBox(height: 16),

        _buildInventorySection(theme),

        // Debug section
        if (_isDebugMode) ...[
          const SizedBox(height: 16),
          Divider(color: theme.border, height: 1, thickness: 1.5),
          const SizedBox(height: 16),
          Text(
            'DEBUG MODE',
            style: AppTypography.bodyLarge(
              context,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _debugAdvanceGrowth,
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('+20 Hours'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _debugInstantGrowth,
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('Instant Grow'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ==================== GRID SECTION ====================

  Widget _buildGridSection(AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.gardenTitle,
          style: AppTypography.bodyLarge(
            context,
            color: theme.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          key: _gridKey,
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.border, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            // LayoutBuilder gives us the rendered size so we can map
            // pointer positions to cell indices without RenderBox lookups.
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final cellSize = constraints.maxWidth / 4;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // ── Single tap ──
                  onTapUp: (d) {
                    final row =
                        (d.localPosition.dy / cellSize).floor().clamp(0, 3);
                    final col =
                        (d.localPosition.dx / cellSize).floor().clamp(0, 3);
                    _smartAction(row, col);
                  },
                  // ── Drag → act on each new cell the finger enters ──
                  onPanStart: (_) => _draggedCells.clear(),
                  onPanUpdate: (d) {
                    final dx = d.localPosition.dx;
                    final dy = d.localPosition.dy;
                    final size = constraints.maxWidth;
                    if (dx < 0 || dx > size || dy < 0 || dy > size) return;
                    final row = (dy / cellSize).floor().clamp(0, 3);
                    final col = (dx / cellSize).floor().clamp(0, 3);
                    final key = '$row-$col';
                    if (_draggedCells.add(key)) {
                      _smartAction(row, col);
                    }
                  },
                  onPanEnd: (_) => _draggedCells.clear(),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 0,
                    ),
                    itemCount: 16,
                    itemBuilder: (context, index) {
                      final row = index ~/ 4;
                      final col = index % 4;
                      return _buildPlotCell(
                          row, col, _progress.plots[row][col], theme);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==================== PLOT CELL ====================

  Widget _buildPlotCell(int row, int col, PlantCell cell, AppTheme theme) {
    final key = '$row-$col';
    final effectType = _cellEffects[key];
    final animCtrl = _getCellAnimCtrl(row, col);

    return Container(
      decoration: const BoxDecoration(color: Color(0xFF8B7355)),
      child: Stack(
        children: [
          // Plant sprite
          Center(
            child: cell.plantType != null
                ? AnimatedBuilder(
                    animation: animCtrl,
                    builder: (context, _) {
                      Widget plant = Semantics(
                        image: true,
                        label:
                            '${_getPlantName(cell.plantType!)} plant, growth: ${cell.growthStage}%',
                        child: Image.asset(
                          AssetLoader.getPlantAsset(
                              cell.plantType!, cell.growthStage),
                          width: 40,
                          height: 40,
                          errorBuilder: (_, _, _) => Text(
                            GardenService.getPlantIcon(cell.plantType!),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      );
                      if (effectType == 'plant') {
                        return Transform.scale(
                            scale: animCtrl.value, child: plant);
                      } else if (effectType == 'harvest') {
                        return Opacity(
                          opacity: 1.0 - animCtrl.value,
                          child: Transform.scale(
                              scale: 1.0 + animCtrl.value * 0.5,
                              child: plant),
                        );
                      } else if (effectType == 'pest') {
                        final shake =
                            math.sin(animCtrl.value * 4 * math.pi) * 4;
                        return Transform.translate(
                            offset: Offset(shake, 0), child: plant);
                      }
                      return plant;
                    },
                  )
                : null,
          ),

          // Water ripple
          if (effectType == 'water')
            Center(
              child: AnimatedBuilder(
                animation: animCtrl,
                builder: (_, _) => Container(
                  width: 40 * (1 + animCtrl.value),
                  height: 40 * (1 + animCtrl.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 1.0 - animCtrl.value),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

          // Harvest floating points
          if (effectType == 'harvest' && _cellHarvestPoints.containsKey(key))
            Center(
              child: AnimatedBuilder(
                animation: animCtrl,
                builder: (_, _) => Transform.translate(
                  offset: Offset(0, -animCtrl.value * 30),
                  child: Opacity(
                    opacity: 1.0 - animCtrl.value,
                    child: Text(
                      '+${_cellHarvestPoints[key]}',
                      style: TextStyle(
                        fontSize: 16 + animCtrl.value * 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Status indicators
          if (cell.plantType != null) ...[
            if (cell.needsWater)
              Positioned(
                top: 2,
                left: 2,
                child: _indicator(Colors.blue, Icons.water_drop),
              ),
            if (cell.hasPest)
              Positioned(
                top: 2,
                right: 2,
                child: _indicator(Colors.red, Icons.bug_report),
              ),
            if (cell.growthStage >= 100)
              Positioned(
                bottom: 2,
                right: 2,
                child: _indicator(Colors.green, Icons.check_circle),
              ),
            if (cell.growthStage < 100)
              Positioned(
                bottom: 2,
                left: 4,
                right: 4,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: theme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: cell.growthStage / 100),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (_, value, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _indicator(Color color, IconData icon) => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 12, color: Colors.white),
      );

  // ==================== INVENTORY SECTION ====================

  Widget _buildInventorySection(AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: _inventoryKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inventory,
          style: AppTypography.bodyLarge(
            context,
            color: theme.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _progress.inventory.entries.map((entry) {
            final isSelected = _selectedPlantType == entry.key;
            final count = entry.value;
            return InkWell(
              onTap: count > 0
                  ? () => setState(() {
                        _selectedPlantType =
                            isSelected ? null : entry.key;
                      })
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primary : theme.background,
                  border: Border.all(
                    color: count > 0
                        ? theme.border
                        : theme.border,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      GardenService.getPlantIcon(entry.key),
                      style: TextStyle(
                        fontSize: 20,
                        color: count > 0 ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x${entry.value}',
                      style: AppTypography.bodyLarge(
                        context,
                        color: isSelected ? theme.background : theme.text,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== HELPERS ====================

  String _getPlantName(String plantType) {
    switch (plantType.toLowerCase()) {
      case 'carrot':
        return 'Carrot';
      case 'tomato':
        return 'Tomato';
      case 'corn':
        return 'Corn';
      case 'sunflower':
        return 'Sunflower';
      case 'rose':
        return 'Rose';
      case 'tulip':
        return 'Tulip';
      case 'wheat':
        return 'Wheat';
      case 'pumpkin':
        return 'Pumpkin';
      case 'strawberry':
        return 'Strawberry';
      default:
        return plantType;
    }
  }
}
