import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/asset_loader.dart';
import '../../core/utils/garden_service.dart';
import '../../core/utils/auth_service.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/data_manager.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/score_provider.dart';
import '../../models/garden_progress.dart';

/// Modal mini-game làm vườn/trồng trọt
class GardenModal extends StatefulWidget {
  const GardenModal({super.key});

  @override
  State<GardenModal> createState() => _GardenModalState();

  /// Helper để show modal
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.garden,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      content: const GardenModal(),
    );
  }
}

class _GardenModalState extends State<GardenModal> with TickerProviderStateMixin {
  late GardenProgress _progress;
  String? _selectedPlantType;
  String? _selectedAction;
  Timer? _growthTimer;
  
  // Animation controllers cho các action
  final Map<String, AnimationController> _cellAnimations = {};
  final Map<String, String> _cellEffects = {}; // Lưu effect type cho mỗi cell
  final Map<String, int> _cellHarvestPoints = {}; // Lưu points khi harvest

  // Debug mode state
  bool _isDebugMode = false;
  final AuthService _authService = AuthService();

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
    for (var controller in _cellAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _startGrowthTimer() {
    // Update growth every 8 seconds (balanced realtime update)
    _growthTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
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
      final emptyPlots = List.generate(4, (row) {
        return List.generate(4, (col) {
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
      // UPDATE tất cả cells dựa trên timestamp
      progress = progress.copyWith(
        plots: GardenService.updateAllCells(progress.plots),
      );
    }
    
    DataManager().saveGardenProgress(progress);
    
    setState(() {
      _progress = progress!;
    });
  }

  void _saveProgress() {
    DataManager().saveGardenProgress(_progress);
  }

  Future<void> _checkDebugMode() async {
    final isDebug = await _authService.isDebugMode;
    if (mounted) {
      setState(() {
        _isDebugMode = isDebug;
      });
    }
  }

  Future<void> _debugAdvanceGrowth() async {
    if (!_isDebugMode) return;

    // Update timestamps
    var newPlots = GardenService.debugAdvanceAllPlants(
      plots: _progress.plots,
      hours: 20,
    );

    // Recalculate immediately instead of waiting for timer
    newPlots = GardenService.updateAllCells(newPlots);

    setState(() {
      _progress = _progress.copyWith(plots: newPlots);
    });
    _saveProgress();

    SfxService().buttonClick();
  }

  Future<void> _debugInstantGrowth() async {
    if (!_isDebugMode) return;

    // Update timestamps
    var newPlots = GardenService.debugInstantGrowAll(
      plots: _progress.plots,
    );

    // Recalculate immediately instead of waiting for timer
    newPlots = GardenService.updateAllCells(newPlots);

    setState(() {
      _progress = _progress.copyWith(plots: newPlots);
    });
    _saveProgress();

    SfxService().buttonClick();
  }

  AnimationController _getCellAnimationController(int row, int col) {
    final key = '$row-$col';
    if (!_cellAnimations.containsKey(key)) {
      _cellAnimations[key] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    }
    return _cellAnimations[key]!;
  }
  
  void _playCellAnimation(int row, int col, String effectType) {
    final key = '$row-$col';
    _cellEffects[key] = effectType;
    final controller = _getCellAnimationController(row, col);
    controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _cellEffects.remove(key);
          _cellHarvestPoints.remove(key); // Cleanup harvest points
        });
      }
    });
  }

  // Các getter sử dụng service methods
  bool get _hasEmptyPlot => GardenService.hasEmptyPlot(_progress.plots);
  bool get _hasPlantNeedingWater => GardenService.hasPlantNeedingWater(_progress.plots);
  bool get _hasPlantWithPest => GardenService.hasPlantWithPest(_progress.plots);
  bool get _hasPlantReadyToHarvest => GardenService.hasPlantReadyToHarvest(_progress.plots);
  bool get _canEnablePlantButton => _hasEmptyPlot;
  bool get _canPlant => GardenService.canPlant(
    selectedPlantType: _selectedPlantType,
    inventory: _progress.inventory,
    plots: _progress.plots,
  );

  void _toggleAction(String action) {
    setState(() {
      _selectedAction = _selectedAction == action ? null : action;
    });
  }

  void _onCellTap(int row, int col) async {
    if (_selectedAction == null) return;

    switch (_selectedAction!) {
      case 'plant':
        if (!_canPlant || _selectedPlantType == null) return;

        final result = GardenService.plantSeed(
          plots: _progress.plots,
          inventory: _progress.inventory,
          row: row,
          col: col,
          plantType: _selectedPlantType!,
        );

        if (result != null) {
          setState(() {
            _progress = _progress.copyWith(
              plots: result['plots'],
              inventory: result['inventory'],
            );
          });
          _saveProgress();
          _playCellAnimation(row, col, 'plant');
        }
        break;

      case 'water':
        final result = GardenService.waterPlant(
          plots: _progress.plots,
          row: row,
          col: col,
        );

        if (result != null) {
          setState(() {
            _progress = _progress.copyWith(plots: result);
          });
          _saveProgress();
          _playCellAnimation(row, col, 'water');
        }
        break;

      case 'pestControl':
        final result = GardenService.removePest(
          plots: _progress.plots,
          row: row,
          col: col,
        );

        if (result != null) {
          setState(() {
            _progress = _progress.copyWith(plots: result);
          });
          _saveProgress();
          _playCellAnimation(row, col, 'pest');
        }
        break;

      case 'harvest':
        final result = GardenService.harvestPlant(
          plots: _progress.plots,
          inventory: _progress.inventory,
          earnings: _progress.earnings,
          row: row,
          col: col,
        );

        if (result != null) {
          setState(() {
            _progress = _progress.copyWith(
              plots: result['plots'],
              inventory: result['inventory'],
              earnings: result['earnings'],
            );
          });
          _saveProgress();

          // Cộng điểm vào UserProfile
          await context.read<ScoreProvider>().addPoints(result['pointsGained']);

          // Lưu points để hiển thị animation
          final key = '$row-$col';
          _cellHarvestPoints[key] = result['pointsGained'];
          _playCellAnimation(row, col, 'harvest');
        }
        break;
    }
  }



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
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInventorySection(theme),
                const SizedBox(height: 16),
                Divider(color: theme.border, height: 1, thickness: 1.5),
                const SizedBox(height: 16),
                _buildActionsSection(theme),

                // Debug buttons section
                if (_isDebugMode) ...[
                  const SizedBox(height: 16),
                  Divider(color: theme.border, height: 1, thickness: 1.5),
                  const SizedBox(height: 16),
                  Text(
                    'DEBUG MODE',
                    style: TextStyle(
                      fontSize: 16,
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridSection(AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.gardenTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 12),
        
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.border, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
              ),
              itemCount: 16,
              itemBuilder: (context, index) {
                final row = index ~/ 4;
                final col = index % 4;
                return _buildPlotCell(row, col, _progress.plots[row][col], theme);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlotCell(int row, int col, PlantCell cell, AppTheme theme) {
    final key = '$row-$col';
    final effectType = _cellEffects[key];
    final animController = _getCellAnimationController(row, col);
    
    return InkWell(
      onTap: () => _onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF8B7355),
        ),
        child: Stack(
          children: [
            // Cây ở giữa với animation
            Center(
              child: cell.plantType != null
                  ? AnimatedBuilder(
                      animation: animController,
                      builder: (context, child) {
                        // Animation dựa trên effect type
                        Widget plantWidget = Image.asset(
                          AssetLoader.getPlantAsset(cell.plantType!, cell.growthStage),
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              _getPlantIcon(cell.plantType!),
                              style: const TextStyle(fontSize: 24),
                            );
                          },
                        );
                        
                        if (effectType == 'plant') {
                          // Scale from 0 to 1
                          return Transform.scale(
                            scale: animController.value,
                            child: plantWidget,
                          );
                        } else if (effectType == 'harvest') {
                          // Scale up + fade out
                          return Opacity(
                            opacity: 1.0 - animController.value,
                            child: Transform.scale(
                              scale: 1.0 + (animController.value * 0.5),
                              child: plantWidget,
                            ),
                          );
                        } else if (effectType == 'pest') {
                          // Shake effect
                          final shake = math.sin(animController.value * 4 * 3.14159) * 4;
                          return Transform.translate(
                            offset: Offset(shake, 0),
                            child: plantWidget,
                          );
                        }
                        
                        return plantWidget;
                      },
                    )
                  : null,
            ),
            
            // Water ripple effect
            if (effectType == 'water')
              Center(
                child: AnimatedBuilder(
                  animation: animController,
                  builder: (context, child) {
                    return Container(
                      width: 40 * (1 + animController.value),
                      height: 40 * (1 + animController.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.withOpacity(1.0 - animController.value),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Floating points text khi harvest
            if (effectType == 'harvest' && _cellHarvestPoints.containsKey(key))
              Center(
                child: AnimatedBuilder(
                  animation: animController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -animController.value * 30),
                      child: Opacity(
                        opacity: 1.0 - animController.value,
                        child: Text(
                          '+${_cellHarvestPoints[key]}',
                          style: TextStyle(
                            fontSize: 16 + (animController.value * 8),
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Indicators ở góc
            if (cell.plantType != null) ...[
              // Icon tưới nước (góc trên trái)
              if (cell.needsWater)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              
              // Icon sâu bệnh (góc trên phải)
              if (cell.hasPest)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bug_report,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              
              // Icon thu hoạch (góc dưới phải)
              if (cell.growthStage >= 100)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              
              // Thanh % ở dưới (TÙY CHỌN) với smooth animation
              if (cell.growthStage < 100)
                Positioned(
                  bottom: 2,
                  left: 4,
                  right: 4,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: cell.growthStage / 100),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.lightGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPlantIcon(String plantType) => GardenService.getPlantIcon(plantType);

  Widget _buildInventorySection(AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inventory,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.text,
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
              onTap: count > 0 ? () {
                setState(() {
                  _selectedPlantType = isSelected ? null : entry.key;
                });
              } : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primary : theme.background,
                  border: Border.all(
                    color: count > 0 ? theme.border : theme.border.withOpacity(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getPlantIcon(entry.key),
                      style: TextStyle(
                        fontSize: 20,
                        color: count > 0 ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x${entry.value}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? theme.background : theme.text,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildActionsSection(AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.action,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionButton(
              icon: Icons.yard,
              label: l10n.plant,
              actionKey: 'plant',
              canEnable: _canEnablePlantButton,
              theme: theme,
            ),
            _buildActionButton(
              icon: Icons.water_drop,
              label: l10n.water,
              actionKey: 'water',
              canEnable: _hasPlantNeedingWater,
              theme: theme,
            ),
            _buildActionButton(
              icon: Icons.bug_report,
              label: l10n.pestControl,
              actionKey: 'pestControl',
              canEnable: _hasPlantWithPest,
              theme: theme,
            ),
            _buildActionButton(
              icon: Icons.agriculture,
              label: l10n.harvest,
              actionKey: 'harvest',
              canEnable: _hasPlantReadyToHarvest,
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String actionKey,
    required bool canEnable,
    required AppTheme theme,
  }) {
    final isSelected = _selectedAction == actionKey;
    
    return AppButton(
      label: label,
      icon: icon,
      isActive: isSelected,
      onPressed: () => _toggleAction(actionKey),
      isDisabled: !canEnable,
    );
  }
}