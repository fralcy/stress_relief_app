import 'dart:math';
import '../constants/plant_config.dart';
import '../../models/index.dart';

class GardenService {
  // Tính growth stage dựa trên timestamp
  static int calculateGrowthStage(PlantCell cell) {
    if (cell.plantType == null || cell.plantedAt == null) return 0;
    
    final config = PlantConfigs.getConfig(cell.plantType!);
    if (config == null) return cell.growthStage;
    
    // Nếu cây thiếu nước → không grow
    if (cell.needsWater) return cell.growthStage;
    
    // Tính thời gian đã trồng (tính từ lần tưới gần nhất)
    final now = DateTime.now();
    final timeSincePlanted = now.difference(cell.plantedAt!);
    final timeSinceWatered = now.difference(cell.lastWatered);
    
    // Nếu quá 24h không tưới → thiếu nước
    if (timeSinceWatered.inHours >= 24) {
      return cell.growthStage; // Ngừng grow
    }
    
    // Tính % growth
    final totalGrowthTime = Duration(hours: config.growthTimeHours);
    final growthProgress = (timeSincePlanted.inMinutes / totalGrowthTime.inMinutes) * 100;
    
    return growthProgress.clamp(0, 100).toInt();
  }
  
  // Check xem có cần nước không
  static bool needsWater(PlantCell cell) {
    if (cell.plantType == null) return false;
    
    final now = DateTime.now();
    final timeSinceWatered = now.difference(cell.lastWatered);
    
    return timeSinceWatered.inHours >= 24;
  }
  
  // Random spawn pest khi mở modal (tỉ lệ thấp)
  static bool shouldSpawnPest(PlantCell cell) {
    if (cell.plantType == null) return false;
    if (cell.hasPest) return true; // Đã có sâu rồi
    
    // 5% chance spawn pest mỗi lần mở modal
    return Random().nextDouble() < 0.05;
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