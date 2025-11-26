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
}