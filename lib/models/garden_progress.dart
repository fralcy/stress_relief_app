import 'package:hive/hive.dart';

part 'garden_progress.g.dart';

// Model cho ô đất trồng trong mini-game vườn
@HiveType(typeId: 12)
class PlantCell {
  @HiveField(0)
  final String? plantType; // Loại cây trồng, null khi chưa trồng
  
  @HiveField(1)
  final int growthStage;  // Phần trăm phát triển (0-100)
  
  @HiveField(2)
  final DateTime lastWatered; // Thời gian tưới nước lần cuối
  
  @HiveField(3)
  final bool needsWater; // Cần tưới nước không
  
  @HiveField(4)
  final bool hasPest; // Bị sâu bệnh không

  PlantCell({
    this.plantType,
    required this.growthStage,
    required this.lastWatered,
    required this.needsWater,
    required this.hasPest,
  });

  // Tạo bản sao với các thay đổi
  PlantCell copyWith({
    String? plantType,
    int? growthStage,
    DateTime? lastWatered,
    bool? needsWater,
    bool? hasPest,
  }) {
    return PlantCell(
      plantType: plantType ?? this.plantType,
      growthStage: growthStage ?? this.growthStage,
      lastWatered: lastWatered ?? this.lastWatered,
      needsWater: needsWater ?? this.needsWater,
      hasPest: hasPest ?? this.hasPest,
    );
  }
}

// Model cho tiến trình mini-game vườn
@HiveType(typeId: 4)
class GardenProgress {
  @HiveField(0)
  final List<List<PlantCell>>? plots;  // Lưới các ô đất
  
  @HiveField(1)
  final Map<String, int> inventory;   // Các hạt giống hiện có
  
  @HiveField(2)
  final int earnings;                 // Tổng điểm kiếm được

  GardenProgress({
    this.plots,
    this.inventory = const {},
    this.earnings = 0,
  });

  // Tạo bản sao với các thay đổi
  GardenProgress copyWith({
    List<List<PlantCell>>? plots,
    Map<String, int>? inventory,
    int? earnings,
  }) {
    return GardenProgress(
      plots: plots ?? this.plots,
      inventory: inventory ?? this.inventory,
      earnings: earnings ?? this.earnings,
    );
  }
}