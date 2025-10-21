import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/asset_loader.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/data_manager.dart';
import '../../core/l10n/app_localizations.dart';
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

class _GardenModalState extends State<GardenModal> {
  late GardenProgress _progress;
  String? _selectedPlantType;
  String? _selectedAction;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  void _loadProgress() {
    var progress = DataManager().gardenProgress;
    
    if (progress == null || progress.plots == null) {
      // Tạo test data với các stage khác nhau
      final testPlots = List.generate(5, (row) {
        return List.generate(5, (col) {
          // Tạo vài ô có cây để test
          if (row == 0 && col == 0) {
            // Stage 1
            return PlantCell(
              plantType: 'carrot',
              growthStage: 20,
              lastWatered: DateTime.now(),
              needsWater: false,
              hasPest: false,
            );
          } else if (row == 0 && col == 1) {
            // Stage 2
            return PlantCell(
              plantType: 'tomato',
              growthStage: 50,
              lastWatered: DateTime.now(),
              needsWater: false,
              hasPest: false,
            );
          } else if (row == 0 && col == 2) {
            // Stage 3
            return PlantCell(
              plantType: 'corn',
              growthStage: 80,
              lastWatered: DateTime.now(),
              needsWater: false,
              hasPest: false,
            );
          } else if (row == 0 && col == 3) {
            // Stage 4 - ready to harvest
            return PlantCell(
              plantType: 'sunflower',
              growthStage: 100,
              lastWatered: DateTime.now(),
              needsWater: false,
              hasPest: false,
            );
          } else {
            // Ô trống
            return PlantCell(
              growthStage: 0,
              lastWatered: DateTime.now(),
              needsWater: false,
              hasPest: false,
            );
          }
        });
      });
      
      progress = GardenProgress(
        plots: testPlots,
        inventory: {
          'carrot': 5,
          'tomato': 5,
          'corn': 5,
          'sunflower': 3,
          'rose': 3,
          'tulip': 3,
          'wheat': 2,
          'pumpkin': 2,
          'strawberry': 2,
          'lettuce': 2,
        },
        earnings: 0,
      );
      DataManager().saveGardenProgress(progress);
    }
    
    setState(() {
      _progress = progress!;
    });
  }

  void _saveProgress() {
    DataManager().saveGardenProgress(_progress);
  }

  // Kiểm tra có ô trống không
  bool get _hasEmptyPlot {
    if (_progress.plots == null) return false;
    for (var row in _progress.plots!) {
      for (var cell in row) {
        if (cell.plantType == null) return true;
      }
    }
    return false;
  }

  bool get _hasPlantNeedingWater {
    if (_progress.plots == null) return false;
    for (var row in _progress.plots!) {
      for (var cell in row) {
        if (cell.plantType != null && cell.needsWater) {
          return true;
        }
      }
    }
    return false;
  }

  bool get _hasPlantWithPest {
    if (_progress.plots == null) return false;
    for (var row in _progress.plots!) {
      for (var cell in row) {
        if (cell.plantType != null && cell.hasPest) {
          return true;
        }
      }
    }
    return false;
  }

  bool get _hasPlantReadyToHarvest {
    if (_progress.plots == null) return false;
    for (var row in _progress.plots!) {
      for (var cell in row) {
        if (cell.plantType != null && cell.growthStage >= 100) {
          return true;
        }
      }
    }
    return false;
  }

  // Kiểm tra điều kiện để enable nút Plant
  bool get _canEnablePlantButton {
    return _hasEmptyPlot;
  }

  // Kiểm tra có thể thực hiện hành động Plant không (cần cả seed và ô trống)
  bool get _canPlant {
    if (_selectedPlantType == null) return false;
    final count = _progress.inventory[_selectedPlantType] ?? 0;
    return count > 0 && _hasEmptyPlot;
  }

  void _toggleAction(String action) {
    setState(() {
      _selectedAction = _selectedAction == action ? null : action;
    });
  }

  void _onCellTap(int row, int col) {
    if (_selectedAction == null) return;
    
    final cell = _progress.plots![row][col];
    final l10n = AppLocalizations.of(context);
    
    switch (_selectedAction!) {
      case 'plant':
        if (cell.plantType != null) return;
        if (!_canPlant) return;
        
        final plots = List<List<PlantCell>>.from(
          _progress.plots!.map((row) => List<PlantCell>.from(row))
        );
        
        plots[row][col] = PlantCell(
          plantType: _selectedPlantType,
          growthStage: 0,
          lastWatered: DateTime.now(),
          needsWater: false,
          hasPest: false,
        );
        
        final newInventory = Map<String, int>.from(_progress.inventory);
        newInventory[_selectedPlantType!] = (newInventory[_selectedPlantType] ?? 0) - 1;
        
        setState(() {
          _progress = _progress.copyWith(
            plots: plots,
            inventory: newInventory,
          );
        });
        _saveProgress();
        _showToast(l10n.plantedSuccessfully);
        break;
        
      case 'water':
        if (cell.plantType == null || !cell.needsWater) return;
        
        final plots = List<List<PlantCell>>.from(
          _progress.plots!.map((row) => List<PlantCell>.from(row))
        );
        
        plots[row][col] = cell.copyWith(
          needsWater: false,
          lastWatered: DateTime.now(),
        );
        
        setState(() {
          _progress = _progress.copyWith(plots: plots);
        });
        _saveProgress();
        _showToast(l10n.wateredSuccessfully);
        break;
        
      case 'pestControl':
        if (cell.plantType == null || !cell.hasPest) return;
        
        final plots = List<List<PlantCell>>.from(
          _progress.plots!.map((row) => List<PlantCell>.from(row))
        );
        
        plots[row][col] = cell.copyWith(hasPest: false);
        
        setState(() {
          _progress = _progress.copyWith(plots: plots);
        });
        _saveProgress();
        _showToast(l10n.pestControlSuccessfully);
        break;
        
      case 'harvest':
        if (cell.plantType == null || cell.growthStage < 100) return;
        
        final plots = List<List<PlantCell>>.from(
          _progress.plots!.map((row) => List<PlantCell>.from(row))
        );
        
        plots[row][col] = PlantCell(
          growthStage: 0,
          lastWatered: DateTime.now(),
          needsWater: false,
          hasPest: false,
        );
        
        final points = 10;
        
        setState(() {
          _progress = _progress.copyWith(
            plots: plots,
            earnings: _progress.earnings + points,
          );
        });
        _saveProgress();
        _showToast(l10n.harvestedSuccessfully(1, points));
        break;
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                crossAxisCount: 5,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
              ),
              itemCount: 25,
              itemBuilder: (context, index) {
                final row = index ~/ 5;
                final col = index % 5;
                return _buildPlotCell(row, col, _progress.plots![row][col], theme);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlotCell(int row, int col, PlantCell cell, AppTheme theme) {
    return InkWell(
      onTap: () => _onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF8B7355),
          // Bỏ border này
          // border: Border.all(color: theme.border, width: 0.5),
        ),
        child: Center(
          child: cell.plantType != null
              ? Image.asset(
                  AssetLoader.getPlantAsset(cell.plantType!, cell.growthStage),
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback nếu không load được ảnh
                    return Text(
                      _getPlantIcon(cell.plantType!),
                      style: const TextStyle(fontSize: 24),
                    );
                  },
                )
              : null, // Ô trống = không hiển thị gì
        ),
      ),
    );
  }

  String _getPlantIcon(String plantType) {
    switch (plantType) {
      case 'carrot': return '🥕';
      case 'tomato': return '🍅';
      case 'corn': return '🌽';
      case 'sunflower': return '🌻';
      case 'rose': return '🌹';
      case 'tulip': return '🌷';
      case 'wheat': return '🌾';
      case 'pumpkin': return '🎃';
      case 'strawberry': return '🍓';
      case 'lettuce': return '🥬';
      default: return '🌿';
    }
  }

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
      onPressed: canEnable ? () => _toggleAction(actionKey) : null,
    );
  }
}