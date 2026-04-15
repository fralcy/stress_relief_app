import 'dart:math';
import '../constants/plant_config.dart';
import '../../models/index.dart';

class GardenService {
  // Tính growth stage dựa trên timestamp
  static int calculateGrowthStage(PlantCell cell) {
    if (cell.plantType == null || cell.plantedAt == null) return 0;
    
    final config = PlantConfigs.getConfig(cell.plantType!);
    if (config == null) return cell.growthStage;
    
    final now = DateTime.now();
    final timeSincePlanted = now.difference(cell.plantedAt!);
    final timeSinceWatered = now.difference(cell.lastWatered);
    
    // Nếu quá 20h từ lastWatered, chỉ tính growth đến hết 20h đó
    final maxGrowthMinutes = timeSinceWatered.inHours >= 20
        ? (timeSincePlanted.inMinutes - timeSinceWatered.inMinutes + (20 * 60))
        : timeSincePlanted.inMinutes;
    
    // Tính % growth
    final totalGrowthTime = Duration(hours: config.growthTimeHours);
    final growthProgress = (maxGrowthMinutes.clamp(0, totalGrowthTime.inMinutes) / totalGrowthTime.inMinutes) * 100;
    
    return growthProgress.clamp(0, 100).toInt();
  }
  
  // Check xem có cần nước không
  static bool needsWater(PlantCell cell) {
    if (cell.plantType == null) return false;

    // Nếu cây đã phát triển đủ (100%), không cần nước nữa
    if (cell.growthStage >= 100) return false;

    final now = DateTime.now();
    final timeSinceWatered = now.difference(cell.lastWatered);

    return timeSinceWatered.inHours >= 20;
  }
  
  // Random spawn pest khi update (tỉ lệ thấp)
  static bool shouldSpawnPest(PlantCell cell) {
    if (cell.plantType == null) return false;
    if (cell.hasPest) return true; // Đã có sâu rồi
    
    // 1.5% chance spawn pest mỗi lần update
    return Random().nextDouble() < 0.015;
  }
  
  // Update tất cả cells khi mở modal
  static List<List<PlantCell>> updateAllCells(List<List<PlantCell>> plots) {
    return plots.map((row) {
      return row.map((cell) {
        if (cell.plantType == null) return cell;

        return cell.copyWith(
          growthStage: calculateGrowthStage(cell),
          needsWater: needsWater(cell),
          hasPest: shouldSpawnPest(cell),
        );
      }).toList();
    }).toList();
  }

  // ===== GARDEN STATUS CHECKS =====

  /// Kiểm tra có ô trống để trồng cây
  static bool hasEmptyPlot(List<List<PlantCell>> plots) {
    for (var row in plots) {
      for (var cell in row) {
        if (cell.plantType == null) return true;
      }
    }
    return false;
  }

  /// Kiểm tra có cây cần tưới nước
  static bool hasPlantNeedingWater(List<List<PlantCell>> plots) {
    for (var row in plots) {
      for (var cell in row) {
        if (cell.plantType != null && cell.needsWater) {
          return true;
        }
      }
    }
    return false;
  }

  /// Kiểm tra có cây bị sâu bệnh
  static bool hasPlantWithPest(List<List<PlantCell>> plots) {
    for (var row in plots) {
      for (var cell in row) {
        if (cell.plantType != null && cell.hasPest) {
          return true;
        }
      }
    }
    return false;
  }

  /// Kiểm tra có cây sẵn sàng thu hoạch
  static bool hasPlantReadyToHarvest(List<List<PlantCell>> plots) {
    for (var row in plots) {
      for (var cell in row) {
        if (cell.plantType != null && cell.growthStage >= 100) {
          return true;
        }
      }
    }
    return false;
  }

  /// Kiểm tra có thể trồng cây (cần cả seed và ô trống)
  static bool canPlant({
    required String? selectedPlantType,
    required Map<String, int> inventory,
    required List<List<PlantCell>> plots,
  }) {
    if (selectedPlantType == null) return false;
    final count = inventory[selectedPlantType] ?? 0;
    return count > 0 && hasEmptyPlot(plots);
  }

  /// Lấy icon của cây theo loại
  static String getPlantIcon(String plantType) {
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

  // ===== GARDEN ACTIONS =====

  /// Trồng cây vào ô (row, col)
  /// Returns: {plots, inventory} updated
  static Map<String, dynamic>? plantSeed({
    required List<List<PlantCell>> plots,
    required Map<String, int> inventory,
    required int row,
    required int col,
    required String plantType,
  }) {
    final cell = plots[row][col];
    if (cell.plantType != null) return null; // Ô đã có cây

    final seedCount = inventory[plantType] ?? 0;
    if (seedCount <= 0) return null; // Không đủ seed

    final now = DateTime.now();
    final newPlots = List<List<PlantCell>>.from(
      plots.map((row) => List<PlantCell>.from(row))
    );

    newPlots[row][col] = PlantCell(
      plantType: plantType,
      growthStage: 0,
      lastWatered: now,
      needsWater: false,
      hasPest: false,
      plantedAt: now,
    );

    final newInventory = Map<String, int>.from(inventory);
    newInventory[plantType] = seedCount - 1;

    return {
      'plots': newPlots,
      'inventory': newInventory,
    };
  }

  /// Tưới nước cho cây
  /// Returns: plots updated hoặc null nếu không thể tưới
  static List<List<PlantCell>>? waterPlant({
    required List<List<PlantCell>> plots,
    required int row,
    required int col,
  }) {
    final cell = plots[row][col];
    if (cell.plantType == null || !cell.needsWater) return null;

    final now = DateTime.now();
    final newPlots = List<List<PlantCell>>.from(
      plots.map((row) => List<PlantCell>.from(row))
    );

    // Tính thời gian tăng trưởng thực tế tích lũy đến lúc tưới (không tính
    // khoảng thời gian khô hạn vượt quá 20h). Cập nhật plantedAt thành một
    // "virtual start" sao cho calculateGrowthStage tiếp tục đúng từ mức hiện tại.
    DateTime newPlantedAt = cell.plantedAt ?? now;
    if (cell.plantedAt != null) {
      final timeSincePlanted = now.difference(cell.plantedAt!);
      final timeSinceWatered = now.difference(cell.lastWatered);
      if (timeSinceWatered.inHours >= 20) {
        final effectiveMinutes = timeSincePlanted.inMinutes
            - timeSinceWatered.inMinutes
            + 20 * 60;
        newPlantedAt = now.subtract(
            Duration(minutes: effectiveMinutes.clamp(0, timeSincePlanted.inMinutes)));
      }
    }

    newPlots[row][col] = cell.copyWith(
      needsWater: false,
      lastWatered: now,
      plantedAt: newPlantedAt,
    );

    return newPlots;
  }

  /// Diệt sâu bệnh
  /// Returns: plots updated hoặc null nếu không thể diệt
  static List<List<PlantCell>>? removePest({
    required List<List<PlantCell>> plots,
    required int row,
    required int col,
  }) {
    final cell = plots[row][col];
    if (cell.plantType == null || !cell.hasPest) return null;

    final newPlots = List<List<PlantCell>>.from(
      plots.map((row) => List<PlantCell>.from(row))
    );

    newPlots[row][col] = cell.copyWith(hasPest: false);

    return newPlots;
  }

  /// Thu hoạch cây
  /// Returns: {plots, inventory, earnings, pointsGained} hoặc null nếu không thể thu hoạch
  static Map<String, dynamic>? harvestPlant({
    required List<List<PlantCell>> plots,
    required Map<String, int> inventory,
    required int earnings,
    required int row,
    required int col,
  }) {
    final cell = plots[row][col];
    if (cell.plantType == null || cell.growthStage < 100) return null;

    final config = PlantConfigs.getConfig(cell.plantType!);
    if (config == null) return null;

    final newPlots = List<List<PlantCell>>.from(
      plots.map((row) => List<PlantCell>.from(row))
    );

    // Reset ô về trống
    newPlots[row][col] = PlantCell(
      plantType: null,
      growthStage: 0,
      lastWatered: DateTime.now(),
      needsWater: false,
      hasPest: false,
      plantedAt: null,
    );

    // Lấy seeds và points
    final seedsGained = config.seedsFromHarvest;
    final pointsGained = config.harvestReward;

    // Update inventory
    final newInventory = Map<String, int>.from(inventory);
    newInventory[cell.plantType!] = (newInventory[cell.plantType!] ?? 0) + seedsGained;

    return {
      'plots': newPlots,
      'inventory': newInventory,
      'earnings': earnings + pointsGained,
      'pointsGained': pointsGained,
    };
  }

  // ==================== DEBUG METHODS ====================

  /// [DEBUG] Advance all plants' timestamps by specified hours
  static List<List<PlantCell>> debugAdvanceAllPlants({
    required List<List<PlantCell>> plots,
    required int hours,
  }) {
    final advanceAmount = Duration(hours: hours);

    return plots.map((row) {
      return row.map((cell) {
        if (cell.plantType == null) return cell;

        return cell.copyWith(
          plantedAt: cell.plantedAt?.subtract(advanceAmount),
          lastWatered: cell.lastWatered.subtract(advanceAmount),
        );
      }).toList();
    }).toList();
  }

  /// [DEBUG] Make all plants instantly ready to harvest
  static List<List<PlantCell>> debugInstantGrowAll({
    required List<List<PlantCell>> plots,
  }) {
    return plots.map((row) {
      return row.map((cell) {
        if (cell.plantType == null) return cell;

        final config = PlantConfigs.getConfig(cell.plantType!);
        if (config == null) return cell;

        final now = DateTime.now();
        final plantedTime = now.subtract(Duration(hours: config.growthTimeHours));

        return cell.copyWith(
          plantedAt: plantedTime,
          lastWatered: now,
        );
      }).toList();
    }).toList();
  }
}